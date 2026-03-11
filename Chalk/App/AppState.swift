// AppState.swift
// Chalk — Central Observable App State
//
// Phase 1: Scaffold stub — properties declared, no logic implemented.
// TODO: Phase 2 — Wire up HealthKitManager and persistence.
// TODO: Phase 3 — Drive UI from this state object.

import SwiftUI
import Combine

/// Central observable state object injected into the SwiftUI environment.
/// Holds all top-level app data and drives the UI reactively.
@MainActor
final class AppState: ObservableObject {

    // MARK: - Published Properties

    /// User-defined workout categories (e.g. Running, Yoga, Upper Body).
    @Published var categories: [WorkoutCategory] = []

    /// All workout entries sourced from HealthKit or entered manually.
    @Published var entries: [WorkoutEntry] = []

    /// Weekly goal snapshots derived from categories + entries for the current ISO week.
    @Published var weeklyGoals: [WeeklyGoal] = []

    /// Whether the user has granted HealthKit read permissions.
    @Published var healthKitAuthorized: Bool = false

    /// True while an async data-loading operation is in flight.
    @Published var isLoading: Bool = false

    /// Non-nil when a recoverable error should be surfaced to the user.
    @Published var errorMessage: String? = nil

    // MARK: - Dependencies

    // TODO: Phase 2 — Inject HealthKitManager here (as a property or via environment).

    // MARK: - Init

    init() {
        // TODO: Phase 2 — Request HealthKit authorisation on first launch.
        // TODO: Phase 2 — Load persisted categories from App Group UserDefaults.
        // TODO: Phase 3 — Seed WorkoutCategory.defaults during onboarding if no categories exist.
        // TODO: Phase 3 — Trigger initial HealthKit fetch after authorisation.
    }

    // MARK: - Intent Methods (Phase 3+)

    // TODO: Phase 3 — func addCategory(_ category: WorkoutCategory)
    // TODO: Phase 3 — func deleteCategory(id: UUID)
    // TODO: Phase 3 — func refreshGoals() async
}
