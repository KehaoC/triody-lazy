from sortedcontainers import SortedSet, SortedDict
from team.agents import Team
from celery import shared_task
from typing import Optional
from team.models import Task
from django.db import transaction
from django.core.cache import cache
import pickle
import json

class TaskPool:
    def __init__(self):
        # 定义 Redis 键名
        self.ready_teams_key = 'task_pool:ready_teams'
        self.waiting_teams_key = 'task_pool:waiting_teams'
        
        # 初始化 Redis 存储
        if not cache.get(self.ready_teams_key):
            cache.set(self.ready_teams_key, pickle.dumps(SortedSet()))
        if not cache.get(self.waiting_teams_key):
            cache.set(self.waiting_teams_key, pickle.dumps(SortedDict()))

    def _get_ready_teams(self) -> SortedSet:
        """获取ready_teams的当前状态"""
        return pickle.loads(cache.get(self.ready_teams_key))

    def _set_ready_teams(self, teams: SortedSet) -> None:
        """更新ready_teams的状态"""
        cache.set(self.ready_teams_key, pickle.dumps(teams))

    def _get_waiting_teams(self) -> SortedDict:
        """获取waiting_teams的当前状态"""
        return pickle.loads(cache.get(self.waiting_teams_key))

    def _set_waiting_teams(self, teams: SortedDict) -> None:
        """更新waiting_teams的状态"""
        cache.set(self.waiting_teams_key, pickle.dumps(teams))

    @shared_task
    def add_team(self, team: Team) -> Optional[str]:
        """异步添加新的Team到任务池中"""
        try:
            with transaction.atomic():
                if self._is_team_ready(team):
                    # 获取当前ready_teams
                    ready_teams = self._get_ready_teams()
                    # 添加新team
                    ready_teams.add(team)
                    # 更新状态
                    self._set_ready_teams(ready_teams)
                else:
                    # 获取当前waiting_teams
                    waiting_teams = self._get_waiting_teams()
                    # 添加新team
                    waiting_teams[team.task_id] = team
                    # 更新状态
                    self._set_waiting_teams(waiting_teams)
                return team.task_id
        except Exception as e:
            print(f"Error adding team {team.task_id}: {str(e)}")
            return None

    def _is_team_ready(self, team: Team) -> bool:
        """检查Team是否可以运行"""
        return True

    @shared_task
    def move_to_ready(self, task_id: str) -> Optional[str]:
        """异步将waiting_teams中的Team移动到ready_teams"""
        try:
            with transaction.atomic():
                # 获取当前状态
                waiting_teams = self._get_waiting_teams()
                if task_id in waiting_teams:
                    team = waiting_teams.pop(task_id)
                    if self._is_team_ready(team):
                        ready_teams = self._get_ready_teams()
                        ready_teams.add(team)
                        # 更新两个队列的状态
                        self._set_waiting_teams(waiting_teams)
                        self._set_ready_teams(ready_teams)
                        return task_id
        except Exception as e:
            print(f"Error moving team {task_id} to ready: {str(e)}")
        return None

    @shared_task
    def schedule(self) -> Optional[str]:
        """调度并运行优先级最高的Team任务"""
        ready_teams = self._get_ready_teams()
        if not ready_teams:
            return None

        try:
            # 获取并移除优先级最高的Team
            team = ready_teams.pop(0)
            self._set_ready_teams(ready_teams)

            with transaction.atomic():
                team.decompose_task()
                team.run()
                return team.task_id

        except Exception as e:
            print(f"Error executing team {team.task_id}: {str(e)}")
            # 发生错误时将任务移到waiting队列
            waiting_teams = self._get_waiting_teams()
            waiting_teams[team.task_id] = team
            self._set_waiting_teams(waiting_teams)
            return None

    def get_team_count(self) -> tuple:
        """返回当前ready和waiting的Team数量"""
        ready_teams = self._get_ready_teams()
        waiting_teams = self._get_waiting_teams()
        return len(ready_teams), len(waiting_teams)

    def get_team_by_task_id(self, task_id: str) -> Optional[Team]:
        """根据task_id获取Team"""
        waiting_teams = self._get_waiting_teams()
        if task_id in waiting_teams:
            return waiting_teams[task_id]
        
        ready_teams = self._get_ready_teams()
        for team in ready_teams:
            if team.task_id == task_id:
                return team
        return None