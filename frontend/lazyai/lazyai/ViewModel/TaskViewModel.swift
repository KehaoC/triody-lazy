import SwiftUI

class TaskViewModel: ObservableObject {
    @Published var tasks: [TaskModel] 
    var taskService: TaskService

    init() {
        self.taskService = TaskService()
        self.tasks = []
        
        Task {
            do {
                print("Fetching tasks")
                let fetchedTasks = try await taskService.getTasks()
                await MainActor.run {
                    self.tasks = fetchedTasks
                }
            } catch {
                print("Failed to fetch tasks: \(error)")
                await MainActor.run {
                    self.tasks = mockTasks
                }
            }
        }
    }

    func createTask(title: String, description: String? = nil) async throws {
        let newTask = try await taskService.createTask(title: title, description: description ?? "")
        print("New task created: \(newTask)")
        await MainActor.run {
            tasks.append(newTask)
        }
    }

    func getTasks() async throws {
        tasks = try await taskService.getTasks()
    }

    func modifyTaskStatus(taskId: Int, isFinished: Bool) async throws {
        // 立即更新 UI
        await MainActor.run {
            if let index = tasks.firstIndex(where: { $0.id == taskId }) {
                withAnimation {
                    tasks[index].isFinished = isFinished
                }
            }
        }
        
        // 后台进行 API 调用
        try await taskService.modifyTaskStatus(taskId: taskId, isFinished: isFinished)
    }

    func deleteTask(taskId: Int) async throws {
        // 立即更新 UI
        await MainActor.run {
            withAnimation {
                tasks.removeAll(where: { $0.id == taskId })
            }
        }
        
        // 后台进行 API 调用
        try await taskService.deleteTask(taskId: taskId)
    }
}

var mockTasks: [TaskModel] = [
    TaskModel(
        id: 1,
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
