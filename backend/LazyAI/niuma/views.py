from django.shortcuts import render
from django.http import JsonResponse

from core.utils import auth_and_error_handler, api_response
from niuma.models import *
from team.models import *

# Create your views here.
@auth_and_error_handler(methods=["GET"])
def get_all_niuma(request):
    niumas = Niuma.objects.filter(user_id=request.user_id)
    return api_response(niumas, "Niumas fetched successfully")

@auth_and_error_handler(methods=["POST"])
def create_basic_niuma(request):
    # 创建基础的三个牛马, 其他数据为空
    niuma_list = [
        Niuma(name="Writer", agent_type="writer", user_id=request.user_id),
        Niuma(name="Researcher", agent_type="researcher", user_id=request.user_id),
        Niuma(name="Coder", agent_type="coder", user_id=request.user_id),
    ]
    Niuma.objects.bulk_create(niuma_list)
    return api_response(message="Niumas created successfully")

@auth_and_error_handler(methods=["GET"])
def get_niuma_detail(request):

    # 1. 获取牛马
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
    niuma_id = request.POST.get("niuma_id")
    task_id = request.POST.get("task_id")

    # TODO: 通知调度器, 这里修改的是数据库，不是缓存区
    Niuma.objects.filter(niuma_id=niuma_id).update(task_id=task_id)
    return api_response(message="Niuma assigned to task successfully")

@auth_and_error_handler(methods=["POST"])
def remove_niuma_from_task(request):
    niuma_id = request.POST.get("niuma_id")
    Niuma.objects.filter(niuma_id=niuma_id).update(task_id=None)

    # TODO: 通知调度器, 这里修改的是数据库，不是缓存区
    return api_response(message="Niuma removed from task successfully")

