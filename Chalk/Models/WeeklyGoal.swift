// WeeklyGoal.swift
// Chalk — Derived Data Model
//
// WeeklyGoal is a *derived* type: it is never stored directly.
// It is computed from WorkoutEntry records filtered to the current ISO week
// (Monday–Sunday) and combined with the owning WorkoutCategory's target.

import Foundation

/// A snapshot of progress for a single `WorkoutCategory` in the current ISO week.
///
/// - Not persisted — always recomputed from `WorkoutEntry` records.
/// - Week boundary follows ISO 8601: Monday 00:00 → Sunday 23:59 local time.
struct WeeklyGoal: Identifiable {

    // MARK: - Properties

    /// Uses the category's own `id` as the goal identifier.
    var id: UUID { category.id }

    /// The workout category this goal tracks.
    let category: WorkoutCategory

    /// Number of completed workouts recorded in the current ISO week.
    var completedCount: Int

    // MARK: - Computed

    /// The weekly target (mirrors `category.targetPerWeek`).
    var targetCount: Int { category.targetPerWeek }

    /// `true` when the weekly target has been met or exceeded.
    var isComplete: Bool { completedCount >= targetCount }

    /// Completion ratio clamped to [0.0, 1.0]. Used for progress rings.
    var progress: Double {
        guard targetCount > 0 else { return 0 }
        return min(Double(completedCount) / Double(targetCount), 1.0)
    }

    /// Remaining workouts needed to hit the target this week (min 0).
    var remaining: Int {
        max(targetCount - completedCount, 0)
    }

    // MARK: - Init

    init(category: WorkoutCategory, completedCount: Int = 0) {
        self.category = category
        self.completedCount = completedCount
    }
}

// MARK: - Factory

extension WeeklyGoal {

    /// Computes a `WeeklyGoal` by counting entries that fall in the current ISO week.
    ///
    /// - Parameters:
    ///   - category: The category to evaluate.
    ///   - entries: All available `WorkoutEntry` records (superset is fine).
    /// - Returns: A populated `WeeklyGoal` snapshot for this week.
    static func compute(for category: WorkoutCategory, from entries: [WorkoutEntry]) -> WeeklyGoal {
        let calendar = Calendar.iso8601
        let now = Date()
        let count = entries.filter { entry in
            entry.categoryId == category.id &&
            calendar.isDate(entry.date, inSameISOWeekAs: now)
        }.count
        return WeeklyGoal(category: category, completedCount: count)
    }
}

// MARK: - Calendar ISO Week Helpers

extension Calendar {

    /// An ISO 8601 calendar where weeks run Monday–Sunday.
    static let iso8601 = Calendar(identifier: .iso8601)

    /// Returns `true` if `date` falls in the same ISO week as `referenceDate`.
    func isDate(_ date: Date, inSameISOWeekAs referenceDate: Date) -> Bool {
        let a = dateComponents([.weekOfYear, .yearForWeekOfYear], from: date)
        let b = dateComponents([.weekOfYear, .yearForWeekOfYear], from: referenceDate)
        return a.weekOfYear == b.weekOfYear && a.yearForWeekOfYear == b.yearForWeekOfYear
    }
}
