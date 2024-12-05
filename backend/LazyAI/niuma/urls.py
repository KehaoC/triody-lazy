from django.urls import path
from niuma.views import create_niuma,delete_niuma,get_niumas,modify_niuma_status,get_niumas
urlpatterns = [
    path('create_task/', create_task, name='create_task'),
    path('delete_task/', delete_task, name='delete_task'),
    path('get_subtasks/', get_subtasks, name='get_subtasks'),
    path('modify_task_status/', modify_task_status, name='modify_task_status'),
    path('get_tasks/', get_tasks, name='get_tasks'),
]