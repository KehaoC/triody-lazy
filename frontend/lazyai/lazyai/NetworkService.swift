import Foundation

// MARK: - TODO
class NetworkService{
	
	static let shared = NetworkService()
	
	let baseUrl = "http://127.0.0.1:8000/"
	let token: String
	
	private init() {
		let accessToken = try! KeychainManager.getToken() ?? ""
		self.token = "Bearer \(accessToken)"
	}
	
	func getTasksToPreview() async throws -> [TaskToPreview] {
        let endpoint = "team/get_tasks_to_preview"
        let method = "GET"
        
        let result: [TaskToPreview]? = try await request(to: endpoint, with: method)
        // 获得在主页可以显示的任务列表
        // header: token
    	print("getTaskToPreview")
		return result ?? []
	}
	
	// 获得任务详情
	func getTaskDetail(taskId: Int) async throws -> TaskDetail? {
        // header: token
        // body: task_id
        // return: TaskDetail
        let endpoint = "team/get_task_detail"
        let method = "GET"
        let body = ["task_id": taskId]

        let result: TaskDetail? = try await request(to: endpoint, with: method, loading: body)

		print("getTaskDetail")
		return result ?? nil
	}
	
    // 创建任务
	func createTask(title: String, description: String, auto: Bool) async throws -> TaskToPreview? {
        let endpoint = "team/create_task"
        let method = "POST"
        let body: [String : Any] = ["title": title, "description": description, "auto": auto]

        let result: TaskToPreview? = try await request(to: endpoint, with: method, loading: body)
		print("createTask")
		return result ?? nil
	}
	
	// 删除任务
	func deleteTask(taskId: Int) async throws {
        let endpoint = "team/delete_task"
        let method = "POST"
        let body = ["task_id": taskId]

        let _: EmptyResponse? = try await request(to: endpoint, with: method, loading: body)
		print("deleteTask")
	}

    // 推送任务运行
    func signalTaskRun(taskId: Int) async throws {
        let endpoint = "team/signal_task_run"
        let method = "POST"
        let body = ["task_id": taskId]

        let _: EmptyResponse? = try await request(to: endpoint, with: method, loading: body)
		print("signalTaskRun")
    }
	
	// 修改任务状态
	func modifyTaskStatus(taskId: Int, isFinished: Bool) async throws {
        let endpoint = "team/modify_task_status"
        let method = "POST"
        let body: [String : Any] = ["task_id": taskId, "is_finished": isFinished]

        let _: EmptyResponse? = try await request(to: endpoint, with: method, loading: body)
		print("modifyTaskStatus")
	}
	
	// 获得牛马数据
	func getAllNiuma() async throws -> [Niuma]? {
        let endpoint = "niuma/get_all_niuma"
        let method = "GET"

        let result: [Niuma]? = try await request(to: endpoint, with: method)
		print("get all niuma")
		return result ?? []
	}

    // 创建基础的牛马
    func createBasicNiuma() async throws -> [Niuma] {
        let endpoint = "niuma/create_basic_niuma"
        let method = "POST"

        let result: [Niuma]? = try await request(to: endpoint, with: method)
		print("createBasicNiuma")
		return result ?? []
    }

	// 获得 niuma 详情
	func getNiumaDetail(niumaId: Int) async throws -> NiumaDetail? {
        let endpoint = "niuma/get_niuma_detail"
        let method = "GET"
        let body = ["niuma_id": niumaId]

        let result: NiumaDetail? = try await request(to: endpoint, with: method, loading: body)
		print("getNiumaDetail")
		return result ?? nil
	}

    func assignNiumaToTask(niumaId: Int, taskId: Int) async throws {
        let endpoint = "niuma/assign_niuma_to_task"
        let method = "POST"
        let body = ["niuma_id": niumaId, "task_id": taskId]

        let _: EmptyResponse? = try await request(to: endpoint, with: method, loading: body)
		print("assignNiumaToTask")
    }

    func removeNiumaFromTask(niumaId: Int) async throws {
        let endpoint = "niuma/remove_niuma_from_task"
        let method = "POST"
        let body = ["niuma_id": niumaId]

        let _: EmptyResponse? = try await request(to: endpoint, with: method, loading: body)
		print("removeNiumaFromTask")
    }

    // MARK: - request 代码重用
    private func request<T: Decodable>(to endpoint: String, with method: String, loading body: [String: Any]? = nil) async throws -> T? {
        // 请求函数
        let url = URL(string: "\(baseUrl)\(endpoint)")!

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            let jsonData = try JSONSerialization.data(withJSONObject: body)
            request.httpBody = jsonData
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        do {
            let decoder = JSONDecoder()

            // 将返回的 json 中的下划线转换为驼峰命名
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let result = try decoder.decode(T.self, from: data)
            return result
        } catch {
            print("Error decoding response: \(error)")
            return nil
        }
    }
}

// Add this struct at the bottom of the file
private struct EmptyResponse: Codable {}
