//
//  ContentView.swift
//  LazyAI
//
//  Created by ALcohol_可豪 on 2024/11/23.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var taskViewModel = TaskViewModel()

    var body: some View {
        NavigationView {
            TabView {
                DesktopView(taskViewModel: taskViewModel)
                    .tabItem {
                        Label("Desktop", systemImage: "desktopcomputer")
                        Text("Desktop")
                    }
                NewCardView(taskViewModel: taskViewModel)
                    .tabItem {
                        Label("New", systemImage: "plus")
                        Text("New")
                    }
                UserView()
                    .tabItem {
                        Label("User", systemImage: "person")
                        Text("User")
                    }
            }
        }
        .navigationTitle("LazyAI")
    }
}

#Preview {
    ContentView()
}
