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
    private var workoutObserverQuery: HKObserverQuery?

    /// `true` if HealthKit is supported on this device.
    /// Always `false` on Simulator; always `true` on iPhone.
    static var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    /// Raw integer value of `HKWorkoutActivityType.walking`.
    /// Exposed as a plain `Int` so non-HealthKit layers (AppState) can identify
    /// walking entries without importing HealthKit.
    static let walkingActivityTypeRawValue: Int = Int(HKWorkoutActivityType.walking.rawValue)

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
                targetPerWeek: 4,
                activityTypeRawValues: [
                    Int(HKWorkoutActivityType.traditionalStrengthTraining.rawValue),
                    Int(HKWorkoutActivityType.functionalStrengthTraining.rawValue)
                ]
            ),
            WorkoutCategory(
                name: "Running",
                icon: "figure.run",
                targetPerWeek: 3,
                activityTypeRawValues: [
                    Int(HKWorkoutActivityType.running.rawValue)
                ]
            ),
            WorkoutCategory(
                name: "Yoga",
                icon: "figure.yoga",
                targetPerWeek: 1,
                activityTypeRawValues: [
                    Int(HKWorkoutActivityType.yoga.rawValue),
                    Int(HKWorkoutActivityType.mindAndBody.rawValue)
                ]
            )
        ]
    }

    // MARK: - Category Library (full picker catalog)

    /// Complete catalog of every HealthKit workout type Chalk can track, sorted alphabetically.
    ///
    /// Each template has a stable UUID (lazy static) so GoalSetupView can rely on
    /// identity-based rendering across redraws. One entry per distinct HK activity type
    /// (Yoga bundles yoga + mindAndBody since they're indistinguishable in practice;
    /// Strength covers traditionalStrengthTraining only — Functional Strength is separate).
    static let categoryLibrary: [WorkoutCategory] = {
        [
            WorkoutCategory(name: "American Football", icon: "figure.american.football",   targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.americanFootball.rawValue)]),
            WorkoutCategory(name: "Archery",           icon: "figure.archery",             targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.archery.rawValue)]),
            WorkoutCategory(name: "Aus. Football",     icon: "figure.australian.football", targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.australianFootball.rawValue)]),
            WorkoutCategory(name: "Badminton",         icon: "figure.badminton",           targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.badminton.rawValue)]),
            WorkoutCategory(name: "Barre",             icon: "figure.barre",               targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.barre.rawValue)]),
            WorkoutCategory(name: "Baseball",          icon: "figure.baseball",            targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.baseball.rawValue)]),
            WorkoutCategory(name: "Basketball",        icon: "figure.basketball",          targetPerWeek: 3, activityTypeRawValues: [Int(HKWorkoutActivityType.basketball.rawValue)]),
            WorkoutCategory(name: "Bowling",           icon: "figure.bowling",             targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.bowling.rawValue)]),
            WorkoutCategory(name: "Boxing",            icon: "figure.boxing",              targetPerWeek: 3, activityTypeRawValues: [Int(HKWorkoutActivityType.boxing.rawValue)]),
            WorkoutCategory(name: "Climbing",          icon: "figure.climbing",            targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.climbing.rawValue)]),
            WorkoutCategory(name: "Cooldown",          icon: "figure.cooldown",            targetPerWeek: 3, activityTypeRawValues: [Int(HKWorkoutActivityType.cooldown.rawValue)]),
            WorkoutCategory(name: "Core Training",     icon: "figure.core.training",       targetPerWeek: 3, activityTypeRawValues: [Int(HKWorkoutActivityType.coreTraining.rawValue)]),
            WorkoutCategory(name: "Cricket",           icon: "figure.cricket",             targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.cricket.rawValue)]),
            WorkoutCategory(name: "Cross Training",    icon: "figure.cross.training",      targetPerWeek: 3, activityTypeRawValues: [Int(HKWorkoutActivityType.crossTraining.rawValue)]),
            WorkoutCategory(name: "Cross-Country Ski", icon: "figure.skiing.crosscountry", targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.crossCountrySkiing.rawValue)]),
            WorkoutCategory(name: "Curling",           icon: "figure.curling",             targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.curling.rawValue)]),
            WorkoutCategory(name: "Cycling",           icon: "figure.outdoor.cycle",       targetPerWeek: 3, activityTypeRawValues: [Int(HKWorkoutActivityType.cycling.rawValue)]),
            WorkoutCategory(name: "Dance",             icon: "figure.dance",               targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.dance.rawValue)]),
            WorkoutCategory(name: "Disc Sports",       icon: "figure.disc.sports",         targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.discSports.rawValue)]),
            WorkoutCategory(name: "Downhill Skiing",   icon: "figure.skiing.downhill",     targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.downhillSkiing.rawValue)]),
            WorkoutCategory(name: "Elliptical",        icon: "figure.elliptical",          targetPerWeek: 3, activityTypeRawValues: [Int(HKWorkoutActivityType.elliptical.rawValue)]),
            WorkoutCategory(name: "Equestrian",        icon: "figure.equestrian.sports",   targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.equestrianSports.rawValue)]),
            WorkoutCategory(name: "Fencing",           icon: "figure.fencing",             targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.fencing.rawValue)]),
            WorkoutCategory(name: "Fishing",           icon: "figure.fishing",             targetPerWeek: 1, activityTypeRawValues: [Int(HKWorkoutActivityType.fishing.rawValue)]),
            WorkoutCategory(name: "Flexibility",       icon: "figure.flexibility",         targetPerWeek: 3, activityTypeRawValues: [Int(HKWorkoutActivityType.flexibility.rawValue)]),
            WorkoutCategory(name: "Functional Strength", icon: "figure.strengthtraining.functional", targetPerWeek: 3, activityTypeRawValues: [Int(HKWorkoutActivityType.functionalStrengthTraining.rawValue)]),
            WorkoutCategory(name: "Golf",              icon: "figure.golf",                targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.golf.rawValue)]),
            WorkoutCategory(name: "Gymnastics",        icon: "figure.gymnastics",          targetPerWeek: 3, activityTypeRawValues: [Int(HKWorkoutActivityType.gymnastics.rawValue)]),
            WorkoutCategory(name: "Hand Cycling",      icon: "figure.hand.cycling",        targetPerWeek: 3, activityTypeRawValues: [Int(HKWorkoutActivityType.handCycling.rawValue)]),
            WorkoutCategory(name: "Handball",          icon: "figure.handball",            targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.handball.rawValue)]),
            WorkoutCategory(name: "HIIT",              icon: "figure.highintensity.intervaltraining", targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.highIntensityIntervalTraining.rawValue)]),
            WorkoutCategory(name: "Hiking",            icon: "figure.hiking",              targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.hiking.rawValue)]),
            WorkoutCategory(name: "Hockey",            icon: "figure.hockey",              targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.hockey.rawValue)]),
            WorkoutCategory(name: "Hunting",           icon: "figure.hunting",             targetPerWeek: 1, activityTypeRawValues: [Int(HKWorkoutActivityType.hunting.rawValue)]),
            WorkoutCategory(name: "Jump Rope",         icon: "figure.jumprope",            targetPerWeek: 3, activityTypeRawValues: [Int(HKWorkoutActivityType.jumpRope.rawValue)]),
            WorkoutCategory(name: "Kickboxing",        icon: "figure.kickboxing",          targetPerWeek: 3, activityTypeRawValues: [Int(HKWorkoutActivityType.kickboxing.rawValue)]),
            WorkoutCategory(name: "Lacrosse",          icon: "figure.lacrosse",            targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.lacrosse.rawValue)]),
            WorkoutCategory(name: "Martial Arts",      icon: "figure.martial.arts",        targetPerWeek: 3, activityTypeRawValues: [Int(HKWorkoutActivityType.martialArts.rawValue)]),
            WorkoutCategory(name: "Mixed Cardio",      icon: "figure.mixed.cardio",        targetPerWeek: 3, activityTypeRawValues: [Int(HKWorkoutActivityType.mixedCardio.rawValue)]),
            WorkoutCategory(name: "Pickleball",        icon: "figure.pickleball",          targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.pickleball.rawValue)]),
            WorkoutCategory(name: "Pilates",           icon: "figure.pilates",             targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.pilates.rawValue)]),
            WorkoutCategory(name: "Racquetball",       icon: "figure.racquetball",         targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.racquetball.rawValue)]),
            WorkoutCategory(name: "Rowing",            icon: "figure.indoor.rowing",       targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.rowing.rawValue)]),
            WorkoutCategory(name: "Rugby",             icon: "figure.rugby",               targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.rugby.rawValue)]),
            WorkoutCategory(name: "Running",           icon: "figure.run",                 targetPerWeek: 3, activityTypeRawValues: [Int(HKWorkoutActivityType.running.rawValue)]),
            WorkoutCategory(name: "Sailing",           icon: "figure.sailing",             targetPerWeek: 1, activityTypeRawValues: [Int(HKWorkoutActivityType.sailing.rawValue)]),
            WorkoutCategory(name: "Skating",           icon: "figure.skating",             targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.skatingSports.rawValue)]),
            WorkoutCategory(name: "Snowboarding",      icon: "figure.snowboarding",        targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.snowboarding.rawValue)]),
            WorkoutCategory(name: "Soccer",            icon: "figure.soccer",              targetPerWeek: 3, activityTypeRawValues: [Int(HKWorkoutActivityType.soccer.rawValue)]),
            WorkoutCategory(name: "Softball",          icon: "figure.softball",            targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.softball.rawValue)]),
            WorkoutCategory(name: "Squash",            icon: "figure.squash",              targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.squash.rawValue)]),
            WorkoutCategory(name: "Stair Climbing",    icon: "figure.stair.stepper",       targetPerWeek: 3, activityTypeRawValues: [Int(HKWorkoutActivityType.stairClimbing.rawValue)]),
            WorkoutCategory(name: "Stairs",            icon: "figure.stairs",              targetPerWeek: 3, activityTypeRawValues: [Int(HKWorkoutActivityType.stairs.rawValue)]),
            WorkoutCategory(name: "Step Training",     icon: "figure.step.training",       targetPerWeek: 3, activityTypeRawValues: [Int(HKWorkoutActivityType.stepTraining.rawValue)]),
            WorkoutCategory(name: "Strength",          icon: "figure.strengthtraining.traditional", targetPerWeek: 4, activityTypeRawValues: [Int(HKWorkoutActivityType.traditionalStrengthTraining.rawValue)]),
            WorkoutCategory(name: "Surfing",           icon: "figure.surfing",             targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.surfingSports.rawValue)]),
            WorkoutCategory(name: "Swimming",          icon: "figure.pool.swim",           targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.swimming.rawValue)]),
            WorkoutCategory(name: "Table Tennis",      icon: "figure.table.tennis",        targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.tableTennis.rawValue)]),
            WorkoutCategory(name: "Tai Chi",           icon: "figure.taichi",              targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.taiChi.rawValue)]),
            WorkoutCategory(name: "Tennis",            icon: "figure.tennis",              targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.tennis.rawValue)]),
            WorkoutCategory(name: "Track & Field",     icon: "figure.track.and.field",     targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.trackAndField.rawValue)]),
            WorkoutCategory(name: "Volleyball",        icon: "figure.volleyball",          targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.volleyball.rawValue)]),
            WorkoutCategory(name: "Walking",           icon: "figure.walk",                targetPerWeek: 5, activityTypeRawValues: [Int(HKWorkoutActivityType.walking.rawValue)]),
            WorkoutCategory(name: "Water Fitness",     icon: "figure.water.fitness",       targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.waterFitness.rawValue)]),
            WorkoutCategory(name: "Water Polo",        icon: "figure.water.polo",          targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.waterPolo.rawValue)]),
            WorkoutCategory(name: "Wheelchair Run",    icon: "figure.roll.runningpace",    targetPerWeek: 3, activityTypeRawValues: [Int(HKWorkoutActivityType.wheelchairRunPace.rawValue)]),
            WorkoutCategory(name: "Wheelchair Walk",   icon: "figure.roll",                targetPerWeek: 5, activityTypeRawValues: [Int(HKWorkoutActivityType.wheelchairWalkPace.rawValue)]),
            WorkoutCategory(name: "Wrestling",         icon: "figure.wrestling",           targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.wrestling.rawValue)]),
            WorkoutCategory(name: "Yoga",              icon: "figure.yoga",                targetPerWeek: 2, activityTypeRawValues: [Int(HKWorkoutActivityType.yoga.rawValue), Int(HKWorkoutActivityType.mindAndBody.rawValue)]),
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
    /// Registers for HealthKit background delivery so the widget snapshot stays
    /// fresh even when the app is not running.
    ///
    /// HealthKit can relaunch the app in the background when a new workout is saved.
    /// On relaunch the observer query fires immediately, `onUpdate` is called, and
    /// the completion handler is forwarded to HealthKit to confirm delivery.
    ///
    /// Safe to call multiple times — re-registration is a no-op if the query is
    /// already active. Requires:
    ///   - Entitlement: `com.apple.developer.healthkit.background-delivery`
    ///   - Info.plist: `UIBackgroundModes` → `health-kit`
    ///   - Xcode Signing & Capabilities → HealthKit → "Background Delivery" ticked
    func enableBackgroundDelivery(onUpdate: @escaping () -> Void) {
        guard workoutObserverQuery == nil else { return }

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

        let query = HKObserverQuery(sampleType: workoutType, predicate: nil) { _, completionHandler, error in
            defer { completionHandler() }
            if let error {
                print("[Chalk] HKObserverQuery error: \(error.localizedDescription)")
                return
            }
            onUpdate()
        }

        workoutObserverQuery = query
        healthStore.execute(query)
    }
}
