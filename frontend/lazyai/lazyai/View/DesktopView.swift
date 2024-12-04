import SwiftUI

struct DesktopView: View {
    @ObservedObject var taskViewModel: TaskViewModel
    @ObservedObject var niumaAssigner: NiumaAssigner

    var body: some View {
        VStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(taskViewModel.tasks) { task in
                        TaskCard(task: task, taskViewModel: taskViewModel, niumaAssigner: niumaAssigner)
                    }
                }
                .padding()
            }
            Divider()
            NiumaHouseView()
        }
        .enableInjection()

    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}

