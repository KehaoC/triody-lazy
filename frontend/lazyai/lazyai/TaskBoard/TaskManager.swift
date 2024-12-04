import SwiftUI

class TaskManager: ObservableObject {
    @Published private var taskList: [TaskToPreview] = []

    init() {
		Task {
			try await self.taskList = MyNetworkService.shared.getTasksToPreview()
		}
    }
	
	var tasks: [TaskToPreview] {
		taskList
	}

    func modifyTaskStatus(taskId: UUID, isFinished: Bool) async throws {
        try await MyNetworkService.shared.modifyTaskStatus(taskId: taskId, isFinished: isFinished)
    }

    func deleteTask(taskId: UUID) async throws {
        try await MyNetworkService.shared.deleteTask(taskId: taskId)
    }

    func createTask(title: String, description: String) async throws {
        try await MyNetworkService.shared.createTask(title: title, description: description)
    }
}
