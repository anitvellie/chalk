// ChalkWidgetExtension.swift
// Chalk — Widget Extension entry point

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Widget declarations

struct SingleGoalWidget: Widget {
    let kind = SharedConstants.WidgetKind.singleGoal

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectGoalIntent.self,
            provider: SingleGoalProvider()
        ) { entry in
            SingleGoalWidgetView(entry: entry)
        }
        .configurationDisplayName("Single Goal")
        .description("Track one specific workout goal at a glance.")
        .supportedFamilies([.systemSmall])
    }
}

struct AllGoalsWidget: Widget {
    let kind = SharedConstants.WidgetKind.allGoals

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: AllGoalsIntent.self,
            provider: AllGoalsProvider()
        ) { entry in
            AllGoalsWidgetView(entry: entry)
        }
        .configurationDisplayName("All Goals")
        .description("See all your weekly workout goals. Up to 4 goals shown.")
        .supportedFamilies([.systemSmall])
    }
}

struct WeeklyWidget: Widget {
    let kind = SharedConstants.WidgetKind.weekly

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: WeeklyIntent.self,
            provider: WeeklyProvider()
        ) { entry in
            WeeklyWidgetView(entry: entry)
        }
        .configurationDisplayName("Weekly Progress")
        .description("Your weekly activity strip and goal progress.")
        .supportedFamilies([.systemMedium])
    }
}

// MARK: - Bundle

@main
struct ChalkWidgetBundle: WidgetBundle {
    var body: some Widget {
        SingleGoalWidget()
        AllGoalsWidget()
        WeeklyWidget()
    }
}
