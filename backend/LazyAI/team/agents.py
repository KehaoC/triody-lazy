from team.prompts import *
from core.utils import beautyprint
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
            "parameters": {"max_length": 300, "temperature": 0.7, "top_p": 0.9}
        }
        
        response = requests.post(url, headers=headers, json=payload)
        response_json = response.json()
        return response_json[0]["generated_text"].strip()
    
    elif client == "bocha":
        url = "https://api.bochaai.com/v1/web-search"  # 博查 AI 搜索 API
        headers = {
            "Authorization": f"Bearer sk-f7ffbecba7fb4ea187c6ed63903f9ed8",#apikey
            "Content-Type": "application/json"
        }
        params = {
            "query": user_prompt,
            "count": 4 , # 获取前 4 个搜索结果
            "summary": True # 返回摘要
        }
        response = requests.post(url, headers=headers, json=params)
        return response.json()  # 返回 JSON 格式的搜索结果


    else:
        raise ValueError(f"Unsupported client type: {client}")

def text_enhancer(search_ai_name: str, search_results, refine_ai_name: str,system_prompt):
    if(search_ai_name == "bocha"):
         # 获取 data -> webPage -> value 中的所有网页数据
        web_page_values = search_results.get("data", {}).get("webPages", {}).get("value", [])
        # 提取 name, url, snippet 信息
        extracted_data = []
        for page in web_page_values:
            name = page.get("name", "")
            url = page.get("url", "")
            snippet = page.get("snippet", "")
            summary = page.get("summary", "")
            extracted_data.append(f"Name: {name}\nURL: {url}\nSnippet: {snippet}\nSummary:{summary}\n")
    
        # 将Jason提取并转化为文本
        search_text = "\n".join(extracted_data)
        return get_response(system_prompt,search_text,refine_ai_name)
               
    elif search_ai_name == "others":
        pass

# 定义不同 Agent 的特定功能
def outline_writer_chat(system_prompt, user_prompt):
    return get_response(system_prompt, user_prompt, client="groq")

def searcher_chat(system_prompt, user_prompt):
    #return get_response(system_prompt, user_prompt, client="zhipuai")
    search_results = get_response(system_prompt, user_prompt, client="bocha")
    return text_enhancer("bocha", search_results, "zhipuai",system_prompt)

def leader_chat(system_prompt, user_prompt):
    return get_response(system_prompt, user_prompt, client="kimi")

def coder_chat(system_prompt, user_prompt):
    return get_response(system_prompt, user_prompt, client="Coder-32B-Instruct")

# 函数映射字典
functions = {
    "Leader": leader_chat,
    "Outline_Writer": outline_writer_chat,
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

default_executors = [
    Agent("Outline_Writer", outline_writer_system_prompt),
    Agent("Searcher", searcher_system_prompt),
    Agent("Coder", coder_system_prompt),
]


class Team:
    def __init__(self, executors, task):
        # Leader和Distributer是Team的固定Agent
        self.leader = Agent("Leader", leader_system_prompt)  
        # leader 了解系统能力的边界，知道什么能做好，什么做不了
        # Leader 对 task 进行解读，找到对应的 Agents 去解决特定问题
        # 输出[(subtask_description, agent_type), ...]
        # TODO： 如果Leader 可以清晰定义无法解决的任务的集合，则也可以展现给用户

        # 可变Agent
        executors = executors if executors else default_executors  # 如果传入为空那就默认，避免在 view 中定义
        self.executors = {executor.name: executor for executor in executors}
        self.task_description = task.description
        self.subtasks = []
        self.task = task
        self.task_id = task.task_id  # Save the generated task_id for reference
        task.save()  # Save the task to the database
    
    def decompose_task(self):
        # TODO 修改prompt, 输出为[(subtask_description, agent_type), ...] agent 为空则为无法处理
        
        # 将任务分解为多个子任务
        leader_response = self.leader.chat(self.task_description)
        print(leader_response)

        subtask_dict = json.loads(leader_response) # 将json字符串转换为dict
        
        with transaction.atomic():
            for subtask_content in subtask_dict:
                # 创建或获取 Subtask 模型实例
                db_subtask, created = Subtask.objects.get_or_create(
                    task_id=self.task.task_id,  # 将任务正确链接
                    description=subtask_content['subtask_description'],
                    agent_type=subtask_content['agent_type'],
                    defaults={
                        'result': "",  # 初始结果为空
                        'is_lazied': False  # 标记为未处理
                    }
                )
                # 添加到 subtasks 列表中
                self.subtasks.append(db_subtask)
        
    def run(self):
        if not self.task_id:
            print("Task ID is required to save results to the database.")
            return
        
        # Execute tasks and store results
        for subtask in self.subtasks:
            # Use the subtask instance fields directly
            executor = self.executors.get(subtask.agent_type, None)
            if executor:
                subtask.result = executor.chat(subtask.description)
                print(subtask.result)
            else:
                subtask.result = "Sorry, I don't know how to do this."
            # Mark the subtask as lazied
            subtask.is_lazied = True
            
        self.print_subtasks_as_json(self.subtasks)
        
        # Update database with results
        with transaction.atomic():
            # 一定要有这个save()才会更新到远端数据库
            for subtask in self.subtasks:
                subtask.save()

            # Check if all subtasks are lazied
            all_subtasks_lazied = all(subtask.is_lazied for subtask in self.subtasks)

            # Update the parent task's status
            self.task.is_finished = True
            self.task.all_subtasks_lazied = all_subtasks_lazied
            self.task.save()
    
    def print_result(self):
        beautyprint(self.subtasks)

    def print_subtasks_as_json(self,subtasks):
        """
        将子任务列表打印为 JSON 格式，仅包含 description, agent_type, result 字段。
    
        :param subtasks: 子任务实例列表
        """
        # Prepare JSON output
        subtasks_json = [
            {
                "description": subtask.description,
                "agent_type": subtask.agent_type,
                "result": subtask.result
            }
            for subtask in subtasks
        ]
    
        # Print JSON
        print(json.dumps(subtasks_json, indent=4, ensure_ascii=False))