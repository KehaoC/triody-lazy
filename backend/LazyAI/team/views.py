from django.shortcuts import render
import json
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
from django.db import transaction  # For atomic operations
from team.agents import Team
from team.models import Task, Subtask ,User # 导入模型
from team.utils import api_error_handler, APIError, api_response, require_auth
# Create your views here.

@csrf_exempt  # 禁用csrf保护
@require_http_methods(["POST"])  # 明确只允许 POST 请求
@api_error_handler
@require_auth
def create_task(request):
    user_id = request.user_id
    try:
        data = json.loads(request.body)
    except json.JSONDecodeError:
        raise APIError("Invalid JSON format", status_code=400)
        
    task_description = data.get("description")
    task_title = data.get("title")
    
    if not task_description:
        raise APIError("Task description is required")

    task = Task.objects.create(
        title=task_title,
        description=task_description,
        user_id=user_id,
    )
    
    team = Team([], task)     
    response_data = {
        "task_id": team.task_id,
        "title": task.title,
        "description": task.description,
        "summary": None,
        "is_finished": False,
        "all_subtasks_lazied": False,
    }
    
    return api_response(response_data, "Task created successfully")

@csrf_exempt
@require_http_methods(["DELETE"])
@api_error_handler
@require_auth
def delete_task(request):
    try:
        data = json.loads(request.body)
    except json.JSONDecodeError:
        raise APIError("Invalid JSON format", status_code=400)
        
    task_id = data.get("task_id")

    if not task_id:
        raise APIError("Task ID is required")
    
    try:
        task_id = int(task_id)
    except ValueError:
        raise APIError("Task ID must be an integer")
    
    with transaction.atomic():
        task = Task.objects.filter(task_id=task_id, user_id=user_id).first()
        if not task:
            raise APIError("Task not found", status_code=404)

        Subtask.objects.filter(task_id=task_id).delete()
        task.delete()

    return api_response(message="Task deleted successfully")

@csrf_exempt
@require_http_methods(["GET"])
@api_error_handler
@require_auth
def get_tasks(request):
    user_id = request.user_id
    tasks = Task.objects.filter(user_id=user_id)

    if not tasks.exists():
        raise APIError("No tasks found for the given User ID", status_code=404)

    tasks_data = [
        {
            "task_id": task.task_id,
            "title": task.title,
            "description": task.description,
            "summary": task.summary,
            "is_finished": task.is_finished,
            "all_subtasks_lazied": task.all_subtasks_lazied
        }
        for task in tasks
    ]

    return api_response({"tasks": tasks_data}, "Tasks fetched successfully")

@csrf_exempt
@require_http_methods(["PUT"])
@api_error_handler
@require_auth
def modify_task_status(request):
    try:
        data = json.loads(request.body)
    except json.JSONDecodeError:
        raise APIError("Invalid JSON format", status_code=400)
        
    task_id = data.get("task_id")
    is_finished = data.get("is_finished")
    user_id = request.user_id

    if task_id is None:
        raise APIError("Task ID is required")
        
    if is_finished is None:
        raise APIError("is_finished status is required")

    try:
        task_id = int(task_id)
    except ValueError:
        raise APIError("Task ID must be an integer")

    # 验证任务是否属于当前用户并更新状态
    task = Task.objects.filter(task_id=task_id, user_id=user_id).first()
    if not task:
        raise APIError("Task not found", status_code=404)

    task.is_finished = is_finished
    task.save()

    return api_response(
        data={
            "task_id": task.task_id,
            "is_finished": task.is_finished
        },
        message="Task status updated successfully"
    )


@csrf_exempt
@require_http_methods(["GET"])
@api_error_handler
@require_auth
def get_subtasks(request):
    try:
        data = json.loads(request.body)
    except json.JSONDecodeError:
        raise APIError("Invalid JSON format", status_code=400)
        
    task_id = data.get("task_id")
    user_id = request.user_id

    if task_id is None:
        raise APIError("Task ID is required")

    try:
        task_id = int(task_id)
    except ValueError:
        raise APIError("Task ID must be an integer")

    # 验证任务是否属于当前用户
    task = Task.objects.filter(task_id=task_id, user_id=user_id).first()
    if not task:
        raise APIError("Task not found", status_code=404)

    # 获取任务的所有子任务
    subtasks = Subtask.objects.filter(task_id=task_id)
    if not subtasks.exists():
        raise APIError("No subtasks found for the given Task ID", status_code=404)

    # 格式化子任务数据
    subtasks_data = [
        {
            "subtask_id": subtask.subtask_id,
            "description": subtask.description,
            "agent_name": subtask.agent_name,
            "is_lazied": subtask.is_lazied,
            "result": subtask.result,
        }
        for subtask in subtasks
    ]

    return api_response(
        data={"subtasks": subtasks_data},
        message="Subtasks fetched successfully"
    )
