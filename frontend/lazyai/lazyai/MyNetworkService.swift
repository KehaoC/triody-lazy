import Foundation

// MARK: - TODO
class MyNetworkService{
	
	
	static let shared = MyNetworkService()
	
	
	let baseUrl = "http://127.0.0.1:8000/team/"
	let token: String
	
	private init() {
		let accessToken = try! KeychainManager.getToken() ?? ""
		self.token = "Bearer \(accessToken)"
	}
	
	func getTasksToPreview() async throws -> [TaskToPreview] {
		print("getTaskToPreview")
		return []
	}
	
	// 获得首页下方的 niuma 列表
	func getNiumaHome() async throws -> NiumaHome {
		print("getNiumaHome")
		return NiumaHome(niumas: [Niuma(id: 1, name: "test", agentType: "test", progress: 0.5, taskId: 1, subtaskId: 1)])
	}
	
	// 获得任务详情
	func getTaskDetail(taskId: UUID) async throws -> TaskDetail {
		print("getTaskDetail")
	}
	
	// 获得 niuma 详情
	func getNiumaDetail(niumaId: Int) async throws -> NiumaDetail {
		print("getNiumaDetail")
	}
	
	// 创建任务
	func createTask(title: String, description: String) async throws -> TaskModel {
		print("createTask")
	}
	
	// 删除任务
	func deleteTask(taskId: UUID) async throws {
		print("deleteTask")
	}
	
	// 修改任务状态
	func modifyTaskStatus(taskId: UUID, isFinished: Bool) async throws {
		print("modifyTaskStatus")
	}
	
	// 获得牛马数据
	func getAllNiuma() async throws -> [Niuma]? {
		print("get all niuma")
		return []
	}
}

    // func createTask(title: String, description: String) async throws -> TaskModel {
    //     let url = URL(string: "\(baseUrl)create_task/")!
    //     var request = URLRequest(url: url)
    //     request.httpMethod = "POST"
    //     request.setValue(token, forHTTPHeaderField: "Authorization")
    //     request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
    //     let taskRequest = TaskRequest(title: title, description: description)
    //     request.httpBody = try JSONEncoder().encode(taskRequest)

    //     let (data, response) = try await URLSession.shared.data(for: request)
        
    //     guard let httpResponse = response as? HTTPURLResponse,
    //           (200...299).contains(httpResponse.statusCode) else {
    //         throw NSError(domain: "TaskService", code: -1, userInfo: [NSLocalizedDescriptionKey: "HTTP request failed"])
    //     }

    //     let apiResponse = try JSONDecoder().decode(APIResponse<TaskModel>.self, from: data)
    //     return apiResponse.data
    // }

    // func getTasks() async throws -> [TaskModel] {
    //     let url = URL(string: "\(baseUrl)get_tasks/")!
    //     var request = URLRequest(url: url)
    //     request.httpMethod = "GET"
    //     request.setValue(token, forHTTPHeaderField: "Authorization")
        
    //     let (data, response) = try await URLSession.shared.data(for: request)
        
    //     guard let httpResponse = response as? HTTPURLResponse,
    //           (200...299).contains(httpResponse.statusCode) else {
    //         throw NSError(domain: "TaskService", code: -1, userInfo: [NSLocalizedDescriptionKey: "HTTP request failed"])
    //     }

    //     let apiResponse = try JSONDecoder().decode(APIResponse<TasksData>.self, from: data)
    //     return apiResponse.data.tasks
    // }

    // func modifyTaskStatus(taskId: Int, isFinished: Bool) async throws {
    //     let url = URL(string: "\(baseUrl)modify_task_status/")!
    //     var request = URLRequest(url: url)
    //     request.httpMethod = "PUT"
    //     request.setValue(token, forHTTPHeaderField: "Authorization")
    //     request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
    //     struct ModifyStatusRequest: Codable {
    //         let task_id: String
    //         let is_finished: Bool
    //     }
        
    //     let modifyRequest = ModifyStatusRequest(task_id: String(taskId), is_finished: isFinished)
    //     request.httpBody = try JSONEncoder().encode(modifyRequest)
        
    //     let (_, response) = try await URLSession.shared.data(for: request)
        
    //     guard let httpResponse = response as? HTTPURLResponse,
    //           (200...299).contains(httpResponse.statusCode) else {
    //         throw NSError(domain: "TaskService", code: -1, userInfo: [NSLocalizedDescriptionKey: "HTTP request failed"])
    //     }
    // }

    // func deleteTask(taskId: Int) async throws {
    //     let url = URL(string: "\(baseUrl)delete_task/")!
    //     var request = URLRequest(url: url)
    //     request.httpMethod = "DELETE"
    //     request.setValue(token, forHTTPHeaderField: "Authorization")
    //     request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
    //     struct DeleteTaskRequest: Codable {
    //         let task_id: Int
    //     }
        
    //     let deleteRequest = DeleteTaskRequest(task_id: taskId)
    //     request.httpBody = try JSONEncoder().encode(deleteRequest)
        
    //     let (data, response) = try await URLSession.shared.data(for: request)
        
    //     guard let httpResponse = response as? HTTPURLResponse,
    //           (200...299).contains(httpResponse.statusCode) else {
    //         throw NSError(domain: "TaskService", code: -1, userInfo: [NSLocalizedDescriptionKey: "HTTP request failed"])
    //     }
        
    //     struct DeleteTaskResponse: Codable {
    //         let status: String
    //         let message: String
    //         let data: String?
    //     }
        
    //     _ = try JSONDecoder().decode(DeleteTaskResponse.self, from: data)
    // }

    // func getSubtasks(taskId: Int) async throws -> [Subtask] {
    //     let url = URL(string: "\(baseUrl)get_subtasks/")!
    //     var request = URLRequest(url: url)
    //     request.httpMethod = "POST"
    //     request.setValue(token, forHTTPHeaderField: "Authorization")
    //     request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        

    //     let subtaskRequest = SubtaskRequest(task_id: taskId)
    //     request.httpBody = try JSONEncoder().encode(subtaskRequest)
        
    //     let (data, response) = try await URLSession.shared.data(for: request)
        
    //     guard let httpResponse = response as? HTTPURLResponse,
    //           (200...299).contains(httpResponse.statusCode) else {
    //         throw NSError(domain: "TaskService", code: -1, userInfo: [NSLocalizedDescriptionKey: "HTTP request failed"])
    //     }
        
    //     let apiResponse = try JSONDecoder().decode(APIResponse<SubtasksData>.self, from: data)
    //     let subtasks: [Subtask] = apiResponse.data.subtasks.map {
    //         Subtask(
    //             id: $0.subtask_id,
    //             taskId: taskId,
    //             description: $0.description,
    //             agentName: $0.agent_name,
    //             isLazied: $0.is_lazied,
    //             result: $0.result ?? ""
    //         )
    //     }
    //     return subtasks
    // }

    // TODO: 

//}
//
//extension TaskService {
//
//    struct APIResponse<T: Codable>: Codable {
//        let status: String
//        let message: String
//        let data: T
//    }
//
//    struct TaskRequest: Codable {
//        let title: String
//        let description: String
//    }
//
//    struct SubtaskRequest: Codable {
//        let task_id: Int
//    }
//
//    struct TasksData: Codable {
//        let tasks: [TaskModel]
//    }
//
//    struct SubtasksData: Codable {
//        let subtasks: [SubtaskResponse]
//    }
//
//    struct SubtaskResponse: Codable {
//        let subtask_id: Int
//        let description: String
//        let agent_name: String
//        let is_lazied: Bool
//        let result: String?
//    }
//}
