from django.urls import path
from team.views import create_task,delete_task,get_subtasks,modify_task_status,get_tasks

urlpatterns = [
    path('create_task/', create_task, name='create_task'),
    path('delete_task/', delete_task, name='delete_task'),
    path('get_subtasks/', get_subtasks, name='get_subtasks'),
    path('modify_task_status/', modify_task_status, name='modify_task_status'),
    path('get_tasks/', get_tasks, name='get_tasks'),
]