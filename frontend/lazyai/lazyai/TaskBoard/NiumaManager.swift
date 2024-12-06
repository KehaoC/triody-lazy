import SwiftUI

class NiumaManager: ObservableObject {
	@Published var niumas: [Niuma] = []
	@Published var niumaDetails: [NiumaDetail] = []
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
            async let niumasList = NetworkService.shared.getAllNiuma()
            // async let detailsList = NetworkService.shared.getAllNiumaDetails()
            
            let niumas = try await niumasList
            // let details = try await detailsList
            
            await MainActor.run {
                if let niumas = niumas {
                    self.niumas = niumas
                }
                // self.niumaDetails = details
                self.isLoading = false
            }
        } catch {
            print("Failed to load initial niuma data: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }

	var niumasInHome: [NiumaInHome] {
        niumas.filter { $0.taskId == nil }.compactMap { niuma in
            NiumaInHome(id: niuma.id, name: niuma.name, agentType: niuma.agentType)
        }
    }

	func filterNiumasInTask(with taskId: Int?) -> [NiumaDetail] {
        // 过滤出处于该任务中的牛马们, 并返回它们的简略信息
		niumas.filter { $0.taskId == taskId }.compactMap { niuma in
            NiumaDetail(id: niuma.id, name: niuma.name, agentType: niuma.agentType, progress: niuma.progress, taskId: niuma.taskId, taskTitle: "", subtaskDescription: "", result: "")
		}
	}

    func getInitialNiumas() async throws {
        // 用户在一开始没有任何牛马的时候，需要创建一些基础的牛马
        do {
            let newNiumas = try await NetworkService.shared.createBasicNiuma()
            niumas.append(contentsOf: newNiumas)
            print("getInitialNiumas success")
        } catch {
            print("getInitialNiumas error: \(error)")
        }
    }

    func getNiumaDetail(niumaId: Int) async throws -> NiumaDetail? {
        try await NetworkService.shared.getNiumaDetail(niumaId: niumaId)
    }

    func assignNiumaToTask(niumaId: Int, taskId: Int) async throws {
        try await NetworkService.shared.assignNiumaToTask(niumaId: niumaId, taskId: taskId)
    }

    func removeNiumaFromTask(niumaId: Int) async throws {
        try await NetworkService.shared.removeNiumaFromTask(niumaId: niumaId)
    }
}

