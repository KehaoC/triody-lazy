import SwiftUI

struct TaskCard: View {
    let task: TaskToPreview
    let taskDetailId: Int?

    // 用于获取新任务
    @EnvironmentObject var taskManager: TaskManager
    @EnvironmentObject var niumaManager: NiumaManager

    @State private var showDetailCard = false
    @State private var showDeleteAlert = false
    @State private var isLongPressed = false

    var body: some View {
        ZStack {
            if !showDetailCard {
                // 简略任务卡, 在主页面上显示的简略形式
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        taskTitle
                        Spacer()
                        statusLabel(isFinished: task.isFinished)
                    }

                    // 任务描述
                    if !task.description.isEmpty {
                        taskDescription
                    }

                    // 任务进度
                    HStack {
                        // 处于该任务中的牛马们, 这里是简略形式
                        ForEach(niumaManager.filterNiumasInTask(with: task.id), id: \.id) { niuma in
                            // 点击后显示牛马的详细信息
                            NiumaInTaskCard(niuma: niuma)
                        }
                    }
                    niumaDropArea
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                .gesture(
                    // 长按删除
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
                    // 点击显示详细任务卡
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        Task {
                            try await taskManager.getTaskDetail(taskId: task.id)
                        }
                        showDetailCard.toggle()
                    }
                }
            } else {
                // 详细任务卡
                DetailCard(task: taskManager.taskDetailWith(taskId: taskDetailId)!, isShowing: $showDetailCard)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.9).combined(with: .opacity),
                        removal: .scale(scale: 0.9).combined(with: .opacity)
                    ))
                    .shadow(color: .black.opacity(0.2), radius: 10)
            }
            
        }
        .alert("Delete Task", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                // 删除任务
                Task {
                    do {
                        try await taskManager.deleteTask(taskId: task.id)
                    } catch {
                        print("Error deleting task: \(error)")
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this task?")
        }
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif

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
                // 点击修改任务状态
                Task {
                    do {
                        try await taskManager.modifyTaskStatus(taskId: task.id, isFinished: !task.isFinished)
                    } catch {
                        print("Error modifying task status: \(error)")
                    }
                }
            }
    }

    func niumaInShort(niuma: NiumaToPreviewInTask) -> some View {
        // 在简略卡片列表中展现的，只有基本描述和进度
        VStack {
            Text(niuma.name)
                .font(.subheadline)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .foregroundStyle(.primary)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.2))
                )
            ProgressView(value: niuma.progress)
        }
        .onTapGesture {

        }
    }

    var taskTitle: some View {
        Text(task.title)
            .font(.headline)
            .foregroundStyle(.primary)
    }

    var taskDescription: some View {
        Text(task.description)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(2)
    }

    var niumaDropArea: some View {
		RoundedRectangle(cornerRadius: 12)
			.fill(.gray.opacity(0.1))
			.frame(height: 44)
			.overlay(
				Text("Drop here")
					.foregroundColor(.gray)
			)
	}
}

struct DetailCard: View {
    // 展示额外信息
    // 子任务描述，子任务进度，子任务分配的牛马
    var task: TaskDetail
    @Binding var isShowing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text(task.title)
                    .font(.title2.bold())
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        // 点击关闭详细任务卡
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
            
            // TODO: 什么时候获取详细的子任务信息？
            if let subtasks = task.subtasksInTaskDetail, !subtasks.isEmpty {
                Divider()
                
                Text("Subtasks")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                VStack(spacing: 8) {
                    if let subtasks = task.subtasksInTaskDetail {
                        ForEach(subtasks, id: \.id) { subtask in
                            // 子任务描述，子任务进度，子任务分配的牛马
                            Text(subtask.description)
                        }
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
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}

