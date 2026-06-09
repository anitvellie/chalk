// AppState.swift
// Chalk — Central Observable App State

import SwiftUI
import Combine
import WidgetKit

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

    /// Entries fetched for all known library types, used by WeeklyActivityStrip.
    /// Shows workouts in the strip even when they don't match a configured goal.
    @Published var stripEntries: [WorkoutEntry] = []

    /// Weekly goal snapshots for the current ISO week, one per category.
    @Published var weeklyGoals: [WeeklyGoal] = []

    /// Whether the user has granted HealthKit read permissions.
    @Published var healthKitAuthorized: Bool = false

    /// `true` while an async data-loading operation is in flight.
    @Published var isLoading: Bool = false

    /// Non-nil when a recoverable error should be surfaced to the user.
    @Published var errorMessage: String? = nil

    /// Timestamp of the last successful HealthKit sync. Nil before the first fetch.
    @Published var lastRefreshed: Date? = nil

    /// `true` once the user has completed the first-launch onboarding flow.
    @Published var hasCompletedOnboarding: Bool

    /// Persisted user preferences controlling duration thresholds and exclusions.
    @Published var preferences: UserPreferences = UserPreferences()

    #if DEBUG
    /// Whether mock data is currently overriding live HealthKit data.
    @Published var isMockActive: Bool = false
    #endif

    // MARK: - Dependencies

    private let healthKitManager = HealthKitManager()

    // MARK: - Init

    init() {
        #if DEBUG
        let forced = UserDefaults.standard.bool(forKey: "debug.forceOnboarding")
        hasCompletedOnboarding = forced ? false : UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        #else
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        #endif
        loadCategories()
        loadPreferences()
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
            healthKitManager.enableBackgroundDelivery { [weak self] in
                Task { @MainActor [weak self] in
                    await self?.refreshGoals()
                }
            }
            await refreshGoals()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Data Refresh

    /// Re-fetches weekly goal counts and entries from HealthKit for the current ISO week,
    /// then applies user preference filters (duration thresholds + excluded types).
    ///
    /// Safe to call from a pull-to-refresh control or after changing a category or preference.
    func refreshGoals() async {
        #if DEBUG
        guard !isMockActive else { return }
        #endif
        guard healthKitAuthorized else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let rawGoalEntries = try await healthKitManager.fetchCurrentWeekEntries(for: categories)
            let filteredGoalEntries = filterEntries(rawGoalEntries, using: categories)
            weeklyGoals = categories.map {
                WeeklyGoal.compute(for: $0, from: filteredGoalEntries.filter { !$0.isHidden })
            }
            entries = filteredGoalEntries

            let rawStripEntries = try await healthKitManager.fetchCurrentWeekEntries(for: HealthKitManager.categoryLibrary)
            stripEntries = filterEntries(rawStripEntries, using: HealthKitManager.categoryLibrary)

            errorMessage = nil
            lastRefreshed = Date()
            let snapshot = buildWidgetSnapshot()
            saveWidgetSnapshot(snapshot)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Preference Filtering

    /// Applies duration thresholds and type exclusions to a set of entries.
    ///
    /// - Parameters:
    ///   - entries: Raw entries returned from HealthKit.
    ///   - categorySource: The category array whose IDs the entries reference
    ///     (`categories` for goal entries, `HealthKitManager.categoryLibrary` for strip entries).
    private func filterEntries(_ entries: [WorkoutEntry], using categorySource: [WorkoutCategory]) -> [WorkoutEntry] {
        let categoryMap = Dictionary(uniqueKeysWithValues: categorySource.map { ($0.id, $0) })
        let walkingRaw = HealthKitManager.walkingActivityTypeRawValue

        return entries.filter { entry in
            let rawValues = categoryMap[entry.categoryId]?.activityTypeRawValues ?? []

            // Drop excluded activity types
            if rawValues.contains(where: { preferences.excludedActivityTypeRawValues.contains($0) }) {
                return false
            }

            // Walking uses its own threshold; everything else uses the global one
            let isWalking = rawValues.contains(walkingRaw)
            let thresholdSeconds = TimeInterval(
                (isWalking ? preferences.minWalkingDurationMinutes : preferences.minWorkoutDurationMinutes) * 60
            )
            return entry.duration >= thresholdSeconds
        }
    }

    // MARK: - Mock Data (DEBUG only)

    #if DEBUG
    /// Replaces live HealthKit data with synthetic entries and recomputes goals.
    func applyMock(entries: [WorkoutEntry]) {
        isMockActive = true
        self.entries = entries
        weeklyGoals = categories.map { WeeklyGoal.compute(for: $0, from: entries) }
    }

    /// Clears mock data and restores live HealthKit data (or zero-counts on Simulator).
    func clearMock() async {
        isMockActive = false
        entries = []
        if healthKitAuthorized {
            await refreshGoals()
        } else {
            weeklyGoals = categories.map { WeeklyGoal(category: $0, completedCount: 0) }
        }
    }
    #endif

    // MARK: - Widget Snapshot

    private func buildWidgetSnapshot() -> WidgetSnapshot {
        let goalSnapshots = weeklyGoals.map { goal in
            GoalSnapshot(
                id: goal.category.id,
                name: goal.category.name,
                icon: goal.category.icon,
                completed: goal.completedCount,
                target: goal.targetCount
            )
        }

        // Same week-start logic as WeeklyActivityStrip so the widget strip is always in sync.
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today)
        let daysFromStart = (weekday - cal.firstWeekday + 7) % 7
        guard let weekStart = cal.date(byAdding: .day, value: -daysFromStart, to: today) else {
            return WidgetSnapshot(goals: goalSnapshots, weekDays: [], lastRefreshed: Date())
        }
        let weekDates = (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: weekStart) }

        let categoryMap = Dictionary(uniqueKeysWithValues: HealthKitManager.categoryLibrary.map { ($0.id, $0) })
        // Sort longest-first so workoutIcons[0] is the most prominent workout of that day.
        var iconsByDay: [Date: [String]] = [:]
        for entry in stripEntries.filter({ !$0.isHidden }).sorted(by: { $0.duration > $1.duration }) {
            guard let cat = categoryMap[entry.categoryId] else { continue }
            let day = cal.startOfDay(for: entry.date)
            iconsByDay[day, default: []].append(cat.icon)
        }

        let daySnapshots = weekDates.map { day -> DaySnapshot in
            let icons = iconsByDay[day] ?? []
            var seen = Set<String>()
            let unique = icons.filter { seen.insert($0).inserted }
            return DaySnapshot(date: day, workoutIcons: unique)
        }

        return WidgetSnapshot(goals: goalSnapshots, weekDays: daySnapshots, lastRefreshed: Date())
    }

    private func saveWidgetSnapshot(_ snapshot: WidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        let store = SharedConstants.sharedDefaults ?? UserDefaults.standard
        store.set(data, forKey: SharedConstants.UserDefaultsKey.widgetSnapshot)
    }

    // MARK: - Persistence (categories)

    /// Loads categories from the shared App Group UserDefaults.
    /// Falls back to `UserDefaults.standard` if the App Group is not yet configured.
    /// Seeds from `HealthKitManager.defaultCategories` on first launch.
    private func loadCategories() {
        let store = SharedConstants.sharedDefaults ?? UserDefaults.standard
        if let data = store.data(forKey: SharedConstants.UserDefaultsKey.categories),
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
            store.set(data, forKey: SharedConstants.UserDefaultsKey.categories)
        }
    }

    // MARK: - Persistence (preferences)

    private func loadPreferences() {
        let store = SharedConstants.sharedDefaults ?? UserDefaults.standard
        if let data = store.data(forKey: SharedConstants.UserDefaultsKey.preferences),
           let saved = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            preferences = saved
        }
    }

    func savePreferences() {
        let store = SharedConstants.sharedDefaults ?? UserDefaults.standard
        if let data = try? JSONEncoder().encode(preferences) {
            store.set(data, forKey: SharedConstants.UserDefaultsKey.preferences)
        }
    }

    // MARK: - Preference Mutations

    func setMinWorkoutDuration(_ minutes: Int) {
        preferences.minWorkoutDurationMinutes = minutes
        savePreferences()
    }

    func setMinWalkingDuration(_ minutes: Int) {
        preferences.minWalkingDurationMinutes = minutes
        savePreferences()
    }

    /// Adds raw values to the exclusion set, removes any conflicting goals, and refreshes.
    func excludeActivityType(_ rawValues: [Int]) {
        let rawSet = Set(rawValues)
        categories.removeAll { $0.activityTypeRawValues.contains(where: { rawSet.contains($0) }) }
        weeklyGoals.removeAll { $0.category.activityTypeRawValues.contains(where: { rawSet.contains($0) }) }
        preferences.excludedActivityTypeRawValues.formUnion(rawValues)
        saveCategories()
        savePreferences()
        Task { await refreshGoals() }
    }

    /// Removes raw values from the exclusion set and refreshes.
    func includeActivityType(_ rawValues: [Int]) {
        preferences.excludedActivityTypeRawValues.subtract(rawValues)
        savePreferences()
        Task { await refreshGoals() }
    }

    // MARK: - Onboarding

    func completeOnboarding() {
        hasCompletedOnboarding = true
        #if DEBUG
        guard !UserDefaults.standard.bool(forKey: "debug.forceOnboarding") else { return }
        #endif
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
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
