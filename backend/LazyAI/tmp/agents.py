from prompts import *
from typing import List
from zhipuai import ZhipuAI
from groq import Groq
import json
from utils import beautyprint

def get_response(system_prompt: str, user_prompt: str, client: str = "zhipuai") -> str:
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

class Agent:
    def __init__(self, name, system_prompt):
        # 初始化，一个Agent只需要一个system prompt进行定义
        self.name = name
        self.system_prompt = system_prompt

    def chat(self, user_prompt):
        # 根据system prompt和user prompt，给出response
        return get_response(self.system_prompt, user_prompt)

class Team:
    def __init__(self, excutors, task):
        # Leader和Distributer是Team的固定Agent
        self.leader = Agent("Leader", leader_system_prompt)
        self.distributer = Agent("Distributer", distributer_system_prompt)

        # 可变Agent
        self.excutors = {excutor.name: excutor for excutor in excutors}

        # 任务
        self.task = task

        self.processes = []
    
    def decompose_task(self):
        # 将任务分解为多个子任务
        leader_response = self.leader.chat(self.task)
        print(leader_response)
        subtask_dict = json.loads(leader_response) # 将json字符串转换为dict
        for subtask_id, subtask_content in subtask_dict.items():
            self.processes.append({
                "subtask_id": subtask_id,
                "subtask_content": subtask_content,
                "excutor": "",
                "excute_result": ""
            })
    
    def distribute_task(self):
        # 将子任务分配给excutors
        subtask_list = [process["subtask_content"] for process in self.processes]
        distributer_response = self.distributer.chat(str(subtask_list))
        # update processes with excutor's name
        distributer_response_dict = json.loads(distributer_response)
        
        # 更新processes 中的excutor 名字
        for process in self.processes:
            process["excutor"] = distributer_response_dict[process["subtask_id"]]
    
    def run(self):
        # 执行任务
        print("Start running...")
        index = 0
        for process in self.processes:
            # 初始化本轮任务
            excutor = self.excutors[process["excutor"]]
            task = process["subtask_content"]
            hint = self.processes[index - 1]["excute_result"] if index > 0 else "" # 获取上一个任务的结果
            prompt = f"TASK: {task}\nHINT: {hint}"

            # 开始执行本轮
            print(f"excute subtask {index}: {task}")
            process["excute_result"] = excutor.chat(prompt)
            index += 1

        print("Run over.")
    
    def print_result(self):
        beautyprint(self.processes)

        

def main():
    # 自建Agent: Writer and Searcher
    writer = Agent("Writer", writer_system_prompt)
    searcher = Agent("Searcher", searcher_system_prompt)
    team = Team(excutors=[writer, searcher], task="Write a blog about multi-agent system")

    team.decompose_task()
    team.distribute_task()
    team.run()

    team.print_result()

if __name__ == "__main__":
    main()

