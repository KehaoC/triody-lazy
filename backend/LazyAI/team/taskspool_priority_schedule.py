from celery import shared_task, current_app
from typing import Optional
from team.agents import Team
from team.models import Task
from django.db import transaction
from celery.result import AsyncResult
from uuid import uuid4
from celery.utils.log import get_task_logger

logger = get_task_logger(__name__)

class TaskPool:
    def __init__(self):
        # 定义不同优先级的队列
        self.priority_queues = {
            'high': 'high_priority',
            'normal': 'normal_priority',
            'low': 'low_priority'
        }
        self.waiting_queue = 'waiting_tasks'

    @shared_task(queue='default')
    def add_team(self, team: Team, priority: str = 'normal') -> Optional[str]:
        """
        异步添加新的Team到任务池中
        priority: 'high', 'normal', 或 'low'
        """
        try:
            with transaction.atomic():
                if self._is_team_ready(team):
                    # 根据优先级选择队列
                    queue_name = self.priority_queues.get(priority, 'normal_priority')
                    task_priority = {'high': 9, 'normal': 5, 'low': 1}.get(priority, 5)
                    
                    # 发送到对应优先级的队列
                    task_id = str(uuid4())
                    current_app.send_task(
                        'team.taskspool_priority.TaskPool.schedule',
                        args=[team],
                        kwargs={},
                        queue=queue_name,
                        priority=task_priority,
                        task_id=task_id
                    )
                else:
                    # 发送到waiting队列
                    task_id = str(uuid4())
                    current_app.send_task(
                        'team.taskspool_priority.TaskPool.wait',
                        args=[team],
                        kwargs={},
                        queue=self.waiting_queue,
                        task_id=task_id
                    )
                return task_id
        except Exception as e:
            logger.error(f"Error adding team: {str(e)}")
            return None

    @shared_task(queue='default')
    def move_to_ready(self, task_id: str, priority: str = 'normal') -> Optional[str]:
        """将waiting队列中的任务移动到指定优先级的ready队列"""
        try:
            result = AsyncResult(task_id)
            if result.ready():
                team = result.get()
                if self._is_team_ready(team):
                    queue_name = self.priority_queues.get(priority, 'normal_priority')
                    task_priority = {'high': 9, 'normal': 5, 'low': 1}.get(priority, 5)
                    
                    new_task_id = str(uuid4())
                    current_app.send_task(
                        'team.taskspool_priority.TaskPool.schedule',
                        args=[team],
                        kwargs={},
                        queue=queue_name,
                        priority=task_priority,
                        task_id=new_task_id
                    )
                    return new_task_id
        except Exception as e:
            logger.error(f"Error moving task {task_id} to ready: {str(e)}")
        return None

    @shared_task(bind=True)
    def periodic_schedule(self):
        """
        定期检查队列并执行任务的调度器
        按优先级顺序处理队列中的Team任务
        """
        # 获取 Celery 的 backend
        backend = current_app.backend
        lock_id = f"{self.periodic_schedule.name}_lock"
        
        # 尝试获取锁
        if not backend.client.setnx(lock_id, True):
            logger.info("Previous task still running")
            return None
        
        try:
            app = current_app
            
            # 按优先级顺序处理队列
            for priority in ['high', 'normal', 'low']:
                queue_name = self.priority_queues[priority]
                
                # 检查队列中是否有任务
                inspector = app.control.inspect()
                active_tasks = inspector.active().get(queue_name, [])
                
                if active_tasks:
                    try:
                        # 从队列中获取任务
                        result = app.tasks['team.taskspool_priority.TaskPool.schedule'].apply_async(
                            queue=queue_name
                        )
                    
                        # 获取Team实例并执行
                        team = result.get()  # 这里会阻塞直到获取到任务
                        if team:
                            try:
                                with transaction.atomic():
                                    # 执行任务分解和运行
                                    team.decompose_task()
                                    team.run()
                                    logger.info(f"Successfully processed task {team.task_id} from {queue_name}")
                                
                            except Exception as e:
                                logger.error(f"Error processing task {team.task_id}: {str(e)}")
                                # 如果处理失败，移到waiting队列
                                self._handle_failed_task(team, str(e))
                            
                    except Exception as e:
                        logger.error(f"Error getting task from {queue_name}: {str(e)}")
                        continue
        finally:
            # 释放锁
            backend.client.delete(lock_id)
            logger.info("Released periodic schedule lock")

    def _handle_failed_task(self, team, error_message):
        """处理失败的任务"""
        try:
            # 将失败的任务移到waiting队列
            task_id = str(uuid4())
            current_app.send_task(
                'team.taskspool_priority.TaskPool.wait',
                args=[team],
                kwargs={'error': error_message},
                queue=self.waiting_queue,
                task_id=task_id
            )
            logger.info(f"Moved failed task {team.task_id} to waiting queue")
        except Exception as e:
            logger.error(f"Error moving failed task {team.task_id} to waiting queue: {str(e)}")

    @shared_task(queue='waiting_tasks')
    def wait(self, team: Team, error: str = None) -> Team:
        """
        等待队列中的任务处理器
        
        Args:
            team: 要处理的Team实例
            error: 错误信息（如果有）
            
        Returns:
            Team: 处理后的Team实例
        """
        if error:
            logger.info(f"Task {team.task_id} in waiting queue due to error: {error}")
        return team

    def get_queue_length(self) -> dict:
        """获取所有队列的长度"""
        app = current_app
        lengths = {}
        
        # 获取优先级队列长度
        inspector = app.control.inspect()
        active = inspector.active() or {}
        
        for priority, queue_name in self.priority_queues.items():
            lengths[priority] = len(active.get(queue_name, []))
            
        # 获取等待队列长度
        lengths['waiting'] = len(active.get(self.waiting_queue, []))
        
        return lengths

# 初始化任务池实例
task_pool = TaskPool()