// StatsView.swift
// Chalk — Stats Tab
//
// Shows this week's overall totals and a per-category breakdown
// with a ProgressView bar for each goal. Real data, generic presentation.

import SwiftUI

struct StatsView: View {

    @EnvironmentObject var appState: AppState

    private var totalCompleted: Int {
        appState.weeklyGoals.reduce(0) { $0 + $1.completedCount }
    }

    private var totalTarget: Int {
        appState.weeklyGoals.reduce(0) { $0 + $1.targetCount }
    }

    var body: some View {
        NavigationStack {
            List {
                // ── Weekly totals ──
                Section("This Week") {
                    HStack {
                        Label("Total Sessions", systemImage: "calendar.badge.checkmark")
                        Spacer()
                        Text("\(totalCompleted) / \(totalTarget)")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    if totalTarget > 0 {
                        ProgressView(value: Double(min(totalCompleted, totalTarget)),
                                     total: Double(totalTarget))
                            .tint(Color(hex: "#135bec"))
                    }
                }

                // ── Per-category breakdown ──
                Section("By Category") {
                    if appState.weeklyGoals.isEmpty {
                        Text("No data yet")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(appState.weeklyGoals) { goal in
                            categoryRow(goal)
                        }
                    }
                }
            }
            .navigationTitle("Stats")
            .overlay {
                if appState.isLoading && appState.weeklyGoals.isEmpty {
                    ProgressView()
                }
            }
        }
        .refreshable { await appState.refreshGoals() }
    }

    @ViewBuilder
    private func categoryRow(_ goal: WeeklyGoal) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: goal.category.icon)
                    .foregroundStyle(goal.category.displayColor)
                    .frame(width: 20)
                Text(goal.category.name)
                    .font(.body.weight(.medium))
                Spacer()
                Text("\(goal.completedCount) / \(goal.targetCount)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(goal.isComplete ? .green : .secondary)
            }
            ProgressView(value: goal.progress)
                .tint(goal.category.displayColor)
        }
        .padding(.vertical, 4)
    }
}
