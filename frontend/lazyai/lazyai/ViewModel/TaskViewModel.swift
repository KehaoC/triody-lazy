import SwiftUI

class TaskViewModel: ObservableObject {
    @Published var tasks: [TaskModel] = []

    func createTask(description: String) {
        
    }

}
