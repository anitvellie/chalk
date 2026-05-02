// RootView.swift
// Chalk — Navigation Shell

import SwiftUI

enum Tab: Hashable {
    case home, history, profile
}

struct RootView: View {

    @EnvironmentObject var appState: AppState
    @State private var selectedTab: Tab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("Home", systemImage: "bolt.house") }
                .tag(Tab.home)
            HistoryView()
                .tabItem { Label("History", systemImage: "calendar") }
                .tag(Tab.history)
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person") }
                .tag(Tab.profile)
        }
        .task {
            print("[Chalk] setupHealthKit called")
            await appState.setupHealthKit()
        }
    }
}
