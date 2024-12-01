import SwiftUI

struct DesktopView: View {
    @ObservedObject var taskViewModel: TaskViewModel

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(taskViewModel.tasks) { task in
                    TaskCard(task: task, taskViewModel: taskViewModel)
                }
            }
            .padding()
        }
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}





