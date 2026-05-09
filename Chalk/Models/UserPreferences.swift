// UserPreferences.swift
// Chalk — User Preferences Model

import Foundation

/// Persisted user preferences that control how workouts are counted and displayed.
struct UserPreferences: Codable, Equatable {

    /// Minimum workout duration (minutes) for a session to count.
    /// Applied to all activity types except walking.
    var minWorkoutDurationMinutes: Int = 5

    /// Minimum duration (minutes) specifically for walking sessions.
    /// Replaces (does not stack with) the general threshold for walking entries.
    var minWalkingDurationMinutes: Int = 45

    /// `HKWorkoutActivityType` raw values the user wants hidden everywhere
    /// (History, weekly strip, and goal counts).
    var excludedActivityTypeRawValues: Set<Int> = []
}
