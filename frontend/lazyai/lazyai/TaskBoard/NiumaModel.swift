import Foundation
import SwiftUI

// 空闲的 niuma 列表
struct NiumaHome {
	let niumas: [NiumaInHome]

	var niumaCount: Int {
		return niumas.count
	}
}

struct NiumaInHome {
	let id: Int
	let name: String
	let agentType: String
}

struct NiumaDetail {
	// 基本信息
	let id: Int
	let name: String
	let agentType: String

	// 进度
	let progress: Double

	//  所属任务信息
	let taskId: UUID?
	let taskTitle: String

	//  目标任务信息
	let subtaskDescription: String
	let result: String
}

struct Niuma {
	// 完整的牛马数据
	let id: Int
	let name: String
	let agentType: String
	
	let progress: Double
	
	let taskId: UUID?
	let subtaskId: Int?
}

struct NiumaToPreviewInTask: Identifiable {
	let id: Int
	let name: String
	let agentType: String

	let progress: Double
}
