from sortedcontainers import SortedSet, SortedDict
from team.agents import Team
from celery import shared_task
from typing import Optional
from team.models import Task
from django.db import transaction

class TaskPool:
    def __init__(self):
        # 存储可以运行的Team（按照优先级排序）
        self.ready_teams = SortedSet()
        # 存储不可运行的Team（按照task_id索引）
        self.waiting_teams = SortedDict()
    
    @shared_task
    def add_team(self, team: Team) -> Optional[str]:
        """
        异步添加新的Team到任务池中
        如果Team可以立即运行，添加到ready_teams
        否则添加到waiting_teams
        返回team的task_id
        """
        try:
            with transaction.atomic():
                if self._is_team_ready(team):
                    self.ready_teams.add(team)
                else:
                    self.waiting_teams[team.task_id] = team
                return team.task_id
        except Exception as e:
            print(f"Error adding team {team.task_id}: {str(e)}")
            return None
    
    def _is_team_ready(self, team: Team) -> bool:
        """
        检查Team是否可以运行
        可以根据具体需求实现检查逻辑
        """
        # 这里可以添加具体的检查逻辑，比如：
        # - 资源是否可用
        # - 依赖任务是否完成
        # - 等等
        return True  # 默认返回True，实际使用时需要根据具体条件判断
    
    @shared_task
    def move_to_ready(self, task_id: str) -> Optional[str]:
        """
        异步将waiting_teams中的Team移动到ready_teams
        返回成功移动的task_id，失败返回None
        """
        try:
            with transaction.atomic():
                if task_id in self.waiting_teams:
                    team = self.waiting_teams.pop(task_id)
                    if self._is_team_ready(team):
                        self.ready_teams.add(team)
                        return task_id
        except Exception as e:
            print(f"Error moving team {task_id} to ready: {str(e)}")
        return None
    
    @shared_task
    def schedule(self) -> Optional[str]:
        """
        调度并运行优先级最高的Team任务
        返回执行的任务ID
        """
        if not self.ready_teams:
            return None
            
        # 获取优先级最高的Team
        team = self.ready_teams.pop(0)
        
        try:
            with transaction.atomic():
                # 执行任务分解
                team.decompose_task()
                # 运行任务
                team.run()
                
            return team.task_id
            
        except Exception as e:
            # 如果执行失败，可以选择重新加入队列或进行错误处理
            print(f"Error executing team {team.task_id}: {str(e)}")
            # 可以选择重新加入waiting_teams
            self.waiting_teams[team.task_id] = team
            return None
    
    def get_team_count(self) -> tuple:
        """
        返回当前ready和waiting的Team数量
        """
        return len(self.ready_teams), len(self.waiting_teams)
    
    def get_team_by_task_id(self, task_id: str) -> Optional[Team]:
        """
        根据task_id获取Team
        """
        if task_id in self.waiting_teams:
            return self.waiting_teams[task_id]
        for team in self.ready_teams:
            if team.task_id == task_id:
                return team
        return None 