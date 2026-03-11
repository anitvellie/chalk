// HealthKitManager.swift
// Chalk — HealthKit Integration Layer
//
// Phase 1: Scaffold stub — method signatures and TODO comments only.
// No HealthKit queries are executed.
//
// Architecture notes:
// - HealthKit is READ-ONLY. This manager never writes data back.
// - All public methods are async/throws to support the Phase 2 query implementation.
// - The model layer (WorkoutCategory, WorkoutEntry) does NOT import HealthKit.
//   This manager is the sole bridge between HK types and Chalk's domain models.

import Foundation
import HealthKit

/// Manages all read-only interaction with Apple HealthKit.
///
/// Inject as a `@StateObject` or pass via the environment from `AppState`.
@MainActor
final class HealthKitManager: ObservableObject {

    // MARK: - Properties

    private let healthStore = HKHealthStore()

    /// `true` if HealthKit is available on this device (not available on iPad without Fitness data).
    static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    // MARK: - Authorisation

    /// Requests HealthKit read permissions for all `HKWorkoutActivityType`s
    /// referenced across the given categories.
    ///
    /// - Parameter categories: Categories whose `activityTypeRawValues` determine
    ///   which HK types to request.
    /// - Throws: If the authorisation request fails.
    func requestAuthorization(for categories: [WorkoutCategory]) async throws {
        // TODO: Phase 2 — Build HKObjectType set from category.activityTypeRawValues:
        //   let types = categories
        //       .flatMap(\.activityTypeRawValues)
        //       .compactMap { HKWorkoutActivityType(rawValue: UInt($0)) }
        //       .map { HKObjectType.workoutType() }   // workouts are queried by type
        //
        // TODO: Phase 2 — Request authorisation:
        //   try await healthStore.requestAuthorization(toShare: [], read: Set(types))
        //
        // TODO: Phase 2 — Update AppState.healthKitAuthorized after the call.
    }

    // MARK: - Fetching Workouts

    /// Fetches all workouts matching a category's activity types within a date range.
    ///
    /// - Parameters:
    ///   - category: The `WorkoutCategory` to query for.
    ///   - startDate: Inclusive range start.
    ///   - endDate:   Inclusive range end.
    /// - Returns: An array of `WorkoutEntry` values mapped from `HKWorkout` samples.
    /// - Throws: If the HealthKit query fails.
    func fetchWorkouts(
        for category: WorkoutCategory,
        from startDate: Date,
        to endDate: Date
    ) async throws -> [WorkoutEntry] {
        // TODO: Phase 2 — For each activityTypeRawValue in category.activityTypeRawValues:
        //   1. Build HKWorkoutType predicate filtered by date range.
        //   2. Build HKSampleQuery (or HKAnchoredObjectQuery for live updates).
        //   3. Execute on healthStore.
        //   4. Map HKWorkout → WorkoutEntry (id: UUID(), categoryId: category.id,
        //      date: hkWorkout.startDate, duration: hkWorkout.duration,
        //      source: .healthKit, externalId: hkWorkout.uuid).
        //
        // TODO: Phase 2 — Special case for "Legs": because Legs and Upper Body both
        //   map to .traditionalStrengthTraining, use HKWorkout.workoutActivityType
        //   AND filter by workout.metadata[HKMetadataKeyWorkoutBrandName] or
        //   workout source (Strong app) + workout name to disambiguate.
        return []
    }

    /// Fetches workout entries for the current ISO week across all categories
    /// and returns a snapshot of `WeeklyGoal` progress.
    ///
    /// - Parameter categories: All user-defined categories to evaluate.
    /// - Returns: One `WeeklyGoal` per category, populated with `completedCount`.
    /// - Throws: If any underlying HealthKit query fails.
    func fetchCurrentWeekGoals(for categories: [WorkoutCategory]) async throws -> [WeeklyGoal] {
        // TODO: Phase 2 — Compute ISO week window:
        //   let calendar = Calendar(identifier: .iso8601)
        //   let weekInterval = calendar.dateInterval(of: .weekOfYear, for: Date())
        //
        // TODO: Phase 2 — For each category, call fetchWorkouts(for:from:to:)
        //   and wrap results in WeeklyGoal.compute(for:from:).
        return categories.map { WeeklyGoal(category: $0, completedCount: 0) }
    }

    // MARK: - Background Delivery

    /// Registers HealthKit observer queries so the app can refresh goals
    /// in the background when new workouts are added.
    func enableBackgroundDelivery() {
        // TODO: Phase 2 — For each relevant HKWorkoutActivityType:
        //   healthStore.enableBackgroundDelivery(for: workoutType,
        //       frequency: .immediate) { success, error in ... }
        //
        // TODO: Phase 2 — Set up HKObserverQuery to wake the app and trigger
        //   a goals refresh + widget timeline reload via WidgetCenter.
    }
}
