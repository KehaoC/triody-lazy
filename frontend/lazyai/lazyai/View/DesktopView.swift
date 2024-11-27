import SwiftUI

struct DesktopView: View {
    @ObservedObject var taskViewModel: TaskViewModel

    var body: some View {
        VStack {
            List(taskViewModel.tasks) { task in
                TaskCard(task: task)
            }
        }
    }
}

struct TaskCard: View {
    // Given by parent view
    let task: TaskModel

    var body: some View {
        VStack (alignment: .leading, spacing: 12) {
            // Title
            HStack {
                Text(task.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                // TaskStatus
                StatusLabel(isFinished: task.isFinished)
            }

            if !task.description.isEmpty {
                Text(task.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }
}

struct StatusLabel: View {
    let isFinished: Bool

    var body: some View {
        Text(isFinished ? "Finished" : "Unfinished")
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(isFinished ? .green.opacity(0.2) : .red.opacity(0.2))
            .foregroundColor(isFinished ? .green : .red)
            .cornerRadius(8)
    }
}
