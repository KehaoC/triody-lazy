from team.prompts import *
from team.utils import beautyprint
from typing import List
from zhipuai import ZhipuAI
from groq import Groq
from team.models import Task, Subtask
from django.db import transaction  # For atomic operations
import json
from openai import OpenAI
import openai
import requests
from team.database import Database

def get_response(system_prompt: str, user_prompt: str, client: str = "groq") -> str:
    if client == "zhipuai":
        client = ZhipuAI(api_key="f3eb4e2ea260b190cfd33927d7034c34.rnN6WjfO2w5peFja")
        model = "glm-4-flash"
        response = client.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ]
        )
        return response.choices[0].message.content

    elif client == "groq":
        client = Groq(api_key="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")
        model = "llama3-8b-8192"
        response = client.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ]
        )
        return response.choices[0].message.content

    elif client == "openai":  # New GPT-4 logic
        openai.api_key = "your-openai-api-key"
        model = "gpt-4"
        response = openai.ChatCompletion.create(
            model=model,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ]
        )
        return response.choices[0].message.content
    
    elif client == "kimi":
        client = OpenAI(
            api_key = "sk-5kjr7mUBqHKhLpq1Ap7WZn9E4H3TfOx8kBBIoDOz2uWAmW75",
            base_url = "https://api.moonshot.cn/v1",
        )
        completion = client.chat.completions.create(
            model = "moonshot-v1-8k",
            messages = [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            temperature = 0.3,
        )
        return completion.choices[0].message.content
    
    elif client == "Coder-32B-Instruct":
        url = "https://api-inference.huggingface.co/models/Qwen/Qwen2.5-Coder-32B-Instruct"
        headers = {"Authorization": "Bearer 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"}
        payload = {
            "inputs": f"System: {system_prompt}\nUser: {user_prompt}",
            "parameters": {"max_length": 1000, "temperature": 0.7, "top_p": 0.9}
        }
        
        response = requests.post(url, headers=headers, json=payload)
        response_json = response.json()
        return response_json[0]["generated_text"].strip()

    else:
        raise ValueError(f"Unsupported client type: {client}")





# 定义不同 Agent 的特定功能
def writer_chat(system_prompt, user_prompt):
    return "Something2"

def searcher_chat(system_prompt, user_prompt):
    return get_response(system_prompt, user_prompt, client="zhipuai")

def leader_chat(system_prompt, user_prompt):
    return get_response(system_prompt, user_prompt, client="kimi")

def coder_chat(system_prompt, user_prompt):
    return get_response(system_prompt, user_prompt, client="Coder-32B-Instruct")

# 函数映射字典
functions = {
    "Leader": leader_chat,
    "Writer": writer_chat,
    "Searcher": searcher_chat,
    "Coder": coder_chat,
}

class Agent:
    def __init__(self, name, system_prompt):
        self.name = name
        self.system_prompt = system_prompt
        self.chat_function = functions.get(name, get_response)  # 默认使用基础的 get_response

    def chat(self, user_prompt):
        return self.chat_function(self.system_prompt, user_prompt)

default_excutors = [
    Agent("Writer", writer_system_prompt),
    Agent("Searcher", searcher_system_prompt),
    Agent("Searcher-Bio", searcher_system_prompt),
    Agent("Coder", coder_system_prompt),
]


class Team:
    def __init__(self, excutors, task_description, user_id):
        # Leader和Distributer是Team的固定Agent
        self.leader = Agent("Leader", leader_system_prompt)  
        # leader 了解系统能力的边界，知道什么能做好，什么做不了
        # Leader 对 task 进行解读，找到对应的 Agents 去解决特定问题
        # 输出[(subtask_description, agent_name), ...]
        # TODO： 如果Leader 可以清晰定义无法解决的任务的集合，则也可以展现给用户

        # 可变Agent
        excutors = excutors if excutors else default_excutors  # 如果传入为空那就默认，避免在 view 中定义
        self.excutors = {excutor.name: excutor for excutor in excutors}
        self.task_description = task_description
        self.subtasks = []

        # Create a Task instance in the database
        self.task = Task.objects.create(
            title = "New Task",  # Default title, modify as needed
            description = task_description,
            user_id = user_id,
        )
        
        self.task_id = self.task.task_id  # Save the generated task_id for reference
    
    def decompose_task(self):
        # TODO 修改prompt, 输出为[(subtask_description, agent_name), ...] agent 为空则为无法处理
        
        # 将任务分解为多个子任务
        leader_response = self.leader.chat(self.task_description)
        print(leader_response)

        subtask_dict = json.loads(leader_response) # 将json字符串转换为dict

        # 将subtask_dict 转换为subtasks，方便后续处理
        for subtask_content in subtask_dict:
            self.subtasks.append({
                "subtask_content": subtask_content['subtask_description'],
                "excutor_name": subtask_content['agent_name'],
                "excute_result": ""
            })
            
        #TODO :这里有必要先存储一遍吗 (应该不用，可以在执行结束后统一存储)
        # # Save results back to the database
        # with transaction.atomic():
        #     for subtask in self.subtasks:
        #         # Update or create the Subtask in the database
        #         db_subtask, created = Subtask.objects.get_or_create(
        #             task_id=self.task,
        #             description=subtask['subtask_content'],
        #             agent_name=subtask['excutor_name']
        #         )
        #         db_subtask.is_lazied = True
        #         db_subtask.result = subtask['excute_result']
        #         db_subtask.save()
        
    def run(self):
    if not self.task_id:
        print("Task ID is required to save results to the database.")
        return
    
    # Execute tasks and store results
    for subtask in self.subtasks:
        executor = self.executors.get(subtask['executor_name'], None)
        if executor:
            subtask['execute_result'] = executor.chat(subtask['subtask_content'])
            print(subtask['execute_result'])
        else:
            subtask['execute_result'] = "Sorry, I don't know how to do this."
    print(self.subtasks)

    # Update database with results
    with transaction.atomic():
        for subtask in self.subtasks:
            # Check if the subtask already exists
            existing_subtasks = Database.select(
                "Subtask",
                task_id=self.task.task_id,
                description=subtask['subtask_content'],
                agent_name=subtask['executor_name']
            )
            
            if existing_subtasks.exists():
                # If the subtask exists, update its fields
                Database.update(
                    "Subtask",
                    filters={
                        "task_id": self.task.task_id,
                        "description": subtask['subtask_content'],
                        "agent_name": subtask['executor_name']
                    },
                    updates={
                        "result": subtask['execute_result'],
                        "is_lazied": True
                    }
                )
            else:
                # If the subtask doesn't exist, create it
                Database.insert(
                    "Subtask",
                    task_id=self.task.task_id,
                    description=subtask['subtask_content'],
                    agent_name=subtask['executor_name'],
                    result=subtask['execute_result'],
                    is_lazied=True
                )

        # Check if all subtasks are marked as "lazied"
        all_subtasks_lazied = all(
            subtask['is_lazied'] for subtask in Database.select(
                "Subtask",
                task_id=self.task.task_id
            ).values("is_lazied")
        )

        # Update the parent task's status
        Database.update(
            "Task",
            filters={"task_id": self.task.task_id},
            updates={
                "is_finished": True,
                "all_subtasks_lazied": all_subtasks_lazied
            }
        )
    def run(self):
        if not self.task_id:
            print("Task ID is required to save results to the database.")
            return
        
        # Execute tasks and store results
        for subtask in self.subtasks:
            excutor = self.excutors.get(subtask['excutor_name'], None)
            if excutor:
                subtask['excute_result'] = excutor.chat(subtask['subtask_content'])
                print(subtask['excute_result'])
            else:
                subtask['excute_result'] = "Sorry, I don't know how to do this."
        print(self.subtasks)
        
        # Update database with results
        with transaction.atomic():
            for subtask in self.subtasks:
                # 创建子任务，直接存储到数据库中
                db_subtask, created = Subtask.objects.get_or_create(
                    task_id=self.task.task_id,  # Properly link to parent task
                    description=subtask['subtask_content'],
                    agent_name=subtask['excutor_name'],
                    defaults={
                        'result': subtask['excute_result'],
                        'is_lazied': True
                    }
                )
                
                # 如果本来就存在的话直接更新
                if not created:
                    db_subtask.result = subtask['excute_result']
                    db_subtask.is_lazied = True
                    db_subtask.save()

            # 确保都处理了，如果都处理了就更新状态
            all_subtasks_lazied = all(
                Subtask.objects.filter(task_id=self.task.task_id).values_list('is_lazied', flat=True)
            )
            
            self.task.is_finished = True
            self.task.allSubtasksLazied = all_subtasks_lazied
            self.task.save()
    
    def print_result(self):
        beautyprint(self.subtasks)

