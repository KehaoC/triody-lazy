import SwiftUI

class NiumaAssigner: ObservableObject {
	@Published var niumas: [NiumaModel] = []

    init() {
        // mock data
        niumas = mockniumas
    }

    func assignNiuma(niumaId: Int, to taskId: Int) {
        if let index = niumas.firstIndex(where: { $0.id == niumaId }) {
            niumas[index].taskId = taskId
            // TODO: 可能需要添加进度初始化等其他逻辑

            niumas[index].progress = 0.0
        }
    }

	func filterNiumas(with taskId: Int) -> [NiumaModel] {
		return niumas.filter { $0.taskId == taskId }
	}
}


var mockniumas: [NiumaModel] = [
    NiumaModel(
        id: 1, 
        name: "Searcher", 
        avatar: "magnifyingglass", 
        description: "Searcher is a niuma that can search the internet for information.",
        taskId: 1,
        progress: 0.5
    ),
    NiumaModel(
        id: 2, 
        name: "Writer", 
        avatar: "pencil", 
        description: "Writer is a niuma that can write articles.",
        taskId: 2,
        progress: 1
    ),
    NiumaModel(
        id: 3, 
        name: "Coder", 
        avatar: "hammer", 
        description: "Coder is a niuma that can code.",
        taskId: 2,
        progress: 0.5
    ),
    NiumaModel(
        id: 4, 
        name: "Searcher", 
        avatar: "magnifyingglass", 
        description: "Searcher is a niuma that can search the internet for information.",
        taskId: nil,
        progress: 0
    ),
]
