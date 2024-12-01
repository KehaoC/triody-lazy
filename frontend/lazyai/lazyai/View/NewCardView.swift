import SwiftUI

struct NewCardView: View {
    @ObservedObject var taskViewModel: TaskViewModel
    @State private var title: String = "Test title"
    @State private var description: String = "Test description"
    @State private var isEditingTitle = false
    @State private var isEditingDescription = false
    @State private var showToast = false
    @State private var toastInfo: String = ""
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
            VStack(alignment: .leading, spacing: 8) {
                Text("Title")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                if isEditingTitle {
                    TextField("Enter title", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                } else {
                    Text(title.isEmpty ? "Got some problems today?" : title)
                        .font(.headline)
                        .padding(.horizontal)
                        .onTapGesture {
                            withAnimation {
                                isEditingTitle = true
                            }
                        }
                }
            }
            
            // Description Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                
                if isEditingDescription {
                    TextEditor(text: $description)
                        .frame(height: 100)
                        .padding(4)
                        .background(RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2)))
                        .padding(.horizontal)
                } else {
                    Text(description.isEmpty ? "Add some details..." : description)
                        .font(.body)
                        .padding(.horizontal)
                        .onTapGesture {
                            withAnimation {
                                isEditingDescription = true
                            }
                        }
                }
            }
            
            Spacer()
            
            Text("Drag to the top to send to AI")
                .font(.caption)
                .foregroundColor(.gray)
            
            controlBar
        }
        .frame(width: 300, height: 400)
        .background(.white)
        .cornerRadius(20)
        .shadow(radius: 10)
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
                            try await taskViewModel.createTask(title: title, description: description)
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
        .onTapGesture {
            // Remove this since we now have separate tap gestures
        }
    }

    var controlBar: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(.gray.opacity(0.9))
            .frame(width: 200, height: 8)
            .padding(.bottom, 20)
    }

    func toastCard(with info: String)->some View {
        Text(info)
            .font(.system(size: 16, weight: .medium))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.75))
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            )
            .foregroundColor(.white)
            .opacity(showToast ? 1 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showToast) // 增加 response 时间使动画变慢
            .offset(y: showToast ? -150 : -200)
            .blur(radius: showToast ? 0 : 2)
    }
}

#Preview {
    NewCardView(taskViewModel: TaskViewModel())
}
