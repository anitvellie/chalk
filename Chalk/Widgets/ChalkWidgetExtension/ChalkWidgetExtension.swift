// ChalkWidgetExtension.swift
// Chalk — WidgetKit Extension
//
// Phase 1: Scaffold stub — widget bundle, provider, entry, and view shells declared.
// No real data is loaded; all views render placeholder content.
//
// Phase 4 will implement:
//   - Loading WeeklyGoal data from App Group UserDefaults.
//   - Tally-mark progress ring rendering per category.
//   - Timeline policy keyed to ISO week boundaries.

import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

/// Data model for a single widget timeline snapshot.
/// Phase 1: Contains only a timestamp.
/// Phase 4 will add `weeklyGoals: [WeeklyGoal]`.
struct ChalkWidgetEntry: TimelineEntry {
    let date: Date

    // TODO: Phase 4 — var weeklyGoals: [WeeklyGoal]

    static let placeholder = ChalkWidgetEntry(date: .now)
}

// MARK: - Timeline Provider

/// Provides timeline entries to WidgetKit.
/// Phase 1: Returns placeholder entries only.
struct ChalkWidgetProvider: TimelineProvider {

    func placeholder(in context: Context) -> ChalkWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (ChalkWidgetEntry) -> Void) {
        // TODO: Phase 4 — Read WeeklyGoal snapshot from SharedConstants.sharedDefaults.
        completion(.placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ChalkWidgetEntry>) -> Void) {
        // TODO: Phase 4 — Decode persisted WeeklyGoal data from App Group UserDefaults.
        // TODO: Phase 4 — Schedule next refresh at the start of the next ISO week (Monday 00:00).
        // TODO: Phase 4 — Use WidgetCenter.shared.reloadTimelines(ofKind:) from the app
        //   after a HealthKit background delivery triggers a data refresh.
        let timeline = Timeline(entries: [ChalkWidgetEntry.placeholder], policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Medium Home Screen Widget View

/// Renders the medium-size home-screen widget.
/// Phase 1: Placeholder view only.
struct ChalkMediumWidgetView: View {
    let entry: ChalkWidgetEntry

    var body: some View {
        VStack(spacing: 8) {
            // TODO: Phase 4 — Replace with HStack of per-category progress rings.
            Image(systemName: "dumbbell.fill")
                .font(.title2)
                .foregroundStyle(Color(red: 0.075, green: 0.357, blue: 0.925))
            Text("Chalk")
                .font(.headline)
            Text("Weekly goals coming in Phase 4")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Lock Screen Widget View

/// Renders the lock-screen (accessory) widget.
/// Phase 1: Placeholder view only.
struct ChalkLockScreenWidgetView: View {
    let entry: ChalkWidgetEntry

    var body: some View {
        // TODO: Phase 4 — Render compact circular or rectangular progress summary.
        Image(systemName: "dumbbell.fill")
            .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget Declarations

/// Medium home-screen widget (2-column, system medium family).
struct ChalkMediumWidget: Widget {
    let kind = SharedConstants.WidgetKind.medium

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ChalkWidgetProvider()) { entry in
            ChalkMediumWidgetView(entry: entry)
        }
        .configurationDisplayName("Chalk")
        .description("Track your weekly workout goals at a glance.")
        .supportedFamilies([.systemMedium])
    }
}

/// Lock-screen widget (circular and rectangular accessory families).
struct ChalkLockScreenWidget: Widget {
    let kind = SharedConstants.WidgetKind.lockScreen

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ChalkWidgetProvider()) { entry in
            ChalkLockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("Chalk")
        .description("Your workout progress at a glance.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

// MARK: - Widget Bundle

@main
struct ChalkWidgetBundle: WidgetBundle {
    var body: some Widget {
        ChalkMediumWidget()
        ChalkLockScreenWidget()
    }
}
