// HealthKitManager.swift
// Chalk — HealthKit Integration Layer
//
// Read-only. This is the sole file in the project that imports HealthKit.
// All other layers (Models, Shared, Widget) remain HK-free.

import Foundation
import HealthKit

/// Manages all read-only interaction with Apple HealthKit.
@MainActor
final class HealthKitManager: ObservableObject {

    // MARK: - Properties

    private let healthStore = HKHealthStore()

    /// `true` if HealthKit is supported on this device.
    /// Always `false` on Simulator; always `true` on iPhone.
    static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    // MARK: - Default Categories (HK-aware seed data)

    /// Default `WorkoutCategory` values with `activityTypeRawValues` correctly
    /// populated from `HKWorkoutActivityType` enum cases.
    ///
    /// Use this (not `WorkoutCategory.defaults`) when seeding storage on first launch,
    /// so raw values are always resolved from the enum — never hardcoded.
    static var defaultCategories: [WorkoutCategory] {
        [
            WorkoutCategory(
                name: "Strength",
                icon: "figure.strengthtraining.traditional",
                colorHex: "#135bec",
                targetPerWeek: 4,
                activityTypeRawValues: [
                    Int(HKWorkoutActivityType.traditionalStrengthTraining.rawValue),
                    Int(HKWorkoutActivityType.functionalStrengthTraining.rawValue)
                ]
            ),
            WorkoutCategory(
                name: "Running",
                icon: "figure.run",
                colorHex: "#ff9500",
                targetPerWeek: 3,
                activityTypeRawValues: [
                    Int(HKWorkoutActivityType.running.rawValue)
                ]
            ),
            WorkoutCategory(
                name: "Yoga",
                icon: "figure.yoga",
                colorHex: "#af52de",
                targetPerWeek: 1,
                activityTypeRawValues: [
                    Int(HKWorkoutActivityType.yoga.rawValue),
                    Int(HKWorkoutActivityType.mindAndBody.rawValue)
                ]
            )
        ]
    }

    // MARK: - Category Library (full picker catalog)

    /// Complete catalog of every workout type Chalk can track.
    ///
    /// Evaluated once (lazy `static let`), giving each template a stable UUID so the
    /// `AddGoalView` grid can rely on identity-based selection across renders.
    /// `defaultCategories` is a subset of this library (first 3 entries).
    static let categoryLibrary: [WorkoutCategory] = {
        [
            WorkoutCategory(
                name: "Strength",
                icon: "figure.strengthtraining.traditional",
                colorHex: "#135bec",
                targetPerWeek: 4,
                activityTypeRawValues: [
                    Int(HKWorkoutActivityType.traditionalStrengthTraining.rawValue),
                    Int(HKWorkoutActivityType.functionalStrengthTraining.rawValue)
                ]
            ),
            WorkoutCategory(
                name: "Running",
                icon: "figure.run",
                colorHex: "#ff9500",
                targetPerWeek: 3,
                activityTypeRawValues: [Int(HKWorkoutActivityType.running.rawValue)]
            ),
            WorkoutCategory(
                name: "Yoga",
                icon: "figure.yoga",
                colorHex: "#af52de",
                targetPerWeek: 1,
                activityTypeRawValues: [
                    Int(HKWorkoutActivityType.yoga.rawValue),
                    Int(HKWorkoutActivityType.mindAndBody.rawValue)
                ]
            ),
            WorkoutCategory(
                name: "Cycling",
                icon: "figure.outdoor.cycle",
                colorHex: "#30d158",
                targetPerWeek: 3,
                activityTypeRawValues: [Int(HKWorkoutActivityType.cycling.rawValue)]
            ),
            WorkoutCategory(
                name: "Walking",
                icon: "figure.walk",
                colorHex: "#32ade6",
                targetPerWeek: 5,
                activityTypeRawValues: [Int(HKWorkoutActivityType.walking.rawValue)]
            ),
            WorkoutCategory(
                name: "HIIT",
                icon: "figure.highintensity.intervaltraining",
                colorHex: "#ff453a",
                targetPerWeek: 2,
                activityTypeRawValues: [
                    Int(HKWorkoutActivityType.highIntensityIntervalTraining.rawValue)
                ]
            ),
            WorkoutCategory(
                name: "Swimming",
                icon: "figure.pool.swim",
                colorHex: "#64d2ff",
                targetPerWeek: 2,
                activityTypeRawValues: [Int(HKWorkoutActivityType.swimming.rawValue)]
            ),
            WorkoutCategory(
                name: "Rowing",
                icon: "figure.rowing",
                colorHex: "#ff9f0a",
                targetPerWeek: 2,
                activityTypeRawValues: [Int(HKWorkoutActivityType.rowing.rawValue)]
            ),
        ]
    }()

