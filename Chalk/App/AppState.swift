// AppState.swift
// Chalk — Central Observable App State

import SwiftUI
import Combine

/// Central observable state object injected into the SwiftUI environment.
/// Holds all top-level app data and drives the UI reactively.
@MainActor
final class AppState: ObservableObject {

    // MARK: - Published Properties

    /// User-defined workout categories (e.g. Strength, Running, Yoga).
    @Published var categories: [WorkoutCategory] = []

    /// All workout entries sourced from HealthKit or entered manually.
    /// Not persisted — always fetched fresh from HealthKit.
    @Published var entries: [WorkoutEntry] = []

    /// Weekly goal snapshots for the current ISO week, one per category.
    @Published var weeklyGoals: [WeeklyGoal] = []

    /// Whether the user has granted HealthKit read permissions.
    @Published var healthKitAuthorized: Bool = false

    /// `true` while an async data-loading operation is in flight.
    @Published var isLoading: Bool = false

    /// Non-nil when a recoverable error should be surfaced to the user.
    @Published var errorMessage: String? = nil

    // MARK: - Dependencies

    private let healthKitManager = HealthKitManager()

    // MARK: - Init

    init() {
        loadCategories()
    }

    // MARK: - HealthKit Setup

    /// Requests HealthKit authorisation and performs the initial goals fetch.
    ///
    /// Call this once from the root view's `.task` modifier.
    /// Safe to call multiple times — HealthKit's permission sheet only appears once.
    func setupHealthKit() async {
        guard HealthKitManager.isAvailable else {
            // Simulator or unsupported device — populate goals with 0 counts so the UI
            // renders correctly without real data.
            weeklyGoals = categories.map { WeeklyGoal(category: $0, completedCount: 0) }
            return
        }

        do {
            try await healthKitManager.requestAuthorization(for: categories)
            healthKitAuthorized = true
            await refreshGoals()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Data Refresh

    /// Re-fetches weekly goal counts and entries from HealthKit for the current ISO week.
    ///
    /// Safe to call from a pull-to-refresh control or after a new category is added.
    func refreshGoals() async {
        guard healthKitAuthorized else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            weeklyGoals = try await healthKitManager.fetchCurrentWeekGoals(for: categories)
            entries = try await healthKitManager.fetchCurrentWeekEntries(for: categories)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Persistence (categories only)

    /// Loads categories from the shared App Group UserDefaults.
    /// Falls back to `UserDefaults.standard` if the App Group is not yet configured.
    /// Seeds from `HealthKitManager.defaultCategories` on first launch.
    private func loadCategories() {
        let store = SharedConstants.sharedDefaults ?? UserDefaults.standard
        if let data = store.data(forKey: "categories"),
           let saved = try? JSONDecoder().decode([WorkoutCategory].self, from: data) {
            categories = saved
        } else {
            categories = HealthKitManager.defaultCategories
            saveCategories()
        }
    }

    /// Persists the current categories to the shared App Group UserDefaults.
    func saveCategories() {
        let store = SharedConstants.sharedDefaults ?? UserDefaults.standard
        if let data = try? JSONEncoder().encode(categories) {
            store.set(data, forKey: "categories")
        }
    }

    // MARK: - Category Management

    func addCategory(_ category: WorkoutCategory) {
        categories.append(category)
        saveCategories()
    }

    func deleteCategory(id: UUID) {
        categories.removeAll { $0.id == id }
        weeklyGoals.removeAll { $0.category.id == id }
        entries.removeAll { $0.categoryId == id }
        saveCategories()
    }

    func updateCategory(_ category: WorkoutCategory) {
        guard let index = categories.firstIndex(where: { $0.id == category.id }) else { return }
        categories[index] = category
        saveCategories()
    }
}
