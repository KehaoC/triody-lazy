from django.urls import path
from team.views import *

urlpatterns = [
    path('get_tasks_to_preview/', get_tasks_to_preview, name='get_tasks_to_preview'),
    path('get_task_detail/', get_task_detail, name='get_task_detail'),
    path('create_task/', create_task, name='create_task'),
    path('delete_task/', delete_task, name='delete_task'),
    path('signal_task_run/', signal_task_run, name='signal_task_run'),
    path('modify_task_status/', modify_task_status, name='modify_task_status'),
]