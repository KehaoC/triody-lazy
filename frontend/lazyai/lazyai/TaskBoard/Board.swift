import SwiftUI

struct Board: View {
    @EnvironmentObject var taskManager: TaskManager
    var body: some View {
        VStack {
			taskList
            Divider()
			NiumaHouseView()
        }
        .enableInjection()

    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif

    var taskList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(taskManager.taskList) { task in
                    // 主页上的任务卡, 不显示任务详情
                    TaskCard(task: task)
                }
            }
        }
    }
}


