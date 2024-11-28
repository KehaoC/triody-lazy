from django.shortcuts import render
import json
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
from django.db import transaction  # For atomic operations
from team.agents import Team
from team.models import Task, Subtask ,User # 导入模型
# Create your views here.

@csrf_exempt  # 禁用csrf保护
@require_http_methods(["POST"])  # 明确只允许 POST 请求
def create_task(request):
    try:
        data = json.loads(request.body)
        task_description = data.get("description")
        task_title = data.get("title")
        # user_id = data.get("user_id")  # 测试的时候使用1
        
        #TODO: 这里应该从request的Header头中获取用户的id，需要auth函数
        user_id = 1
        
        if not task_description:
            return JsonResponse({"error": "Task description is required"}, status=400)
        if not user_id:
            return JsonResponse({"error": "User ID is required"}, status=400)
        
        
        # Create a Task instance in the database
        task = Task.objects.create(
            title = task_title,  # Default title, modify as needed
            description =  task_description,
            user_id = user_id,
        )
        
        team = Team([], task)     
        # 构造响应数据
        response_data = {
            "status": "success",
            "message": "Task created successfully",
            "data": {
                "task_id": team.task_id,  # 假设 Team 对象的 task_id 属性是必需的
                "title": task.title,
                "description": task.description,
                "summary": None,  # 初始为空，假设未来会添加
                "is_finished": False,  # 新任务默认未完成
                "all_subtasks_lazied": False,  # 默认所有子任务未加载
            }
        }
        
        return JsonResponse(response_data, status=200)
    
    except Exception as e:
        # 捕获异常并返回错误响应
        return JsonResponse({"status": "error", "message": str(e)}, status=500)


@csrf_exempt  # 禁用 CSRF 保护
@require_http_methods(["DELETE"])  # 明确只允许 DELETE 请求
def delete_task(request):
    try:
        # 解析请求体中的 JSON 数据
        data = json.loads(request.body)
        task_id = data.get("task_id")
        
        # TODO: 从请求的 Header 中获取用户 ID，需要 auth 函数
        user_id = 1

        if not task_id:
            return JsonResponse({
                "status": "error",
                "message": "Task ID is required",
                "data": None
            }, status=400)
        
        # 转换 task_id 为整数类型
        try:
            task_id = int(task_id)
        except ValueError:
            return JsonResponse({
                "status": "error",
                "message": "Task ID must be an integer",
                "data": None
            }, status=400)
        
        # 使用事务确保任务和子任务同时删除
        with transaction.atomic():
            # 确保任务存在
            task = Task.objects.filter(task_id=task_id, user_id=user_id).first()
            if not task:
                return JsonResponse({
                    "status": "error",
                    "message": "Task not found",
                    "data": None
                }, status=404)

            # 删除相关子任务
            Subtask.objects.filter(task_id=task_id).delete()

            # 删除任务
            task.delete()

        # 返回成功响应
        return JsonResponse({
            "status": "success",
            "message": "Task deleted successfully",
            "data": None
        }, status=200)
    
    except Exception as e:
        # 捕获异常并返回错误信息
        return JsonResponse({
            "status": "error",
            "message": str(e),
            "data": None
        }, status=500)

@csrf_exempt  # 禁用csrf保护
@require_http_methods(["POST"])  # 明确只允许 POST 请求
def modify_task_status(request):
    try:
        # 解析请求体 JSON 数据
        data = json.loads(request.body)
        task_id = data.get("task_id")
        is_finished = data.get("is_finished")

        #TODO: 这里应该从request的Header头中获取用户的id，需要auth函数
        user_id = 1
        
        # 参数校验
        if not task_id:
            return JsonResponse({"error": "Task ID is required"}, status=400)
        if is_finished is None:
            return JsonResponse({"error": "is_finished is required"}, status=400)

        # 转换 task_id 和 is_finished
        try:
            task_id = int(task_id)  # 转换为整数
        except ValueError:
            return JsonResponse({"error": "Task ID must be an integer"}, status=400)
        
        # 转换 is_finished 为布尔值
        if is_finished.lower() in ["true", "1"]:
            is_finished = True
        elif is_finished.lower() in ["false", "0"]:
            is_finished = False
        else:
            return JsonResponse({"error": "is_finished must be 'true' or 'false'"}, status=400)

        task = Task.objects.filter(task_id=task_id,user_id=user_id).first()
        if not task:
            return JsonResponse({"error": "Task not found"}, status=404)

        # 更新任务状态
        task.is_finished = is_finished
        task.save()

        # 返回成功响应
        return JsonResponse({"message": f"Task {task_id} status updated to {is_finished}."}, status=200)

    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)


@csrf_exempt  # 禁用 CSRF 保护
@require_http_methods(["GET"])  # 明确只允许 GET 请求
def get_subtasks(request):
    try:
        # 解析请求体 JSON 数据
        data = json.loads(request.body)
        task_id = data.get("task_id")

        #TODO: 这里应该从request的Header头中获取用户的id，需要auth函数
        user_id = 1
    
        # 参数校验
        if task_id is None:
            return JsonResponse({"status": "error", "message": "Task ID is required"}, status=400)

        try:
            task_id = int(task_id)  # 确保 task_id 是整数
        except ValueError:
            return JsonResponse({"status": "error", "message": "Task ID must be an integer"}, status=400)

        # 获取任务的所有子任务
        subtasks = Subtask.objects.filter(task_id=task_id)

        if not subtasks.exists():
            return JsonResponse({"status": "error", "message": "No subtasks found for the given Task ID"}, status=404)

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

        # 返回成功响应
        response = {
            "status": "success",
            "message": "Subtasks fetched successfully",
            "data": {
                "subtasks": subtasks_data
            }
        }
        return JsonResponse(response, status=200, json_dumps_params={'ensure_ascii': False, 'indent': 4})

    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)}, status=500)

@csrf_exempt  # 禁用 CSRF 保护
@require_http_methods(["GET"])  # 明确只允许 GET 请求
def get_tasks(request):
    try:
        #TODO: 这里应该从request的Header头中获取用户的id，需要auth函数
        user_id = 1

        # 获取用户的所有任务
        tasks = Task.objects.filter(user_id=user_id)

        if not tasks.exists():
            return JsonResponse({"status": "error", "message": "No tasks found for the given User ID"}, status=404)

        # 格式化任务数据
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

        # 返回成功响应
        response = {
            "status": "success",
            "message": "Tasks fetched successfully",
            "data": {
                "tasks": tasks_data
            }
        }
        return JsonResponse(response, status=200, json_dumps_params={'ensure_ascii': False, 'indent': 4})

    except Exception as e:
        return JsonResponse({"status": "error", "message": str(e)}, status=500)
