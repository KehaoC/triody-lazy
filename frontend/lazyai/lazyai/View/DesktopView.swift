import SwiftUI

struct DesktopView: View {
    @ObservedObject var taskViewModel: TaskViewModel

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 32) {
                ForEach(taskViewModel.tasks) { task in
                    TaskCard(task: task)
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

struct TaskCard: View {
    let task: TaskModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(task.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                StatusLabel(isFinished: task.isFinished)
            }

            if !task.description.isEmpty {
                Text(task.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}

struct StatusLabel: View {
    let isFinished: Bool

    var body: some View {
        Text(isFinished ? "Finished" : "Unfinished")
            .font(.caption.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isFinished ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
            .foregroundColor(isFinished ? .green : .red)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}
