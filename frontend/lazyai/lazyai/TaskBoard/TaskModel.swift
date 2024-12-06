import Foundation

struct TaskToPreview: Identifiable, Codable {
    let id: Int
    let title: String
    var description: String?
    var isFinished: Bool
    var allSubtasksLazied: Bool
    let niumas: [NiumaToPreviewInTask]
}

struct TaskDetail: Identifiable, Codable {
	let id: Int
	let title: String
	let description: String?
	let summary: String?

	var isFinished: Bool
	var allSubtasksFinished: Bool

	let subtasks: [SubtaskInTaskDetail]?
}


	struct SubtaskInTaskDetail: Identifiable, Codable {
		let id: Int
		let isFinished: Bool

		let description: String?
		let result: String?

		let assignedNiumaName: String?
		let progress: Double
}
