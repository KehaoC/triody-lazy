import Foundation

// CodingKeys 用于指定 JSON 中的键名, 处理前后端命名不一致的问题

struct TaskModel: Codable, Identifiable {
    let id: Int?
    let title: String
    let description: String
    let summary: String?
    var isFinished: Bool
    let allSubtasksLazied: Bool
    var subtasks: [Subtask]?

    init(title: String, description: String) {
        self.id = nil
        self.title = title
        self.description = description
        self.summary = nil
        self.isFinished = false
        self.allSubtasksLazied = false
        self.subtasks = nil
    }

    init(id: Int, title: String, description: String, summary: String?, isFinished: Bool, allSubtasksLazied: Bool, subtasks: [Subtask]) {
        self.id = id
        self.title = title
        self.description = description
        self.summary = summary
        self.isFinished = isFinished
        self.allSubtasksLazied = allSubtasksLazied
        self.subtasks = subtasks
    }

    enum CodingKeys: String, CodingKey {
        case id = "task_id"
        case title
        case description
        case summary
        case isFinished = "is_finished"
        case allSubtasksLazied = "all_subtasks_lazied"
        case subtasks
    }
}

struct Subtask: Codable, Identifiable {
    let id: Int
    let taskId: Int
    let description: String
    let agentName: String
    let isLazied: Bool
    let result: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "subtask_id"
        case taskId = "task_id"
        case description
        case agentName = "agent_name"
        case isLazied = "is_lazied"
        case result
    }
}
