// WorkoutCategory.swift
// Chalk — Data Model

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
    /// Resolved from enum cases in `HealthKitManager.defaultCategories` — never hardcoded.
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

    /// Shape-only default categories (no HK raw values) used as a fallback reference.
    ///
    /// The HK-aware version — with `activityTypeRawValues` correctly populated from
    /// `HKWorkoutActivityType.case.rawValue` — lives in `HealthKitManager.defaultCategories`.
    /// `AppState.loadCategories()` seeds from that source on first launch.
    ///
    /// Upper Body and Legs are merged into **Strength** because both map to
    /// `HKWorkoutActivityType.traditionalStrengthTraining` in HealthKit with no
    /// reliable way to distinguish them from workout metadata alone.
    static let defaults: [WorkoutCategory] = [
        WorkoutCategory(
            name: "Strength",
            icon: "figure.strengthtraining.traditional",
            colorHex: "#135bec",
            targetPerWeek: 4
        ),
        WorkoutCategory(
            name: "Running",
            icon: "figure.run",
            colorHex: "#ff9500",
            targetPerWeek: 3
        ),
        WorkoutCategory(
            name: "Yoga",
            icon: "figure.yoga",
            colorHex: "#af52de",
            targetPerWeek: 1
        )
    ]
}
