import Foundation

// CodingKeys 用于指定 JSON 中的键名, 处理前后端命名不一致的问题

struct TaskModel: Codable, Identifiable {
    let id: Int
    let userId: Int
    let title: String
    let description: String
    let summary: String?
    let isFinished: Bool
    let allSubtasksLazied: Bool
    var subtasks: [Subtask]?
    
    enum CodingKeys: String, CodingKey {
        case id = "task_id"
        case userId = "user_id"
        case title
        case description
        case summary
        case isFinished
        case allSubtasksLazied
        case subtasks
    }
}

struct Subtask: Codable, Identifiable {
    let id: Int
    let taskId: Int
    let description: String
    let agentName: String
    let isLazied: Bool
    let result: String
    
    enum CodingKeys: String, CodingKey {
        case id = "subtask_id"
        case taskId = "task_id"
        case description
        case agentName = "agent_name"
        case isLazied
        case result
    }
}
