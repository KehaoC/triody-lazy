from celery import shared_task, current_app
from typing import Optional
from team.agents import Team
from team.models import Task
from django.db import transaction
from celery.result import AsyncResult
from kombu.utils.uuid import uuid
from kombu import Queue, Exchange

class TaskPool:
    def __init__(self):
        # 定义不同优先级的队列
        self.priority_queues = {
            'high': 'high_priority',
            'normal': 'normal_priority',
            'low': 'low_priority'
        }
        self.waiting_queue = 'waiting_tasks'
        
        # 确保队列存在
        self._ensure_queues_exist()
    
    def _ensure_queues_exist(self):
        """确保优先级队列在 Celery 中存在"""
        app = current_app
        queues = {}
        
        # 创建优先级队列
        for priority, queue_name in self.priority_queues.items():
            queues[queue_name] = Queue(
                queue_name,
                Exchange(queue_name),
                routing_key=queue_name,
                queue_arguments={'x-max-priority': 10}  # 设置队列最大优先级
            )
        
        # 创建等待队列
        queues[self.waiting_queue] = Queue(
            self.waiting_queue,
            Exchange(self.waiting_queue),
            routing_key=self.waiting_queue
        )
        
        app.conf.task_queues = queues

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
                    task_id = uuid()
                    current_app.send_task(
                        'team.taskspool.TaskPool.schedule',
                        args=[team],
                        kwargs={},
                        queue=queue_name,
                        priority=task_priority,  # 设置任务优先级
                        task_id=task_id
                    )
                else:
                    # 发送到waiting队列
                    task_id = uuid()
                    current_app.send_task(
                        'team.taskspool.TaskPool.wait',
                        args=[team],
                        kwargs={},
                        queue=self.waiting_queue,
                        task_id=task_id
                    )
                return task_id
        except Exception as e:
            print(f"Error adding team: {str(e)}")
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
                    
                    new_task_id = uuid()
                    current_app.send_task(
                        'team.taskspool.TaskPool.schedule',
                        args=[team],
                        kwargs={},
                        queue=queue_name,
                        priority=task_priority,
                        task_id=new_task_id
                    )
                    return new_task_id
        except Exception as e:
            print(f"Error moving task {task_id} to ready: {str(e)}")
        return None

    def get_queue_length(self) -> dict:
        """获取所有队列的长度"""
        app = current_app
        lengths = {}
        
        # 获取优先级队列长度
        for priority, queue_name in self.priority_queues.items():
            queue = app.amqp.queues[queue_name]
            lengths[priority] = queue.queue_declare(passive=True).message_count
            
        # 获取等待队列长度
        waiting_queue = app.amqp.queues[self.waiting_queue]
        lengths['waiting'] = waiting_queue.queue_declare(passive=True).message_count
        
        return lengths
    
    @shared_task(bind=True, max_retries=3)
    def schedule(self, team: Team, priority: str = 'normal') -> Optional[str]:
        """
        执行Team任务的调度器
        
        Args:
            team: 要执行的Team实例
            priority: 任务优先级 ('high', 'normal', 'low')
            
        Returns:
            Optional[str]: 成功返回task_id，失败返回None
        """
        try:
            # 获取任务优先级
            task_priority = {'high': 9, 'normal': 5, 'low': 1}.get(priority, 5)
            
            with transaction.atomic():
                # 1. 任务分解
                try:
                    team.decompose_task()
                except Exception as e:
                    print(f"Error decomposing task {team.task_id}: {str(e)}")
                    raise self.retry(exc=e, countdown=60)  # 1分钟后重试
                
                # 2. 执行任务
                try:
                    team.run()
                except Exception as e:
                    print(f"Error running task {team.task_id}: {str(e)}")
                    # 如果执行失败，降低优先级重��入队
                    new_priority = {
                        'high': 'normal',
                        'normal': 'low',
                        'low': 'low'
                    }.get(priority, 'low')
                    
                    # 重新入队，优先级降低
                    task_id = uuid()
                    current_app.send_task(
                        'team.taskspool.TaskPool.schedule',
                        args=[team],
                        kwargs={'priority': new_priority},
                        queue=self.priority_queues.get(new_priority),
                        priority={'high': 9, 'normal': 5, 'low': 1}.get(new_priority, 1),
                        task_id=task_id
                    )
                    return task_id
                
                # 3. 更新任务状态
                try:
                    team.task.is_finished = True
                    team.task.save()
                except Exception as e:
                    print(f"Error updating task status {team.task_id}: {str(e)}")
                    # 状态更新失败不影响任务完成
                    pass
                
                return team.task_id
                
        except Exception as e:
            print(f"Unexpected error in schedule {team.task_id}: {str(e)}")
            # 发���未预期的错误，移到waiting队列
            try:
                task_id = uuid()
                current_app.send_task(
                    'team.taskspool.TaskPool.wait',
                    args=[team],
                    kwargs={},
                    queue=self.waiting_queue,
                    task_id=task_id
                )
                return task_id
            except Exception as e:
                print(f"Failed to move task to waiting queue {team.task_id}: {str(e)}")
                return None
    
    @shared_task(queue='waiting_tasks')
    def wait(self, team: Team) -> Team:
        """
        等待队列中的任务处理器
        
        Args:
            team: 要处理的Team实例
            
        Returns:
            Team: 处理后的Team实例
        """
        # 可以在这里添加等待逻辑，比如检查依赖条件等
        return team

# 初始化任务池
task_pool = TaskPool()

# 添加高优先级任务
high_priority_task_id = task_pool.add_team.delay(team, priority='high').get()

# 添加普通优先级任务
normal_priority_task_id = task_pool.add_team.delay(team, priority='normal').get()

# 添加低优先级任务
low_priority_task_id = task_pool.add_team.delay(team, priority='low').get()

# 查看各队列长度
queue_lengths = task_pool.get_queue_length()
print(f"Queue lengths: {queue_lengths}")