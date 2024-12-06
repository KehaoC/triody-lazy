from django.shortcuts import render
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
from django.db import transaction  # For atomic operations

from team.agents import Team
from team.models import Task, Subtask ,User # 导入模型
from niuma.models import Niuma
from core.utils import auth_and_error_handler, api_response, require_auth

import json

@auth_and_error_handler(methods=["GET"])
def get_tasks_to_preview(request):
    # 1. 获取所有任务
    tasks = Task.objects.filter(user_id=request.user_id)
    data = []
    for task in tasks:
        # 2. 获取任务的牛马
        niumas = Niuma.objects.filter(task_id=task.task_id)
        # 3. 只返回预览需要的字段
        preview_data = {
            'id': task.task_id,
            'title': task.title,
            'description': task.description,
            'is_finished': task.is_finished,
            'all_subtasks_lazied': task.all_subtasks_lazied,
            'niumas': [niuma.to_dict() for niuma in niumas]
        }
        data.append(preview_data)
    
    return api_response(data, "Tasks fetched successfully")

@auth_and_error_handler(methods=["POST"])
def get_task_detail(request):
    # 1. 获取任务
    task_id = request.POST.get("task_id")
    task = Task.objects.filter(task_id=task_id, user_id=request.user_id).first()
    if not task:
        raise APIError("Task not found", status_code=404)
    
    # 2. 获取任务的子任务
    subtasks_in_task_detail = []
    subtasks = Subtask.objects.filter(task_id=task_id)

    for subtask in subtasks:
        # 3. 获取牛马
        niuma = Niuma.objects.filter(subtask_id=subtask.subtask_id).first()
        subtask_in_task_detail = {
            'id': subtask.subtask_id,
            'is_finished': subtask.is_lazied,

            'description': subtask.description,
            'result': subtask.result,

            'assigned_niuma_name': niuma.niuma_name,
            'progress': niuma.progress
        }
        subtasks_in_task_detail.append(subtask_in_task_detail)
    
    data = {
        'id': task.task_id,
        'title': task.title,
        'description': task.description,
        'summary': task.summary,

        'is_finished': task.is_finished,
        'all_subtasks_finished': task.all_subtasks_lazied,

        'sub_tasks_in_task_detail': subtasks_in_task_detail
    }
    return api_response(data, "Task detail fetched successfully")

@auth_and_error_handler(methods=["POST"])
def create_task(request):
    # 1. 获取任务信息
    title = request.POST.get("title")
    description = request.POST.get("description")
    auto: bool = request.POST.get("auto")

    # 2. 创建任务
    task = Task.objects.create(user_id=request.user_id, title=title, description=description, auto=auto)

    # 3. 返回任务信息
    data = {
        'id': task.task_id,
        'title': task.title,
        'description': task.description,
        'is_finished': task.is_finished,
        'all_subtasks_lazied': task.all_subtasks_lazied,
        'niumas': []  # 默认没有牛马
    }

    if auto:
        # 4. TODO:  异步防止阻塞
        team = Team(task)
        team.decompose_task()  # 会在team类中存储
        team.run()
    else:
        # TODO: 等待用户手动运行
        team = Team(task)  # 只创建，不运行
    return api_response(data, "Task created successfully")




@auth_and_error_handler(methods=["DELETE"])
def delete_task(request):
    task_id = request.POST.get("task_id")
    # TODO：这里需要再 save 来保留删除结果吗
    Task.objects.filter(task_id=task_id, user_id=request.user_id).delete()
    return api_response(message="Task deleted successfully")

@auth_and_error_handler(methods=["POST"])
def signal_task_run(request):
    task_id = request.POST.get("task_id")
    team = Team.objects.filter(task_id=task_id).first()
    if not team:
        raise APIError("Team not found", status_code=404)
    team.run()
    # TODO: 修改调度器中的任务状态
    return api_response(message="Task signaled to run successfully")

@auth_and_error_handler(methods=["POST"])
def modify_task_status(request):
    task_id = request.POST.get("task_id")
    is_finished = request.POST.get("is_finished")
    Task.objects.filter(task_id=task_id, user_id=request.user_id).update(is_finished=is_finished)
    return api_response(message="Task status modified successfully")