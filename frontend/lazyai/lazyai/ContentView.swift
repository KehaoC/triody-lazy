//
//  ContentView.swift
//  LazyAI
//
//  Created by ALcohol_可豪 on 2024/11/23.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            TabView(selection: $selectedTab) {
				Board()
                    .tabItem {
                        Label("Board", systemImage: "desktopcomputer")
                    }
                    .tag(0)
                NewCard()
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
