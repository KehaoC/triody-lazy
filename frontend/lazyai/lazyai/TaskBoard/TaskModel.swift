import Foundation

struct TaskToPreview: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let isFinished: Bool
    let allSubtasksLazied: Bool
    let niumas: [NiumaToPreviewInTask]
}



struct TaskDetail {
	let title: String
	let description: String
	let summary: String

	var isFinished: Bool
	var allSubtasksFinished: Bool

	let subtasksInTaskDetail: [SubtaskInTaskDetail]

}


struct SubtaskInTaskDetail {
	let id: Int
	let isFinished: Bool

	let description: String
	let result: String

	let assignedNiumaName: String
	let progress: Double
}
