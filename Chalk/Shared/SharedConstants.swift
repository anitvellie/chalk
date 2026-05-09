// SharedConstants.swift
// Chalk — Shared Layer (App ↔ Widget ↔ Watch)
//
// Phase 1: Scaffold stub — constants and key namespace declared.
// This file is compiled into both the Chalk app target and ChalkWidgetExtension target.
//
// ⚠️  Before building for the first time:
//     1. Register the App Group ID in the Apple Developer portal.
//     2. Add the App Group capability to both "Chalk" and "ChalkWidgetExtension"
//        targets in Xcode → Signing & Capabilities.
//     3. Replace the placeholder strings below with your real identifiers.

import Foundation

/// Constants shared between the Chalk app and its extensions.
/// All values in this file must be safe to use in both app and extension contexts.
enum SharedConstants {

    // MARK: - App Group

    /// Identifier for the shared App Group container.
    ///
    static let appGroupIdentifier = "group.com.chalkweekly.app"

    // MARK: - Shared UserDefaults

    /// Returns a `UserDefaults` instance backed by the shared App Group container.
    /// Returns `nil` if the App Group entitlement is not yet configured.
    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    // MARK: - UserDefaults Keys

    /// Type-safe key namespace for values stored in the shared `UserDefaults`.
    enum UserDefaultsKey {
        static let preferences    = "userPreferences"
        static let categories     = "categories"
        static let widgetSnapshot = "widgetSnapshot"
    }

    // MARK: - Widget Configuration

    /// Kind strings matching those declared in the WidgetBundle.
    enum WidgetKind {
        static let singleGoal = "chalk.widget.singleGoal"
        static let allGoals   = "chalk.widget.allGoals"
        static let weekly     = "chalk.widget.weekly"
    }
}
