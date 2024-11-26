from prompts import *
from typing import List
from zhipuai import ZhipuAI
from groq import Groq
import json
from utils import beautyprint

def get_response(system_prompt: str, user_prompt: str, client: str = "groq") -> str:
    if client == "zhipuai":
        client = ZhipuAI(api_key="f3eb4e2ea260b190cfd33927d7034c34.rnN6WjfO2w5peFja")  
        model = "glm-4-flash"
    elif client == "groq":
        client = Groq(api_key="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")
        model = "llama3-8b-8192"

    response = client.chat.completions.create(
        model=model,  # 这个模型不要改，其他的都是付费模型，这个是免费的
        messages=[
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ]
    )
    return response.choices[0].message.content

# 定义不同 Agent 的特定功能
def writer_chat(system_prompt, user_prompt):
    return "Something2"

def searcher_chat(system_prompt, user_prompt):
    return "Something"

# 函数映射字典
functions = {
    "Writer": writer_chat,
    "Searcher": searcher_chat,
}

class Agent:
    def __init__(self, name, system_prompt):
        self.name = name
        self.system_prompt = system_prompt
        self.chat_function = functions.get(name, get_response)  # 默认使用基础的 get_response

    def chat(self, user_prompt):
        return self.chat_function(self.system_prompt, user_prompt)
    
class Team:
    def __init__(self, excutors, task):
        # Leader和Distributer是Team的固定Agent
        self.leader = Agent("Leader", leader_system_prompt)  
        # leader 了解系统能力的边界，知道什么能做好，什么做不了
        # Leader 对 task 进行解读，找到对应的 Agents 去解决特定问题
        # 输出[(subtask_description, agent_name), ...]
        # TODO： 如果Leader 可以清晰定义无法解决的任务的集合，则也可以展现给用户

        # 可变Agent
        self.excutors = {excutor.name: excutor for excutor in excutors}

        # 任务
        self.task = task
        self.subtasks = []
    
    def decompose_task(self):
        # 将任务分解为多个子任务
        # TODO 修改prompt, 输出为[(subtask_description, agent_name), ...] agent 为空则为无法处理
        leader_response = self.leader.chat(self.task)
        print(leader_response)

        subtask_dict = json.loads(leader_response) # 将json字符串转换为dict
        for subtask_content in subtask_dict:
            self.subtasks.append({
                "subtask_content": subtask_content,
                "excutor": "",
                "excute_result": ""
            })
    
    def run(self):
        # 执行任务, 根据 subtasks 和 excutors 执行任务
        pass
    
    def print_result(self):
        beautyprint(self.subtasks)

        

def main():
    pass

if __name__ == "__main__":
    main()

