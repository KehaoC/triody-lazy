from celery import shared_task, current_app
from celery.utils.log import get_task_logger
from typing import Optional, Dict
from team.agents import Team
from team.models import Task
from django.db import transaction
from celery.result import AsyncResult
from uuid import uuid4

logger = get_task_logger(__name__)

# 定义队列常量
PRIORITY_QUEUES = {
    'high': 'high_priority',
    'normal': 'normal_priority',
    'low': 'low_priority'
}
WAITING_QUEUE = 'waiting_tasks'

@shared_task
def add_team(team: Team, priority: str = 'normal',ready: bool = False) -> Optional[str]:
    """
    异步添加新的Team到任务池中
    Args:
        team: Team实例
        priority: 优先级，可选值：'high', 'normal', 'low'
    Returns:
        task_id: 任务ID
    """
    try:
        with transaction.atomic():
            if ready:
                # 根据优先级选择队列
                queue_name = PRIORITY_QUEUES.get(priority, 'normal_priority')
                task_priority = {'high': 9, 'normal': 5, 'low': 1}.get(priority, 5)
                
                # 发送到对应优先级的队列
                task_id = team.task_id
                current_app.send_task(
                    'team.tasks.schedule_team',
                    args=[team],
                    kwargs={},
                    queue=queue_name,
                    priority=task_priority,
                    task_id=task_id
                )
            else:
                # 发送到waiting队列
                task_id = team.task_id
                current_app.send_task(
                    'team.tasks.wait_team',
                    args=[team],
                    kwargs={},
                    queue=WAITING_QUEUE,
                    task_id=task_id
                )
            return task_id
    except Exception as e:
        logger.error(f"Error adding team: {str(e)}")
        return None

@shared_task
def move_to_ready(task_id: str, priority: str = 'normal') -> Optional[str]:
    """将waiting队列中的任务移动到指定优先级的ready队列"""
    try:
        result = AsyncResult(task_id)
        if result.ready():
            team = result.get()
            
            queue_name = PRIORITY_QUEUES.get(priority, 'normal_priority')
            task_priority = {'high': 9, 'normal': 5, 'low': 1}.get(priority, 5)
                
            current_app.send_task(
                'team.tasks.schedule_team',
                args=[team],
                kwargs={},
                queue=queue_name,
                priority=task_priority,
                task_id=team.task_id
            )
            
            _cleanup_task(team.task_id)
                
            logger.info(f"Successfully moved team to {queue_name} with new task_id {team.task_id}")
            
            return team.task_id
    except Exception as e:
        logger.error(f"Error moving task {task_id} to ready: {str(e)}")
    return None

@shared_task(bind=True)
def periodic_schedule(self) -> None:
    """定期检查队列的调度器"""
    logger.info("Starting periodic schedule task")
    
    # 获取 Celery 的 backend
    backend = current_app.backend
    lock_id = "periodic_schedule_lock"
    
    # 尝试获取锁
    if not backend.client.setnx(lock_id, '1'):
        logger.info("Previous task still running")
        return None
        
    try:
        # 设置锁的过期时间
        backend.client.expire(lock_id, 60)
        app = current_app
        
        # 获取所有队列的任务状态
        inspector = app.control.inspect()
        active_tasks = inspector.active() or {}
        
        # 检查是否有任务在任何队列中
        has_tasks = False
        for priority in ['high', 'normal', 'low']:
            queue_name = PRIORITY_QUEUES[priority]
            if any(task for worker_tasks in active_tasks.values() 
                  for task in worker_tasks 
                  if task.get('delivery_info', {}).get('routing_key') == queue_name):
                has_tasks = True
                logger.info(f"Found tasks in {queue_name}")
                break
        
        if not has_tasks:
            logger.info("No tasks found in any queue")
            return None
    finally:
        backend.client.delete(lock_id)
        logger.info("Released periodic schedule lock")

@shared_task
def schedule_team(team: Team) -> Team:
    """处理队列中的Team任务"""
    team.decompose_task()
    team.run()
    return team

@shared_task
def wait_team(team: Team, error: str = None) -> Team:
    """
    等待队列中的任务处理器
    Args:
        team: Team实例
        error: 错误信息（如果有）
    """
    if error:
        logger.info(f"Task {team.task_id} in waiting queue due to error: {error}")
    return team

def _handle_failed_task(team: Team, error_message: str) -> None:
    """处理失败的任务（内部函数）"""
    try:
        task_id = str(uuid4())
        current_app.send_task(
            'team.tasks.wait_team',
            args=[team],
            kwargs={'error': error_message},
            queue=WAITING_QUEUE,
            task_id=task_id
        )
        logger.info(f"Moved failed task {team.task_id} to waiting queue")
    except Exception as e:
        logger.error(f"Error moving failed task {team.task_id} to waiting queue: {str(e)}")

def _is_team_ready(team: Team) -> bool:
    """检查Team是否准备就绪（内部函数）"""
    # 实现你的检查逻辑
    return True

def get_queue_length() -> Dict[str, int]:
    """获取所有队列的长度"""
    app = current_app
    lengths = {}
    
    # 获取优先级队列长度
    inspector = app.control.inspect()
    active = inspector.active() or {}
    
    for priority, queue_name in PRIORITY_QUEUES.items():
        lengths[priority] = len(active.get(queue_name, []))
        
    # 获取等待队列长度
    lengths['waiting'] = len(active.get(WAITING_QUEUE, []))
    
    return lengths

def _cleanup_task(task_id: str):
    """清理任务相关的所有数据"""
    try:
        # 1. 清除任务结果
        result = AsyncResult(task_id)
        result.forget()
        
        # 2. 清除Redis中的任务数据
        backend = current_app.backend
        backend.client.delete(f"celery-task-meta-{task_id}")
        
        logger.info(f"Successfully cleaned up task {task_id} from queue")
    except Exception as e:
        logger.error(f"Error cleaning up task {task_id}: {str(e)}")