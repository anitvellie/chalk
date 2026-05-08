// ProfileView.swift
// Chalk — Profile Tab
//
// Shows configured goals and HealthKit permission status.
// Goal editing will be wired up when the goal creation flow is complete.

import SwiftUI

struct ProfileView: View {

    @EnvironmentObject var appState: AppState
    @State private var showGoalSetup = false

    var body: some View {
        NavigationStack {
            List {
                // ── Configured goals ──
                Section("Your Goals") {
                    if appState.categories.isEmpty {
                        Text("No goals configured")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(appState.categories) { category in
                            categoryRow(category)
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { appState.deleteCategory(id: appState.categories[$0].id) }
                        }
                    }
                }

                // ── Developer ──
                #if DEBUG
                Section("Developer") {
                    NavigationLink(destination: MockDataView()) {
                        Label {
                            HStack {
                                Text("Mock Data")
                                if appState.isMockActive {
                                    Spacer()
                                    Text("Active")
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(.orange)
                                }
                            }
                        } icon: {
                            Image(systemName: "flask.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                }
                #endif

                // ── Permissions ──
                Section("Permissions") {
                    HStack {
                        Label("HealthKit", systemImage: "heart.fill")
                            .foregroundStyle(.red)
                        Spacer()
                        Text(appState.healthKitAuthorized ? "Authorized" : "Not authorized")
                            .font(.subheadline)
                            .foregroundStyle(appState.healthKitAuthorized ? .green : .secondary)
                    }
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Edit") { showGoalSetup = true }
                }
            }
        }
        .sheet(isPresented: $showGoalSetup) {
            GoalSetupView(mode: .profile)
                .environmentObject(appState)
        }
    }

    @ViewBuilder
    private func categoryRow(_ category: WorkoutCategory) -> some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(category.displayColor)
                .frame(width: 32, height: 32)
                .background(category.displayColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.body.weight(.medium))
                Text("\(category.targetPerWeek)× per week")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
