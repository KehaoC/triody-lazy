from team.prompts import *
from core.utils import beautyprint
from typing import List
from zhipuai import ZhipuAI
from groq import Groq
from team.models import Task, Subtask 
from niuma.models import Niuma
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

# 函数映射字典 - 确保键名与 agent_type 完全匹配
functions = {
    "leader": leader_chat,
    "searcher": searcher_chat,
    "outline_writer": outline_writer_chat,
    "coder": coder_chat,
}

class Agent:
    def __init__(self, name, system_prompt):
        self.name = name.lower()  # 转换为小写
        self.system_prompt = system_prompt
        self.chat_function = functions.get(self.name, get_response)  # 使用小写名称查找

    def chat(self, user_prompt):
        return self.chat_function(self.system_prompt, user_prompt)
# 默认执行器列表 - 使用小写的 agent_type

default_executors = [
    Agent("outline_writer", outline_writer_system_prompt),
    Agent("searcher", searcher_system_prompt),
    Agent("coder", coder_system_prompt),
]

class Team:
    def __init__(self, executors = None, task = None):
        self.leader = Agent("leader", leader_system_prompt)  

        # 可变Agent
        executors = executors if executors else default_executors
        self.executors = {executor.name.lower(): executor for executor in executors}  # 转换为小写
        self.task_title = task.title if task.title else ""
        self.task_description = task.description if task.description else ""
        self.subtasks = []
        self.task = task
        self.task_id = task.task_id if task else None
        if task:
            task.save()  # Save the task to the database

        print("Task initialized.")
    
    def decompose_task(self):
        print(f"Starting task decomposition for task: {self.task_title}")
        print(f"Task description: {self.task_description}")
            
        try:
            print("Sending request to leader agent...")
            leader_response = self.leader.chat(self.task_title + "\n" + self.task_description)
            print(f"Raw leader response: {leader_response}")
            
            subtask_dict = json.loads(leader_response)
            print(f"Parsed subtasks: {json.dumps(subtask_dict, indent=2)}")
        except json.JSONDecodeError as e:
            print(f"Error parsing leader response: {e}")
            print(f"Invalid JSON response: {leader_response}")
            return
        except Exception as e:
            print(f"Error decomposing task: {e}")
            return
        
        print("Starting transaction for subtask creation...")
        with transaction.atomic():
            for subtask_content in subtask_dict:
                print(f"\nProcessing subtask: {subtask_content}")
                try:
                    db_subtask, created = Subtask.objects.get_or_create(
                        task_id=self.task.task_id,
                        description=subtask_content['subtask_description'],
                        agent_type=subtask_content['agent_type'],
                        defaults={
                            'result': "",
                            'is_lazied': False
                        }
                    )
                    print(f"Subtask {'created' if created else 'retrieved'} with ID: {db_subtask.subtask_id}")

                    # 为子任务分配空闲且类型匹配的niuma
                    available_niuma = Niuma.objects.filter(
                        task_id__isnull=True,
                        agent_type=subtask_content['agent_type']
                    ).first()

                    if available_niuma:
                        available_niuma.task_id = self.task.task_id
                        available_niuma.subtask_id = db_subtask.subtask_id
                        available_niuma.save()
                        print(f"Assigned niuma {available_niuma.niuma_id} to subtask {db_subtask.subtask_id}")
                    else:
                        print(f"No available niuma found for agent type: {subtask_content['agent_type']}")

                    # 添加到 subtasks 列表中
                    self.subtasks.append(db_subtask)
                    print(f"Added subtask to internal list. Current count: {len(self.subtasks)}")

                except Exception as e:
                    print(f"Error creating or getting subtask: {e}")
                    print(f"Subtask content that caused error: {subtask_content}")

        print(f"Decomposition completed. Total subtasks created: {len(self.subtasks)}")

    def run(self):
        print("\n=== Starting LazyTeam run() ===")
        if not self.task_id:
            print("Task ID is required to save results to the database.")
            return
        
        print(f"Processing {len(self.subtasks)} subtasks...")
        
        # Execute tasks and store results
        try:
            for index, subtask in enumerate(self.subtasks, 1):
                print(f"\nProcessing subtask {index}/{len(self.subtasks)}")
                print(f"Subtask type: {subtask.agent_type}")
                print(f"Subtask description: {subtask.description}")
                
                # Use the subtask instance fields directly
                executor = self.executors.get(subtask.agent_type, None)
                if executor:
                    print(f"Found executor for {subtask.agent_type}, executing...")
                    subtask.result = executor.chat(subtask.description)
                    print(f"Execution result: {subtask.result}")
                else:
                    print(f"No executor found for agent type: {subtask.agent_type}")
                    subtask.result = "Sorry, I don't know how to do this."
                    # Mark the subtask as lazied
                    subtask.is_lazied = True
                    print("Marked subtask as lazied")
        except Exception as e:
            print(f"Error running subtasks: {e}")
            print(f"Error details: {str(e)}")
            
        print("\nUpdating database with results...")
        
        # Update database with results
        with transaction.atomic():
            print("Started database transaction")
            
            # 一定要有这个save()才会更新到远端数据库
            for index, subtask in enumerate(self.subtasks, 1):
                print(f"Saving subtask {index}/{len(self.subtasks)}")
                subtask.save()
                print(f"Subtask {subtask.subtask_id} saved successfully")

            # Check if all subtasks are lazied
            all_subtasks_lazied = all(subtask.is_lazied for subtask in self.subtasks)
            print(f"All subtasks lazied status: {all_subtasks_lazied}")

            # Update the parent task's status
            print(f"Updating parent task {self.task.task_id}")
            self.task.is_finished = True
            self.task.all_subtasks_lazied = all_subtasks_lazied
            self.task.save()
            print("Parent task updated successfully")
            
        print("=== LazyTeam run() completed ===\n")
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