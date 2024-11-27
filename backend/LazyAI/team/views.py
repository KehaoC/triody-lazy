from django.shortcuts import render
import json
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.views.decorators.http import require_http_methods
from team.agents import Team
# Create your views here.

@csrf_exempt  # 禁用csrf保护
@require_http_methods(["POST"])  # 明确只允许 POST 请求
def create_task(request):
    try:
        data = json.loads(request.body)
        task_description = data.get("task_description")
        user_id = data.get("user_id")  # 测试的时候使用1

        if not task_description:
            return JsonResponse({"error": "Task description is required"}, status=400)
        if not user_id:
            return JsonResponse({"error": "User ID is required"}, status=400)

        team = Team([], task_description, user_id)

        # 成功返回task_id
        return JsonResponse({"task_id": team.task_id}, status=200)
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=500)
