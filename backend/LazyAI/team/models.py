from django.db import models

# Create your models here.from django.db import models
# 一切从简

# User先用最简单的用户登陆逻辑，不用验证Token之类的
class User(models.Model):
    # 识别码
    user_id = models.AutoField(primary_key=True)

    # 主要信息
    name = models.CharField(max_length=100)
    email = models.EmailField(unique=True)
    password = models.CharField(max_length=100)

class Task(models.Model):
    # 识别码
    task_id = models.AutoField(primary_key=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE)

    # 主要信息
    title = models.CharField(max_length=100)
    description = models.TextField()
    summary = models.TextField(blank=True, null=True)

    isFinished = models.BooleanField(default=False)  # 仅仅展现任务的完成状态
    allSubtasksLazied = models.BooleanField(default=False)  # 是否所有子任务 都经过LazyTeam的多 Agent 框架处理过

class Subtask(models.Model):
    # 识别码
    subtask_id = models.AutoField(primary_key=True)
    task = models.ForeignKey(Task, on_delete=models.CASCADE)

    # 主要信息
    description = models.TextField()
    agent_name = models.CharField(max_length=100)
    isLazied = models.BooleanField(default=False)  # 是否经过LazyTeam的多 Agent 框架处理过

    # 执行结果
    result = models.TextField()