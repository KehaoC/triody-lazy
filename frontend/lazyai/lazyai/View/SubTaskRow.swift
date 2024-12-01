import SwiftUI
struct SubTaskRow: View {
    let subtask: Subtask

    var body: some View {
        HStack {
            Text(subtask.description)
                .font(.subheadline)
                .foregroundStyle(.primary)
            
            Spacer()
            StatusLabel(isFinished: subtask.isLazied)
        }
        .padding(.vertical, 4)
        .enableInjection()
    }

}