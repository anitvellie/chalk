// WorkoutEntry.swift
// Chalk — Data Model
//
// Phase 1: Scaffold stub — properties declared, no persistence logic yet.

import Foundation

/// A single completed workout instance.
///
/// Entries are either imported from HealthKit or entered manually (Phase 3+).
/// Each entry references a `WorkoutCategory` by `UUID` rather than embedding
/// the full category object, keeping the model flat and easy to persist.
struct WorkoutEntry: Identifiable, Codable, Hashable {

    // MARK: - Properties

    let id: UUID

    /// The `WorkoutCategory.id` this entry belongs to.
    var categoryId: UUID

    /// Date and time the workout took place.
    var date: Date

    /// Duration of the workout in seconds.
    var duration: TimeInterval

    /// Whether this entry was imported from HealthKit or added manually.
    var source: WorkoutSource

    /// The `HKWorkout.uuid` for HealthKit-sourced entries.
    /// `nil` for manually-entered entries.
    var externalId: UUID?

    /// `true` when this entry has been suppressed by overlap deduplication.
    ///
    /// Hidden entries are retained in memory so they can be surfaced in future
    /// UI (e.g. letting the user choose which duplicate to keep), but they are
    /// excluded from weekly goal counts and the History list.
    var isHidden: Bool

    // MARK: - Init

    init(
        id: UUID = UUID(),
        categoryId: UUID,
        date: Date,
        duration: TimeInterval,
        source: WorkoutSource,
        externalId: UUID? = nil,
        isHidden: Bool = false
    ) {
        self.id = id
        self.categoryId = categoryId
        self.date = date
        self.duration = duration
        self.source = source
        self.externalId = externalId
        self.isHidden = isHidden
    }
}

// MARK: - WorkoutSource

/// Describes how a `WorkoutEntry` was created.
enum WorkoutSource: String, Codable, CaseIterable, Sendable {

    /// Imported automatically from Apple HealthKit.
    case healthKit = "healthKit"

    /// Entered manually by the user inside Chalk (Phase 3+).
    case manual = "manual"
}
