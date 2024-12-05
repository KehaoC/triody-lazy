import SwiftUI

class TaskManager: ObservableObject {
    @Published private var taskList: [TaskToPreview] = []
    @Published private var taskDetail: [TaskDetail] = []

    init() {
        Task {
            // 初始化获取任务列表
            taskList = try await NetworkService.shared.getTasksToPreview()
        }
    }
	
	var getTasksToPreview: [TaskToPreview] {
		taskList
	}

    func modifyTaskStatus(taskId: Int, isFinished: Bool) async throws {
        do {
            try await NetworkService.shared.modifyTaskStatus(taskId: taskId, isFinished: isFinished)
        } catch {
            print("modifyTaskStatus error: \(error)")
        }
    }

    func deleteTask(taskId: Int) async throws {
        do {
            try await NetworkService.shared.deleteTask(taskId: taskId)
        } catch {
            print("deleteTask error: \(error)")
        }
    }

    func createTaskAuto(title: String, description: String) async throws -> Bool {
        // 自动创建任务, 自动分配牛马
        do {
            let newTask = try await NetworkService.shared.createTask(title: title, description: description, auto: true)
            taskList.append(newTask!)
            return true
        } catch {
            print("createTask error: \(error)")
            return false
        }
    }

    func createTaskManual(title: String, description: String) async throws -> Bool {
        // 手动创建任务, 不分配牛马
        do {
            let newTask = try await NetworkService.shared.createTask(title: title, description: description, auto: false)
            taskList.append(newTask!)
            return true
        } catch {
            print("createTask error: \(error)")
            return false
        }
    }

    func getTaskList() async throws -> Bool {
        // 获得在主页可以显示的任务列表
        // 也可以用于刷新
        do {
            // 获取成功
            taskList = try await NetworkService.shared.getTasksToPreview()
            return true
        } catch {
            // 获取失败
            print("getTaskList error: \(error)")
            return false
        }
    }

    func getTaskDetail(taskId: Int) async throws -> Int? {
        // 获取任务的详细信息
        if taskDetail.contains(where: { $0.id == taskId }) {
            return taskId
        }

        do {
            let newTaskDetail = try await NetworkService.shared.getTaskDetail(taskId: taskId)
            taskDetail.append(newTaskDetail!)
            return taskId
        } catch {
            print("getTaskDetail error: \(error)")
            return nil
        }
    }

    func taskDetailWith(taskId: Int?) -> TaskDetail? {
        taskDetail.first { $0.id == taskId }
    }

    func pushTaskRun(taskId: Int) async throws -> Bool {
        // 推送任务运行
        // 确保任务已经分配了牛马
        do {
            try await NetworkService.shared.signalTaskRun(taskId: taskId)
            return true
        } catch {
            print("pushTaskRun error: \(error)")
            return false
        }
    }
}
