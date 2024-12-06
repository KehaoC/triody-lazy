import Foundation

struct TaskToPreview: Identifiable, Codable {
    let id: Int
    let title: String
    let description: String
    let isFinished: Bool
    let allSubtasksLazied: Bool
    let niumas: [NiumaToPreviewInTask]
}

struct TaskDetail: Identifiable, Codable {
	let id: Int
	let title: String
	let description: String
	let summary: String

	var isFinished: Bool
	var allSubtasksFinished: Bool

	let subtasksInTaskDetail: [SubtaskInTaskDetail]?
}

struct SubtaskInTaskDetail: Identifiable, Codable {
	let id: Int
	let isFinished: Bool

	let description: String
	let result: String

	let assignedNiumaName: String
	let progress: Double
}
