// WidgetSnapshot.swift
// Chalk — Shared Layer (App → Widget data bridge)

import Foundation

struct GoalSnapshot: Codable, Identifiable {
    let id: UUID
    let name: String
    let icon: String        // SF Symbol base name (e.g. "figure.run")
    let completed: Int
    let target: Int

    var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(completed) / Double(target), 1.0)
    }
}

struct DaySnapshot: Codable {
    let date: Date              // Start of day; used for day letter, date number, and past/today/future logic
    let workoutIcons: [String]  // SF Symbol base names, longest-duration first, deduplicated by category
}

struct WidgetSnapshot: Codable {
    let goals: [GoalSnapshot]   // User's configured goals (all; widget logic applies its own prefix cap)
    let weekDays: [DaySnapshot] // Always 7 entries covering the current locale week
    let lastRefreshed: Date
}

extension WidgetSnapshot {
    static let placeholder = WidgetSnapshot(
        goals: [
            GoalSnapshot(id: UUID(), name: "Running",  icon: "figure.run",                           completed: 2, target: 3),
            GoalSnapshot(id: UUID(), name: "Strength", icon: "figure.strengthtraining.traditional",  completed: 3, target: 4),
        ],
        weekDays: [],
        lastRefreshed: Date()
    )
}
