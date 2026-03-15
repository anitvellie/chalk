// RootView.swift
// Chalk — Phase 3 Navigation Shell
//
// Replaces the Phase 2 ContentView. Owns the bottom tab bar and the
// floating Add button. Each tab hosts its own NavigationStack.

import SwiftUI

// MARK: - Tab

enum Tab: Hashable {
    case home, stats, history, profile
}

// MARK: - Root View

struct RootView: View {

    @EnvironmentObject var appState: AppState
    @State private var selectedTab: Tab = .home
    @State private var showingAddGoal = false

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tag(Tab.home)
            StatsView()
                .tag(Tab.stats)
            HistoryView()
                .tag(Tab.history)
            ProfileView()
                .tag(Tab.profile)
        }
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CustomTabBar(selectedTab: $selectedTab, onAdd: { showingAddGoal = true })
        }
        .sheet(isPresented: $showingAddGoal) {
            // TODO: Phase 3 — Goal creation flow
            VStack(spacing: 16) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(Color(hex: "#135bec"))
                Text("Add Goal")
                    .font(.title2.bold())
                Text("Goal creation coming soon.")
                    .foregroundStyle(.secondary)
            }
            .presentationDetents([.medium])
        }
        .task {
            await appState.setupHealthKit()
        }
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {

    @Binding var selectedTab: Tab
    let onAdd: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            tabButton(.home,    icon: "house",     label: "Home")
            tabButton(.stats,   icon: "chart.bar", label: "Stats")

            // Floating Add button — offset upward to straddle the tab bar top edge
            Button(action: onAdd) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#135bec"))
                        .frame(width: 56, height: 56)
                        .shadow(color: Color(hex: "#135bec").opacity(0.4), radius: 12, x: 0, y: 4)
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .offset(y: -16)

            tabButton(.history, icon: "clock",    label: "History")
            tabButton(.profile, icon: "person",   label: "Profile")
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
