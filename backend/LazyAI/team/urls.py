from django.urls import path
from team.views import create_task

urlpatterns = [
    path('create_task/', create_task, name='create_task'),
]