    // MARK: - Authorisation

    /// Requests HealthKit read permission for workout data.
    ///
    /// A single `HKWorkoutType` covers all `HKWorkoutActivityType` variants —
    /// no need to enumerate individual types per category.
    ///
    /// - Parameter categories: Provided for API consistency; not used in the query.
    /// - Throws: If the system rejects the authorisation request (e.g. parental controls).
    ///   Note: HealthKit never throws when the user simply denies — it silently
    ///   returns zero results on subsequent queries instead.
    func requestAuthorization(for categories: [WorkoutCategory]) async throws {
        let readTypes: Set<HKObjectType> = [HKObjectType.workoutType()]
        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
    }

    // MARK: - Fetching Workouts

    /// Fetches all workouts matching a category's activity types within a date range.
    ///
    /// - Parameters:
    ///   - category: The `WorkoutCategory` whose `activityTypeRawValues` drive the query.
    ///   - startDate: Inclusive range start (typically the Monday 00:00 of the ISO week).
    ///   - endDate:   Inclusive range end   (typically the Sunday 23:59 of the ISO week).
    /// - Returns: Deduplicated `WorkoutEntry` values mapped from matching `HKWorkout` samples.
    /// - Throws: If any underlying HealthKit query fails.
    func fetchWorkouts(
        for category: WorkoutCategory,
        from startDate: Date,
        to endDate: Date
    ) async throws -> [WorkoutEntry] {

        let activityTypes = category.activityTypeRawValues
            .compactMap { HKWorkoutActivityType(rawValue: UInt($0)) }

        var allEntries: [WorkoutEntry] = []

        for activityType in activityTypes {
            let typePredicate = HKQuery.predicateForWorkouts(with: activityType)
            let datePredicate = HKQuery.predicateForSamples(
                withStart: startDate,
                end: endDate,
                options: .strictStartDate
            )
            let predicate = NSCompoundPredicate(
                andPredicateWithSubpredicates: [typePredicate, datePredicate]
            )
            let sortDescriptor = NSSortDescriptor(
                key: HKSampleSortIdentifierStartDate,
                ascending: false
            )

            let entries: [WorkoutEntry] = try await withCheckedThrowingContinuation { continuation in
                let query = HKSampleQuery(
                    sampleType: .workoutType(),
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: [sortDescriptor]
                ) { _, samples, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    let workouts = samples?.compactMap { $0 as? HKWorkout } ?? []
                    let mapped = workouts.map { workout in
                        WorkoutEntry(
                            categoryId: category.id,
                            date: workout.startDate,
                            duration: workout.duration,
                            source: .healthKit,
                            externalId: workout.uuid
                        )
                    }
                    continuation.resume(returning: mapped)
                }
                self.healthStore.execute(query)
            }

            allEntries.append(contentsOf: entries)
        }

        // Pass 1 — deduplicate by externalId: defensive guard against a single HK sample
        // matching more than one activityType in activityTypeRawValues.
        var seen = Set<UUID>()
        let deduped = allEntries.filter { entry in
            guard let externalId = entry.externalId else { return true }
            return seen.insert(externalId).inserted
        }

        // Pass 2 — overlap deduplication: if two workouts of the same category overlap
        // in time (e.g. a Nike Run Club entry and its Strava mirror), keep only the
        // longest one and mark the rest isHidden = true.
        //
        // Algorithm: sort by start date, sweep through building overlap groups, then
        // within each group of size > 1 keep the entry with the greatest duration
        // (ties broken by earliest start date).
        let sorted = deduped.sorted { $0.date < $1.date }
        var groups: [[WorkoutEntry]] = []
        var currentGroup: [WorkoutEntry] = []
        var groupEndDate = Date.distantPast

        for entry in sorted {
            let entryEnd = entry.date.addingTimeInterval(entry.duration)
            if currentGroup.isEmpty || entry.date < groupEndDate {
                currentGroup.append(entry)
                if entryEnd > groupEndDate { groupEndDate = entryEnd }
            } else {
                groups.append(currentGroup)
                currentGroup = [entry]
                groupEndDate = entryEnd
            }
        }
        if !currentGroup.isEmpty { groups.append(currentGroup) }

        return groups.flatMap { group -> [WorkoutEntry] in
            guard group.count > 1 else { return group }
            let keeper = group.max { a, b in
                a.duration == b.duration ? a.date > b.date : a.duration < b.duration
            }!
            return group.map { entry in
                var e = entry
                e.isHidden = entry.id != keeper.id
                return e
            }
        }
    }

