import SwiftUI
struct TaskCard: View {
    let task: TaskModel
    @State private var showDetail = false
    @ObservedObject var taskViewModel: TaskViewModel
    @State private var showDeleteAlert = false
    @State private var isLongPressed = false

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(task.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    statusLabel(isFinished: task.isFinished)
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
            .animation(.easeInOut(duration: 0.2), value: isLongPressed)
            .gesture(
                LongPressGesture(minimumDuration: 0.5)
                    .onChanged { _ in
                        isLongPressed = true
                    }
                    .onEnded { _ in
                        isLongPressed = false
                        showDeleteAlert = true
                    }
            )
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showDetail.toggle()
                }
            }
            
            if showDetail {
                DetailCardView(task: task, taskViewModel: taskViewModel, isShowing: $showDetail)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.9).combined(with: .opacity),
                        removal: .scale(scale: 0.9).combined(with: .opacity)
                    ))
                    .shadow(color: .black.opacity(0.2), radius: 10)
            }
        }
        .alert("Delete Task", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await taskViewModel.deleteTask(taskId: task.id!)
                    } catch {
                        print("Error deleting task: \(error)")
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this task?")
        }
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
            .onTapGesture {
                Task {
                    do {
                        try await taskViewModel.modifyTaskStatus(taskId: task.id!, isFinished: !task.isFinished)
                    } catch {
                        print("Error modifying task status: \(error)")
                    }
                }
            }
    }
    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif  
}

struct DetailCardView: View {
    let task: TaskModel
    @ObservedObject var taskViewModel: TaskViewModel
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text(task.title)
                    .font(.title2.bold())
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isShowing = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.gray)
                        .font(.title2)
                }
            }
            
            // Task Description
            if !task.description.isEmpty {
                Text(task.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            
            // Updated Subtasks Section
            if let subtasks = task.subtasks, !subtasks.isEmpty {
                Divider()
                
                Text("Subtasks")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                VStack(spacing: 8) {
                    ForEach(subtasks) { subtask in
                        ExpandableSubtaskRow(subtask: subtask)
                    }
                }
            } else {
                Divider()
                Text("No subtasks yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        .padding(.horizontal, 20)
        .padding(.vertical, 60)
        .rotation3DEffect(.degrees(5), axis: (x: 1, y: 0, z: 0))
    }
}

struct ExpandableSubtaskRow: View {
    let subtask: Subtask
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(subtask.description)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .opacity(subtask.isLazied ? 1.0 : 0.5)
                
                Spacer()
                
                isLaziedIcon(isLazied: subtask.isLazied)
                
                Image(systemName: "chevron.right")
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .foregroundStyle(.gray)
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Agent: \(subtask.agentName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let result = subtask.result {
                        Text("Result:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(result)
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .padding(.leading, 8)
                    }
                }
                .padding(.leading)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.green.opacity(subtask.isLazied ? 0.3 : 0))
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }
        .animation(.easeInOut, value: subtask.isLazied)
    }
    
    func isLaziedIcon(isLazied: Bool) -> some View {
        Image(systemName: isLazied ? "checkmark.circle.fill" : "circle")
            .foregroundStyle(isLazied ? .green : .gray.opacity(0.3))
            .font(.system(size: 20))
            .symbolEffect(.bounce, value: isLazied)
    }
}