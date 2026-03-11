// WeeklyGoal.swift
// Chalk — Derived Data Model
//
// Phase 1: Scaffold stub — struct shape defined, compute logic deferred to Phase 2.
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

// MARK: - Factory (Phase 2)

extension WeeklyGoal {

    // TODO: Phase 2 — Implement:
    //
    // /// Computes a WeeklyGoal for a category by counting matching entries in the current ISO week.
    // /// - Parameters:
    // ///   - category: The category to evaluate.
    // ///   - entries: All available WorkoutEntry records.
    // /// - Returns: A populated WeeklyGoal snapshot.
    // static func compute(for category: WorkoutCategory, from entries: [WorkoutEntry]) -> WeeklyGoal {
    //     let weekEntries = entries.filter { entry in
    //         entry.categoryId == category.id && Calendar.iso8601.isInCurrentISOWeek(entry.date)
    //     }
    //     return WeeklyGoal(category: category, completedCount: weekEntries.count)
    // }
}

// MARK: - Calendar ISO Week Helper (Phase 2)

extension Calendar {

    // TODO: Phase 2 — Expose a convenience `iso8601` static Calendar
    //   and an `isInCurrentISOWeek(_ date: Date) -> Bool` helper
    //   that computes the Monday–Sunday window for today.
}
