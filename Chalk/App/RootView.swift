// RootView.swift
// Chalk — Navigation Shell
//
// Owns the bottom tab bar (Home | History | Profile).
// Each tab hosts its own NavigationStack.

import SwiftUI

// MARK: - Tab

enum Tab: Hashable {
    case home, history, profile
}

// MARK: - Root View

struct RootView: View {

    @EnvironmentObject var appState: AppState
    @State private var selectedTab: Tab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tag(Tab.home)
            HistoryView()
                .tag(Tab.history)
            ProfileView()
                .tag(Tab.profile)
        }
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CustomTabBar(selectedTab: $selectedTab)
        }
        .task {
            await appState.setupHealthKit()
        }
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {

    @Binding var selectedTab: Tab

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            tabButton(.home,    icon: "house",  label: "Home")
            tabButton(.history, icon: "clock",  label: "History")
            tabButton(.profile, icon: "person", label: "Profile")
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(Color(uiColor: .separator))
                        .frame(height: 0.5)
                }
        }
    }

    @ViewBuilder
    private func tabButton(_ tab: Tab, icon: String, label: String) -> some View {
        Button {
            selectedTab = tab
        } label: {
            let active = selectedTab == tab
            VStack(spacing: 4) {
                Image(systemName: active ? "\(icon).fill" : icon)
                    .font(.system(size: 22))
                    .foregroundStyle(active ? Color(hex: "#135bec") : Color.secondary)
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(active ? Color(hex: "#135bec") : Color.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
