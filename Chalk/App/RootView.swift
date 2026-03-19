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

    private struct TabItem {
        let tab: Tab
        let icon: String
        let activeIcon: String
        let label: String
    }

    private let items: [TabItem] = [
        TabItem(tab: .home,    icon: "bolt.house",  activeIcon: "bolt.house.fill", label: "Home"),
        TabItem(tab: .history, icon: "calendar",    activeIcon: "calendar",        label: "History"),
        TabItem(tab: .profile, icon: "person",      activeIcon: "person.fill",     label: "Profile"),
    ]

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(items, id: \.label) { item in
                tabButton(item)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background { tabBarBackground }
    }

    @ViewBuilder
    private var tabBarBackground: some View {
        if #available(iOS 26, *) {
            Rectangle()
                .fill(.clear)
                .glassEffect()
                .ignoresSafeArea(edges: .bottom)
        } else {
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
    private func tabButton(_ item: TabItem) -> some View {
        let active = selectedTab == item.tab
        Button {
            selectedTab = item.tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: active ? item.activeIcon : item.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(active ? Color(hex: "#135bec") : Color.secondary)
                Text(item.label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(active ? Color(hex: "#135bec") : Color.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background { if active { activePill } }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var activePill: some View {
        if #available(iOS 26, *) {
            Capsule()
                .fill(.clear)
                .glassEffect(in: Capsule())
        } else {
            Capsule()
                .fill(.regularMaterial)
        }
    }
}
