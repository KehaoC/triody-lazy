//
//  ContentView.swift
//  LazyAI
//
//  Created by ALcohol_可豪 on 2024/11/23.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var taskViewModel = TaskViewModel()
	@StateObject private var niumaAssigner = NiumaAssigner()
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
				DesktopView(taskViewModel: taskViewModel, niumaAssigner: niumaAssigner)
                    .tabItem {
                        Label("Desktop", systemImage: "desktopcomputer")
                    }
                    .tag(0)
                NewCardView(taskViewModel: taskViewModel)
                    .tabItem {
                        Label("New", systemImage: "plus.circle.fill")
                    }
                    .tag(1)
                AuthView()
                    .tabItem {
                        Label("User", systemImage: "person.circle.fill")
                    }
                    .tag(2)
            }
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                // ... existing toolbar ...
            }
            .tint(.primary)
            .animation(.easeInOut, value: selectedTab)
        }
        .enableInjection()
    }


}

#Preview {
    ContentView()
}
