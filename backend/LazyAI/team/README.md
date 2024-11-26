# 总结
目前实现了基本的框架，可以进行任务的分解和执行。

但是有一些问题存在：
1. 任务分解的目标不明确，我们只是想帮用户偷懒，所以是否可以告诉 Leader，对于这个大任务，拆分出其中部分可以被 AI 完美解决的部分来解决。而不是生成一个拓扑序列来执行，徒增复杂度。

# 拓展agents的流程
1. 写 agentname_chat 函数，定义 agent 的特定功能
2. 在 functions 中注册 agentname_chat 函数
3. 在 prompt 中注册 agentname 和 agentname_system_prompt