    /// Fetches workout data for the current ISO week across all categories
    /// and returns a `WeeklyGoal` snapshot for each.
    ///
    /// - Parameter categories: All user-defined categories to evaluate.
    /// - Returns: One `WeeklyGoal` per category with accurate `completedCount`.
    /// - Throws: If any underlying HealthKit query fails.
    func fetchCurrentWeekGoals(for categories: [WorkoutCategory]) async throws -> [WeeklyGoal] {
        let calendar = Calendar.iso8601
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: Date()) else {
            return categories.map { WeeklyGoal(category: $0, completedCount: 0) }
        }

        var goals: [WeeklyGoal] = []
        for category in categories {
            let entries = try await fetchWorkouts(
                for: category,
                from: weekInterval.start,
                to: weekInterval.end
            )
            let visibleCount = entries.filter { !$0.isHidden }.count
            goals.append(WeeklyGoal(category: category, completedCount: visibleCount))
        }
        return goals
    }

    /// Fetches all workout entries across all categories for the current ISO week.
    ///
    /// Used to populate `AppState.entries` for the History tab.
    /// Results are sorted newest-first.
    func fetchCurrentWeekEntries(for categories: [WorkoutCategory]) async throws -> [WorkoutEntry] {
        let calendar = Calendar.iso8601
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: Date()) else {
            return []
        }
        var allEntries: [WorkoutEntry] = []
        for category in categories {
            let entries = try await fetchWorkouts(
                for: category,
                from: weekInterval.start,
                to: weekInterval.end
            )
            allEntries.append(contentsOf: entries)
        }
        return allEntries.sorted { $0.date > $1.date }
    }

    // MARK: - Background Delivery

    /// Registers HealthKit observer queries so the system can wake the app
    /// when new workouts are recorded, keeping weekly goal counts up to date.
    ///
    /// ⚠️  Not called in Phase 2. Will be activated in Phase 4 when the widget
    ///     needs to reload its timeline after new workouts arrive.
    ///
    /// Prerequisites — add in Xcode before enabling:
    ///   1. Signing & Capabilities → HealthKit → tick "Background Delivery"
    ///   2. Entitlement added automatically: `com.apple.developer.healthkit.background-delivery`
    ///   3. Info.plist: `UIBackgroundModes` array → add `health-kit`
    func enableBackgroundDelivery() {
        let workoutType = HKObjectType.workoutType()

        healthStore.enableBackgroundDelivery(for: workoutType, frequency: .immediate) { success, error in
            if let error {
                print("[Chalk] HealthKit background delivery registration failed: \(error.localizedDescription)")
                return
            }
            if success {
                print("[Chalk] HealthKit background delivery enabled.")
            }
        }

        let observerQuery = HKObserverQuery(sampleType: workoutType, predicate: nil) { _, completionHandler, error in
            defer { completionHandler() }
            if let error {
                print("[Chalk] HKObserverQuery error: \(error.localizedDescription)")
                return
            }
            // TODO: Phase 4 — Refresh goals and reload widget timelines:
            // Task { @MainActor in
            //     await appState.refreshGoals()
            //     WidgetCenter.shared.reloadAllTimelines()
            // }
        }

        healthStore.execute(observerQuery)
    }
}
