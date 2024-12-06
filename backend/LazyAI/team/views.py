from team.agents import Team
from team.models import Task, Subtask # 导入模型
from niuma.models import Niuma
from core.utils import auth_and_error_handler, api_response
from core.utils.api import APIError
import json

@auth_and_error_handler(methods=["GET"])
def get_tasks_to_preview(request):
    try:
        print("Fetching tasks for user_id:", request.user_id)
        # 1. 获取所有任务
        tasks = Task.objects.filter(user_id=request.user_id)
        print(f"Found {len(tasks)} tasks")
        
        data = []
        for task in tasks:
            try:
                # 2. 获取任务的牛马
                niumas = Niuma.objects.filter(task_id=task.task_id)
                print(f"Found {len(niumas)} niumas for task {task.task_id}")
                
                # 3. 只返回预览需要的字段
                preview_data = {
                    'id': task.task_id,
                    'title': task.title,
                    'description': task.description,
                    'is_finished': task.is_finished,
                    'all_subtasks_lazied': task.all_subtasks_lazied,
                    'niumas': [{
                        'id': niuma.niuma_id,
                        'name': niuma.niuma_name,
                        'agentType': niuma.agent_type,
                        'progress': niuma.progress
                    } for niuma in niumas]
                }
                data.append(preview_data)
            except Exception as e:
                print(f"Error processing task {task.task_id}: {str(e)}")
                continue
        
        print("Successfully processed all tasks")
        return api_response(data, "Tasks fetched successfully")
        
    except Exception as e:
        print(f"Error in get_tasks_to_preview: {str(e)}")
        raise APIError(f"Failed to fetch tasks: {str(e)}")

@auth_and_error_handler(methods=["GET"])
def get_all_tasks_detail(request):
    print(f"Fetching all tasks details for user_id: {request.user_id}")
    tasks = Task.objects.filter(user_id=request.user_id)
    print(f"Found {len(tasks)} tasks")
    data = []
    
    for task in tasks:
        print(f"\nProcessing task {task.task_id}: {task.title}")
        # 获取任务的子任务
        subtasks_in_task_detail = []
        subtasks = Subtask.objects.filter(task_id=task.task_id)
        print(f"Found {len(subtasks)} subtasks for task {task.task_id}")

        for subtask in subtasks:
            print(f"\nProcessing subtask {subtask.subtask_id}")
            try:
                niuma = Niuma.objects.filter(subtask_id=subtask.subtask_id).first()
                print(f"Found niuma for subtask: {niuma.niuma_name if niuma else 'No niuma assigned'}")
                subtask_in_task_detail = {
                    'id': subtask.subtask_id,
                    'is_finished': subtask.is_lazied,
                    'description': subtask.description,
                    'result': subtask.result,
                    'assigned_niuma_name': niuma.niuma_name if niuma else None,
                    'progress': niuma.progress if niuma else 0.0
                }
                print(f"Subtask details: {subtask_in_task_detail}")
                subtasks_in_task_detail.append(subtask_in_task_detail)
            except Exception as e:
                print(f"Error getting niuma for subtask {subtask.subtask_id}: {e}")
                print(f"Error details: {str(e)}")
        
        task_detail = {
            'id': task.task_id,
            'title': task.title,
            'description': task.description,
            'summary': task.summary,
            'is_finished': task.is_finished,
            'all_subtasks_finished': task.all_subtasks_lazied,
            'subtasks': subtasks_in_task_detail
        }
        print(f"\nTask {task.task_id} details compiled: {task_detail}")
        data.append(task_detail)
    
    print(f"\nSuccessfully processed all {len(data)} tasks")
    return api_response(data, "Tasks fetched successfully")
@auth_and_error_handler(methods=["POST"])
def get_task_detail(request):
    # 解析 JSON 数据
    data = json.loads(request.body)
    task_id = data.get("task_id")
    task = Task.objects.filter(task_id=task_id, user_id=request.user_id).first()
    if not task:
        raise APIError("Task not found", status_code=404)
    # 2. 获取任务的子任务
    subtasks_in_task_detail = []
    subtasks = Subtask.objects.filter(task_id=task_id)

    for subtask in subtasks:
        # 3. 获取牛马
        try:
            niuma = Niuma.objects.filter(subtask_id=subtask.subtask_id).first()
            subtask_in_task_detail = {
                'id': subtask.subtask_id,
                'is_finished': subtask.is_lazied,
                'description': subtask.description,
                'result': subtask.result,
                'assigned_niuma_name': niuma.niuma_name if niuma else None,
                'progress': niuma.progress if niuma else 0.0
            }
            subtasks_in_task_detail.append(subtask_in_task_detail)
        except Exception as e:
            print(f"Error getting niuma for subtask {subtask.subtask_id}: {e}")
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
    # 解析 JSON 数据
    data = json.loads(request.body)
    title = data.get("title")
    description = data.get("description")
    auto = data.get("auto")


    # 2. 创建任务，暂时没有用到 auto 逻辑
    try:
        task = Task.objects.create(user_id=request.user_id, title=title, description=description)
    except Exception as e:
        print(f"failed here 1: {e}")
        raise APIError(f"Failed to create task: {str(e)}", status_code=500)

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
        try:
            print("Creating team...")
            team = Team(task=task)
        except Exception as e:
            print(f"failed here 2: {e}")
            raise APIError(f"Failed to create team: {str(e)}", status_code=500)
        print("Decomposing task...")
        team.decompose_task()  # 会在team类中存储
        print("Running subtasks...")
        team.run()
    else:
        # TODO: 等待用户手动运行
        team = Team(task=task)  # 只创建，不运行
    return api_response(data, "Task created successfully")

@auth_and_error_handler(methods=["POST"])
def delete_task(request):
    data = json.loads(request.body)
    task_id = data.get("task_id")
    # TODO：这里需要再 save 来保留删除结果吗
    Task.objects.filter(task_id=task_id, user_id=request.user_id).delete()
    return api_response(message="Task deleted successfully")

@auth_and_error_handler(methods=["POST"])
def signal_task_run(request):
    data = json.loads(request.body)
    task_id = data.get("task_id")
    team = Team.objects.filter(task_id=task_id).first()
    if not team:
        raise APIError("Team not found", status_code=404)
    team.run()
    # TODO: 修改调度器中的任务状态
    return api_response(message="Task signaled to run successfully")

@auth_and_error_handler(methods=["POST"])
def modify_task_status(request):
    data = json.loads(request.body)
    task_id = data.get("task_id")
    is_finished = data.get("is_finished")
    Task.objects.filter(task_id=task_id, user_id=request.user_id).update(is_finished=is_finished)
    return api_response(message="Task status modified successfully")