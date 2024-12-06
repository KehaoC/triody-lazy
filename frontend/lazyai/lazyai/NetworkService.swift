import Foundation

// MARK: - TODO
class NetworkService{
	
	static let shared = NetworkService()
	
	let baseUrl = "http://127.0.0.1:8000/"
	let token: String
	
	private init() {
        // TODO 这里有的时候加不上去是怎么回事
		var accessToken = ""
		for _ in 0..<3 {
			if let token = try? KeychainManager.getToken() {
				accessToken = token
				break
			}
		}
		self.token = "Bearer \(accessToken)"
	}
	
    // MARK: - Team - task related
	func getTasksToPreview() async throws -> [TaskToPreview] {
        let endpoint = "team/get_tasks_to_preview/"
        let method = "GET"
        
        let result: [TaskToPreview]? = try await request(to: endpoint, with: method)
        // 获得在主页可以显示的任务列表
        // header: token
    	print("getTaskToPreview")
		return result ?? []
	}
	
	func getTaskDetail(taskId: Int) async throws -> TaskDetail? {
        // header: token
        // body: task_id
        // return: TaskDetail
        let endpoint = "team/get_task_detail/"
        let method = "POST"
        let body = ["task_id": taskId]

        let result: TaskDetail? = try await request(to: endpoint, with: method, loading: body)

		print("getTaskDetail")
		return result ?? nil
	}

    func getAllTaskDetails() async throws -> [TaskDetail] {
        let endpoint = "team/get_all_tasks_detail/"
        let method = "GET"
        
        let result: [TaskDetail]? = try await request(to: endpoint, with: method)
        
        if let taskDetails = result {
            for task in taskDetails {
                print("Task: \(task.title)")
                if let subtasks = task.subtasks {
                    for subtask in subtasks {
                        print("  Subtask ID: \(subtask.id)")
                        print("  Description: \(subtask.description ?? "No description")")
                        print("  Result: \(subtask.result ?? "No result")")
                        print("  Assigned Niuma: \(subtask.assignedNiumaName ?? "No niuma assigned")")
                        print("  Progress: \(subtask.progress)")
                        print("  Is Finished: \(subtask.isFinished)")
                        print("  ---")
                    }
                }
            }
        }
        
        return result ?? []
    }

	
    // TODO: 创建任务, 自动者手动逻辑继续实现
	func createTask(title: String, description: String, auto: Bool) async throws -> TaskToPreview? {
        let endpoint = "team/create_task/"
        let method = "POST"
        let body: [String : Any] = ["title": title, "description": description, "auto": auto]

        let result: TaskToPreview? = try await request(to: endpoint, with: method, loading: body)
		print("createTask")
		return result ?? nil
	}
	
	func deleteTask(taskId: Int) async throws {
        let endpoint = "team/delete_task/"
        let method = "POST"
        let body = ["task_id": taskId]

        let _: EmptyResponse? = try await request(to: endpoint, with: method, loading: body)
		print("deleteTask")
	}

    // TODO: 推送任务运行
    func signalTaskRun(taskId: Int) async throws {
        let endpoint = "team/signal_task_run/"
        let method = "POST"
        let body = ["task_id": taskId]

        let _: EmptyResponse? = try await request(to: endpoint, with: method, loading: body)
		print("signalTaskRun")
    }
	
	func modifyTaskStatus(taskId: Int, isFinished: Bool) async throws {
        let endpoint = "team/modify_task_status/"
        let method = "POST"
        let body: [String : Any] = ["task_id": taskId, "is_finished": isFinished]

        let _: EmptyResponse? = try await request(to: endpoint, with: method, loading: body)
		print("modifyTaskStatus")
	}
	
    // MARK: - Niuma related
	func getAllNiuma() async throws -> [Niuma]? {
        let endpoint = "niuma/get_all_niuma/"
        let method = "GET"

        let result: [Niuma]? = try await request(to: endpoint, with: method)
		print("get all niuma")
		return result ?? []
	}

    func createBasicNiuma() async throws -> [Niuma] {
        let endpoint = "niuma/create_basic_niuma/"
        let method = "POST"

        let result: [Niuma]? = try await request(to: endpoint, with: method)
		print("createBasicNiuma")
		return result ?? []
    }

    // TODO: 获得 niuma 详情
	func getNiumaDetail(niumaId: Int) async throws -> NiumaDetail? {
        let endpoint = "niuma/get_niuma_detail/"
        let method = "POST"
        let body = ["niuma_id": niumaId]

        let result: NiumaDetail? = try await request(to: endpoint, with: method, loading: body)
		print("getNiumaDetail")
		return result ?? nil
	}

    func assignNiumaToTask(niumaId: Int, taskId: Int) async throws {
        let endpoint = "niuma/assign_niuma_to_task/"
        let method = "POST"
        let body = ["niuma_id": niumaId, "task_id": taskId]

        let _: EmptyResponse? = try await request(to: endpoint, with: method, loading: body)
		print("assignNiumaToTask")
    }

    func removeNiumaFromTask(niumaId: Int) async throws {
        let endpoint = "niuma/remove_niuma_from_task/"
        let method = "POST"
        let body = ["niuma_id": niumaId]

        let _: EmptyResponse? = try await request(to: endpoint, with: method, loading: body)
		print("removeNiumaFromTask")
    }

    // MARK: - request 
    private func request<T: Codable>(to endpoint: String, with method: String, loading body: [String: Any]? = nil) async throws -> T? {
        // 数据使用 json 格式传递

        let url = URL(string: "\(baseUrl)\(endpoint)")!
        // print("request to url: \(url)")
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: body)
                request.httpBody = jsonData
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    print("Request body JSON: \(jsonString)")
                }
            } catch {
                print("Error serializing body: \(error)")
            }
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            // 解码为 APIResponse
            let apiResponse = try decoder.decode(APIResponse<T>.self, from: data)
            
            // 检查状态
            guard apiResponse.status == "success" else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: apiResponse.message])
            }
            
            return apiResponse.data
        } catch {
            print("Error decoding response: \(error)")
            throw error
        }
    }
}

// Add this struct at the bottom of the file
private struct EmptyResponse: Codable {}

// 添加通用响应模型
struct APIResponse<T: Codable>: Codable {
    let status: String
    let message: String
    let data: T?
}
