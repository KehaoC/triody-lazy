from celery import shared_task, current_app
from typing import Optional
from team.agents import Team
from team.models import Task
from django.db import transaction
from celery.result import AsyncResult
from kombu.utils.uuid import uuid

class TaskPool:
    def __init__(self):
        # 定义队列名称
        self.ready_queue = 'ready_tasks'
        self.waiting_queue = 'waiting_tasks'
        
        # 确保队列存在
        self._ensure_queues_exist()
    
    def _ensure_queues_exist(self):
        """确保队列在 Celery 中存在"""
        app = current_app
        app.conf.task_queues = {
            self.ready_queue: {
                'exchange': self.ready_queue,
                'routing_key': self.ready_queue,
            },
            self.waiting_queue: {
                'exchange': self.waiting_queue,
                'routing_key': self.waiting_queue,
            }
        }

    @shared_task(queue='default')
    def add_team(self, team: Team) -> Optional[str]:
        """异步添加新的Team到任务池中"""
        try:
            with transaction.atomic():
                if self._is_team_ready(team):
                    # 发送到ready队列
                    task_id = uuid()
                    current_app.send_task(
                        'team.taskspool.TaskPool.schedule',
                        args=[team],
                        kwargs={},
                        queue=self.ready_queue,
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

    def _is_team_ready(self, team: Team) -> bool:
        """检查Team是否可以运行"""
        return True

    @shared_task(queue='default')
    def move_to_ready(self, task_id: str) -> Optional[str]:
        """将waiting队列中的任务移动到ready队列"""
        try:
            # 获取waiting队列中的任务
            result = AsyncResult(task_id)
            if result.ready():
                team = result.get()
                if self._is_team_ready(team):
                    # 发送到ready队列
                    new_task_id = uuid()
                    current_app.send_task(
                        'team.taskspool.TaskPool.schedule',
                        args=[team],
                        kwargs={},
                        queue=self.ready_queue,
                        task_id=new_task_id
                    )
                    return new_task_id
        except Exception as e:
            print(f"Error moving task {task_id} to ready: {str(e)}")
        return None

    @shared_task(queue='ready_tasks')
    def schedule(self, team: Team) -> Optional[str]:
        """执行Team任务"""
        try:
            with transaction.atomic():
                team.decompose_task()
                team.run()
                return team.task_id
        except Exception as e:
            print(f"Error executing team {team.task_id}: {str(e)}")
            # 发生错误时将任务移到waiting队列
            task_id = uuid()
            current_app.send_task(
                'team.taskspool.TaskPool.wait',
                args=[team],
                kwargs={},
                queue=self.waiting_queue,
                task_id=task_id
            )
            return None

    @shared_task(queue='waiting_tasks')
    def wait(self, team: Team) -> Team:
        """等待队列中的任务处理器"""
        return team

    def get_queue_length(self) -> tuple:
        """获取队列长度"""
        app = current_app
        ready_queue = app.amqp.queues[self.ready_queue]
        waiting_queue = app.amqp.queues[self.waiting_queue]
        
        return (
            ready_queue.queue_declare(passive=True).message_count,
            waiting_queue.queue_declare(passive=True).message_count
        )

    def get_task_status(self, task_id: str) -> Optional[str]:
        """获取任务状态"""
        return AsyncResult(task_id).status
    
# 初始化任务池
task_pool = TaskPool()

# 添加任务
task_id = task_pool.add_team.delay(team).get()

# 查看任务状态
status = task_pool.get_task_status(task_id)

# 移动到ready队列
new_task_id = task_pool.move_to_ready.delay(task_id).get()

# 查看队列长度
ready_count, waiting_count = task_pool.get_queue_length()