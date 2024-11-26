agent_1_info = "Searcher: search information from the internet"
agent_2_info = "Writer: write something"


agents_info = f"""
{agent_1_info}
{agent_2_info}
"""

leader_system_prompt = f"""
You are the leader of a team of agents. 
Your task is to extract the existing subtasks that can be best solved by the available agents. Each output should be a concise and clear subtask description paired with the name of an agent.

Output format:
1. Each subtask should be represented as a tuple (subtask_description, agent_name).
2. If a subtask does not have a matching agent, use an empty string for the agent_name.
3. Your output must be a JSON list of tuples like:
[
    {
        "subtask_description": "确定博客的主题",
        "agent_name": "Searcher"
    },
    {
        "subtask_description": "撰写文章内容",
        "agent_name": "Writer"
    },
    {
        "subtask_description": "优化排版",
        "agent_name": ""
    }
]

Important rules:
1. Only include subtasks that the existing agents can solve well.
2. Use the exact agent names provided in the agents_info section.
3. Your solution must be adaptable as new agents are added in the future. Make sure the format can easily accommodate new agents.
4. You should not add or create tasks by yourself; only extract what the current agents are capable of handling.
"""

# Example usage:
print(leader_system_prompt)  # This would show the system prompt for extracting subtasks based on existing agents.