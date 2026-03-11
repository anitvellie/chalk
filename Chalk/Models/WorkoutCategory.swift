// WorkoutCategory.swift
// Chalk — Data Model
//
// Phase 1: Scaffold stub — properties and default seed data declared.
// No persistence or HealthKit logic implemented yet.

import Foundation

/// A user-defined workout category with a weekly completion target.
///
/// Design decisions:
/// - `colorHex` stores colour as a hex string (e.g. `"#135bec"`) so the model
///   is serialisable and sharable via App Groups without importing SwiftUI.
///   Convert to `SwiftUI.Color` in the view layer using `Color(hex:)`.
/// - `activityTypeRawValues` stores `HKWorkoutActivityType.rawValue` integers
///   so the Models layer stays free of a HealthKit import.
///   The mapping logic lives in `HealthKitManager`.
struct WorkoutCategory: Identifiable, Codable, Hashable {

    // MARK: - Properties

    let id: UUID

    /// Human-readable name shown in the UI (e.g. "Running").
    var name: String

    /// SF Symbol name for the category icon (e.g. "figure.run").
    var icon: String

    /// Colour as a hex string (e.g. "#135bec"). Convert to SwiftUI Color in the view layer.
    var colorHex: String

    /// How many times the user wants to complete this workout per week.
    var targetPerWeek: Int

    /// Raw integer values of the `HKWorkoutActivityType` cases this category maps to.
    /// Populated in Phase 2 when HealthKit integration is implemented.
    var activityTypeRawValues: [Int]

    // MARK: - Init

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String,
        targetPerWeek: Int,
        activityTypeRawValues: [Int] = []
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.targetPerWeek = targetPerWeek
        self.activityTypeRawValues = activityTypeRawValues
    }
}

// MARK: - Default Seed Data

extension WorkoutCategory {

    /// Default categories shown during first-launch onboarding.
    ///
    /// HK activity type raw values are left empty here and will be assigned in Phase 2
    /// once the HealthKit mapping layer is built.
    static let defaults: [WorkoutCategory] = [
        WorkoutCategory(
            name: "Upper Body",
            icon: "figure.strengthtraining.traditional",
            colorHex: "#135bec",
            targetPerWeek: 2,
            activityTypeRawValues: []
            // TODO: Phase 2 — map to HK .traditionalStrengthTraining + .functionalStrengthTraining
        ),
        WorkoutCategory(
            name: "Legs",
            icon: "figure.strengthtraining.functional",
            colorHex: "#34c759",
            targetPerWeek: 2,
            activityTypeRawValues: []
            // TODO: Phase 2 — map to HK .traditionalStrengthTraining (name-filtered) + .cycling
        ),
        WorkoutCategory(
            name: "Running",
            icon: "figure.run",
            colorHex: "#ff9500",
            targetPerWeek: 3,
            activityTypeRawValues: []
            // TODO: Phase 2 — map to HK .running
        ),
        WorkoutCategory(
            name: "Yoga",
            icon: "figure.yoga",
            colorHex: "#af52de",
            targetPerWeek: 1,
            activityTypeRawValues: []
            // TODO: Phase 2 — map to HK .yoga + .mindAndBody
        )
    ]
}
