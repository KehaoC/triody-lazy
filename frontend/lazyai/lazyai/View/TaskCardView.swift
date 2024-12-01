import SwiftUI
struct TaskCard: View {
    let task: TaskModel
    @State private var isExpanded = true
    @ObservedObject var taskViewModel: TaskViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(task.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                statusLabel(isFinished: task.isFinished)
            }

            if let description = task.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if isExpanded {
                Divider()
                expendedSubtaskList(subtasks: task.subtasks ?? [])
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .onTapGesture {
            isExpanded.toggle()
        }
    }



    func expendedSubtaskList(subtasks: [Subtask]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            HStack{
                Text("Subtasks")
                    .font(.headline)
            Spacer()
            Text("\(task.subtasks?.count ?? 0) Subtasks detected")
                .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            // subtask list
            if let subtasks = task.subtasks, subtasks.isEmpty {
                Text("No subtasks detected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(subtasks) { subtask in
                    SubtaskRow(subtask: subtask)
                }
            }

        }
        .padding()
        .background(Color(.systemBackground))
        .enableInjection()
    }

    func statusLabel(isFinished: Bool) -> some View {
        Text(isFinished ? "Finished" : "Not Finished")
            .font(.subheadline)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(isFinished ? .green : .red)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isFinished ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
            )
    }
    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif  
}

struct SubtaskRow: View {
    let subtask: Subtask
    var body: some View {
        HStack{
            Text(subtask.description)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .opacity(subtask.isLazied ? 1.0 : 0.5)
            
            Spacer()
            isLaziedIcon(isLazied: subtask.isLazied)
        }
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.green.opacity(subtask.isLazied ? 0.3 : 0))
        )
        .onTapGesture {
            if subtask.isLazied {
                print("Tapped subtask: \(subtask.description)")
            }
        }
        .animation(.easeInOut, value: subtask.isLazied)
        .scaleEffect(subtask.isLazied ? 1.02 : 1.0)
    }

    func isLaziedIcon(isLazied: Bool) -> some View {
        Image(systemName: isLazied ? "checkmark.circle.fill" : "circle")
            .foregroundStyle(isLazied ? .green : .gray.opacity(0.3))
            .font(.system(size: 20))
            .symbolEffect(.bounce, value: isLazied)
    }
}
