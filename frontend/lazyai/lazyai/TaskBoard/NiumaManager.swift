import SwiftUI

class NiumaManager: ObservableObject {
	@Published var niumas: [Niuma] = []

    init() {
        Task {
            guard let niumas = try await MyNetworkService.shared.getAllNiuma() else {
                return
            }
            self.niumas = niumas
        }
    }
    var niumasInHome: [NiumaInHome] {
        niumas.filter { $0.taskId?.uuidString == nil }.compactMap { niuma in
            NiumaInHome(id: niuma.id, name: niuma.name, agentType: niuma.agentType)
        }
    }

	func filterNiumasInTask(with taskId: UUID) -> [NiumaDetail] {
        // 过滤出处于该任务中的牛马们
		niumas.filter { $0.taskId?.uuidString == taskId.uuidString }.compactMap { niuma in
			NiumaDetail(id: niuma.id, name: niuma.name, agentType: niuma.agentType, progress: niuma.progress, taskId: niuma.taskId, taskTitle: niuma.taskTitle, subtaskDescription: niuma.subtaskDescription, result: niuma.result)
		}
	}
}

