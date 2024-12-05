from django.db import models
from team.models import Task,User,Subtask
# Create your models here.
class Niuma(models.Model):
    niuma_id = models.AutoField(primary_key=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE, to_field='id')
    task = models.ForeignKey(Task, on_delete=models.CASCADE, to_field='task_id',null=True,blank=True)
    subtask = models.ForeignKey(Subtask, on_delete=models.CASCADE, to_field='subtask_id',null=True,blank=True)
    niuma_name = models.CharField(max_length=100)
    agent_type = models.CharField(max_length=100)
    progress = models.FloatField(default=0.0)
