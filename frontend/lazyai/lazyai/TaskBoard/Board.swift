import SwiftUI

struct Board: View {
    var body: some View {
        VStack {
			TaskList()
            Divider()
			NiumaHouseView()
        }
        .enableInjection()

    }

    #if DEBUG
    @ObserveInjection var forceRedraw
    #endif
}


