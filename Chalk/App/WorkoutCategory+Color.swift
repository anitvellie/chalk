// WorkoutCategory+Color.swift
// Chalk — View-layer colour mapping (app target only)
//
// Single source of truth for the display colour of every workout type.
// Both the goal-card ring and the weekly activity strip derive from `displayColor`.
// Add a new case here whenever a new type is added to HealthKitManager.categoryLibrary.

import SwiftUI

extension WorkoutCategory {

    /// The UIKit system colour assigned to this workout type.
    /// Switches on the SF Symbol icon name — the semantic per-type identifier
    /// that is already present in the view layer without importing HealthKit.
    var displayColor: Color {
        switch icon {
        case "figure.strengthtraining.traditional",
             "figure.strengthtraining.functional":
            return Color(uiColor: .systemCyan)
        case "figure.run":
            return Color(uiColor: .systemOrange)
        case "figure.yoga",
             "figure.mind.and.body":
            return Color(uiColor: .systemPink)
        case "figure.outdoor.cycle":
            return Color(uiColor: .systemBlue)
        case "figure.walk":
            return Color(uiColor: .systemGreen)
        case "figure.highintensity.intervaltraining":
            return Color(uiColor: .systemYellow)
        case "figure.pool.swim":
            return Color(uiColor: .systemTeal)
        case "figure.indoor.rowing":
            return Color(uiColor: .systemIndigo)
        default:
            return Color(uiColor: .systemPurple)
        }
    }
}
