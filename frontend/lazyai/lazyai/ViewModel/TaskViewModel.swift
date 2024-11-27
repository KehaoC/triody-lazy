import SwiftUI

class TaskViewModel: ObservableObject {
    @Published var tasks: [TaskModel] 

    init() {
        self.tasks = mockTasks
    }

    // View 中调用的时候不需要传入 id, 只需要传入 title 和 userId
    func createTask(userId: Int = 1, title: String) {
        // TODO: 创建任务
        let newTask = TaskModel(
            id: tasks.count + 1,
            userId: userId,
            title: title
        )
        print("In TaskViewModel: \(newTask)")
        tasks.append(newTask)
    }

}

var mockTasks: [TaskModel] = [
    TaskModel(
        id: 1,
        userId: 1,
        title: "Write a blog post",
        description: "Write a technical blog post about SwiftUI and MVVM",
        summary: "Create technical content about iOS development",
        isFinished: false,
        allSubtasksLazied: false,
        subtasks: [
            Subtask(id: 1, taskId: 1, description: "Research MVVM pattern", agentName: "researcher", isLazied: true, result: "MVVM research completed"),
            Subtask(id: 2, taskId: 1, description: "Write outline", agentName: "writer", isLazied: false, result: "")
        ]
    ),
    TaskModel(
        id: 2,
        userId: 1,
        title: "Implement user authentication",
        description: "Add user login and registration functionality",
        summary: "Setup user authentication system",
        isFinished: false,
        allSubtasksLazied: true,
        subtasks: [
            Subtask(id: 3, taskId: 2, description: "Design login UI", agentName: "designer", isLazied: true, result: "Login UI completed"),
            Subtask(id: 4, taskId: 2, description: "Implement auth logic", agentName: "developer", isLazied: true, result: "Auth logic implemented")
        ]
    ),
    TaskModel(
        id: 3,
        userId: 1,
        title: "Update app documentation",
        description: "Update README and API documentation",
        summary: "Maintain project documentation",
        isFinished: true,
        allSubtasksLazied: true,
        subtasks: [
            Subtask(id: 5, taskId: 3, description: "Update README", agentName: "writer", isLazied: true, result: "README updated"),
            Subtask(id: 6, taskId: 3, description: "Update API docs", agentName: "writer", isLazied: true, result: "API documentation completed")
        ]
    )
]
