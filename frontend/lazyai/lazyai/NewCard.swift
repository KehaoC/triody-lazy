import SwiftUI

struct NewCard: View {

    @EnvironmentObject var taskManager: TaskManager
    @EnvironmentObject var userViewModel: UserViewModel

    // 卡片内容
    @State private var title: String = ""
    @State private var description: String = ""

    // 卡片状态
    @State private var isEditingTitle = false
    @State private var isEditingDescription = false

    // Toast 提示
    @State private var showToast = false
    @State private var toastInfo: String = ""

    // 卡片动画
    @State private var cardOpacity: Double = 1.0
    @State private var offset: CGSize = .zero // Use a single offset variable
    
    var body: some View {
        ZStack {
            card
            toastCard(with: toastInfo)
        }
        .enableInjection()
    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif

    var card: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 20)
            
            // Title Section
            VStack(alignment: isEditingTitle ? .leading : .center, spacing: 8) {
                Text("Title")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray.opacity(0.8))
                    .padding(.horizontal)
                
                if isEditingTitle {
                    TextField("Enter title", text: $title)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.1))
                        )
                        .padding(.horizontal)
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                } else {
                    Text(title.isEmpty ? "Got some problems today?" : title)
                        .font(.system(size: 18, weight: .semibold))
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                isEditingTitle = true
                            }
                        }
                }
            }
            
            // Description Section
            VStack(alignment: isEditingDescription ? .leading : .center, spacing: 8) {
                Text("Description")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray.opacity(0.8))
                    .padding(.horizontal)
                
                if isEditingDescription {
                    TextEditor(text: $description)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.1))
                                )
                        )
                        .frame(height: 100)
                        .padding(.horizontal)
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                } else {
                    Text(description.isEmpty ? "Add some details..." : description)
                        .font(.system(size: 16))
                        .foregroundColor(description.isEmpty ? .gray : .primary)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                isEditingDescription = true
                            }
                        }
                }
            }
            
            Spacer()
            
            // Drag Indicator
            VStack(spacing: 6) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.gray.opacity(0.6))
                    .offset(y: offset.height / 10) // 添加拖拽反馈
                
                Text("Drag up to send")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray.opacity(0.8))
            }
            .padding(.bottom, 20)
        }
        .frame(width: 300, height: 400)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.white)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .offset(x: offset.width, y: offset.height) // Apply the offset directly
        .opacity(cardOpacity)
        .gesture(
            DragGesture()
                .onChanged { value in
                    self.offset = value.translation // Update offset during drag
                }
                .onEnded { value in
                    if value.translation.height < -100 {
                        // 如果向上拖动超过 100 点，则认为用户想要发送给 AI


                        // 1. 先让卡片消失
                        withAnimation(.easeOut(duration: 0.5)) {
                            self.offset.height = -1000
                            cardOpacity = 0
                        }

                        // 2. 显示 Toast 提示
                        toastInfo = "Sent to Lazy, You just have to have a rest now."
                        showToast = true
                        print("create task: \(title)")
                        Task {
                            // 自动创建任务
                            try await taskManager.createTaskAuto(title: title, description: description)
                        }

                        // 3. 重置卡片状态并归位
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            title = ""
                            description = ""
                            isEditingTitle = false
                            isEditingDescription = false
                            self.offset.height = 1000  // 先挪到下面去

                            // 4. 让卡片重新出现
                            withAnimation(.spring(
                                response: 0.4,
                                dampingFraction: 0.5,
                                blendDuration: 0
                            )) {
                                self.offset = .zero
                                cardOpacity = 1
                            }
                        }

                        // 5. 1.5 秒后隐藏 Toast
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showToast = false
                        }
                    } else {
                        // 如果没有超过阈值，则归位
                        self.offset = .zero
                    }
                }
        )

    }

    var controlBar: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(.gray.opacity(0.9))
            .frame(width: 200, height: 8)
            .padding(.bottom, 20)
    }

    func toastCard(with info: String) -> some View {
        Text(info)
            .font(.system(size: 16, weight: .medium))
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.85))
                    .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
            )
            .foregroundColor(.white)
            .opacity(showToast ? 1 : 0)
            .scaleEffect(showToast ? 1 : 0.8)
            .blur(radius: showToast ? 0 : 4)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showToast)
            .offset(y: showToast ? -180 : -220)
    }
}