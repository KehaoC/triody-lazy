from django.shortcuts import render
from django.http import JsonResponse
import json

from core.utils import auth_and_error_handler, api_response
from niuma.models import *
from team.models import *

# Create your views here.
@auth_and_error_handler(methods=["GET"])
def get_all_niuma(request):
    try:
        niumas = Niuma.objects.filter(user_id=request.user_id)
        # Convert queryset to list of dictionaries
        niuma_list = []
        for niuma in niumas:
            niuma_dict = {
                "id": niuma.niuma_id,
                "name": niuma.niuma_name,
                "agentType": niuma.agent_type,
                "progress": niuma.progress,
                "taskId": niuma.task_id,
                "subtaskId": niuma.subtask_id
            }
            niuma_list.append(niuma_dict)
    except Exception as e:
        print("errors here: ", e)
        return api_response(message="Niumas fetched failed", status_code=500)
    return api_response(niuma_list, "Niumas fetched successfully")

@auth_and_error_handler(methods=["POST"])
def create_basic_niuma(request):
    # 创建基础的三个牛马, 其他数据为空
    user = User.objects.get(id=request.user_id)
    try:
        niuma_list = [
            Niuma(
                user = user,
                task = None,
                subtask = None,
                niuma_name = "writer",
                agent_type = "writer",
                progress = 0.0,
            ),
            Niuma(
                user = user,
                task = None,
                subtask = None,
                niuma_name = "searcher",
                agent_type = "searcher",
                progress = 0.0,
            ),
            Niuma(
                user = user,
                task = None,
                subtask = None,
                niuma_name = "coder",
                agent_type = "coder",
                progress = 0.0,
            ),
        ]
        Niuma.objects.bulk_create(niuma_list)
    except Exception as e:
        print("errors here: ", e)
        return api_response(message="Niumas created failed", status_code=500)
    return api_response(message="Niumas created successfully")

@auth_and_error_handler(methods=["GET"])
def get_niuma_detail(request):
    # 从 URL 参数获取数据
    niuma_id = request.GET.get("niuma_id")
    niuma = Niuma.objects.get(id=niuma_id)

    # 2. 获取牛马所属的子任务
    subtask = Subtask.objects.get(id=niuma.subtask_id)

    data = {
        "id": niuma.niuma_id,
        "name": niuma.niuma_name,
        "agent_type": niuma.agent_type,

        "progress": niuma.progress,
        "task_id": subtask.task_id,

        "task_title": subtask.task.title,
        "subtask_description": subtask.description,

        "result": subtask.result,
    }
    return api_response(data, "Niuma fetched successfully")

@auth_and_error_handler(methods=["POST"])
def assign_niuma_to_task(request):
    data = json.loads(request.body)
    niuma_id = data.get("niuma_id")
    task_id = data.get("task_id")

    # TODO: 通知调度器, 这里修改的是数据库，不是缓存区
    Niuma.objects.filter(niuma_id=niuma_id).update(task_id=task_id)
    return api_response(message="Niuma assigned to task successfully")

@auth_and_error_handler(methods=["POST"])
def remove_niuma_from_task(request):
    data = json.loads(request.body)
    niuma_id = data.get("niuma_id")
    Niuma.objects.filter(niuma_id=niuma_id).update(task_id=None)

    # TODO: 通知调度器, 这里修改的是数据库，不是缓存区
    return api_response(message="Niuma removed from task successfully")

