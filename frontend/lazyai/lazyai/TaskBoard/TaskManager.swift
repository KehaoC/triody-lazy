import SwiftUI

class TaskManager: ObservableObject {
    @Published var taskList: [TaskToPreview] = []
    @Published var taskDetail: [TaskDetail] = []
    @Published var taskDetailId: Int?
    @Published var isLoading: Bool = true

    init() {
        Task {
            await loadInitialData()
        }
    }

    private func loadInitialData() async {
        await MainActor.run {
            isLoading = true
        }
        do {
            async let tasks = NetworkService.shared.getTasksToPreview()
            async let taskDetails = NetworkService.shared.getAllTaskDetails()
            
            let taskResults = try await tasks
            let taskDetailResults = try await taskDetails
            
            await MainActor.run {
                print("Update tasks")
                self.taskList = taskResults
                self.taskDetail = taskDetailResults
                self.isLoading = false
            }
        } catch {
            print("Failed to load initial data: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }

    func modifyTaskStatus(taskId: Int, isFinished: Bool) async throws {
        await MainActor.run {
            withAnimation {
                if let index = taskList.firstIndex(where: { $0.id == taskId }) {
                    taskList[index].isFinished = isFinished
                }
            }
        }
        
        do {
            try await NetworkService.shared.modifyTaskStatus(taskId: taskId, isFinished: isFinished)
        } catch {
            await MainActor.run {
                withAnimation {
                    if let index = taskList.firstIndex(where: { $0.id == taskId }) {
                        taskList[index].isFinished = !isFinished
                    }
                }
            }
            print("modifyTaskStatus error: \(error)")
            throw error
        }
    }

    func deleteTask(taskId: Int) async throws {
        let deletedTask = taskList.first { $0.id == taskId }
        await MainActor.run {
            withAnimation {
                taskList.removeAll { $0.id == taskId }
            }
        }
        
        do {
            try await NetworkService.shared.deleteTask(taskId: taskId)
        } catch {
            if let task = deletedTask {
                await MainActor.run {
                    withAnimation {
                        taskList.append(task)
                    }
                }
            }
            print("deleteTask error: \(error)")
            throw error
        }
    }

    func createTaskAuto(title: String, description: String) async throws -> Bool {
        let tempTask = TaskToPreview(id: -1, title: title, description: description, isFinished: false, allSubtasksLazied: false, niumas: [])
        
        await MainActor.run {
            withAnimation {
                taskList.append(tempTask)
            }
        }
        
        do {
            let newTask = try await NetworkService.shared.createTask(title: title, description: description, auto: true)
            
            await MainActor.run {
                withAnimation {
                    if let index = taskList.firstIndex(where: { $0.id == -1 }) {
                        taskList[index] = newTask!
                    }
                }
            }
            return true
        } catch {
            await MainActor.run {
                withAnimation {
                    taskList.removeAll { $0.id == -1 }
                }
            }
            print("createTask error: \(error)")
            return false
        }
    }

    func createTaskManual(title: String, description: String) async throws -> Bool {
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
        do {
            taskList = try await NetworkService.shared.getTasksToPreview()
            return true
        } catch {
            print("getTaskList error: \(error)")
            return false
        }
    }

    func getTaskDetail(taskId: Int) async throws {
        if taskDetail.contains(where: { $0.id == taskId }) {
            return
        }

        do {
            let newTaskDetail = try await NetworkService.shared.getTaskDetail(taskId: taskId)
            taskDetail.append(newTaskDetail!)
            taskDetailId = taskId
        } catch {
            print("getTaskDetail error: \(error)")
        }
    }

    func taskDetailWith(taskId: Int?) -> TaskDetail? {
        taskDetail.first { $0.id == taskId }
    }

    func pushTaskRun(taskId: Int) async throws -> Bool {
        do {
            try await NetworkService.shared.signalTaskRun(taskId: taskId)
            return true
        } catch {
            print("pushTaskRun error: \(error)")
            return false
        }
    }
}
