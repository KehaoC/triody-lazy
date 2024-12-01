import SwiftUI

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