// WidgetProviders.swift
// Chalk — Widget Extension

import WidgetKit
import SwiftUI

// MARK: - Timeline entries
// Each widget bakes its configuration into the entry so the view receives a
// single, fully-resolved value object with no additional intent look-up needed.

struct SingleGoalEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
    let selectedGoalId: UUID?
    let isMonochrome: Bool
}

struct AllGoalsEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
    let isMonochrome: Bool
}

struct WeeklyEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
    let isMonochrome: Bool
    let isWheel: Bool
}

// MARK: - Shared helpers

private func loadSnapshot() -> WidgetSnapshot {
    guard let store = UserDefaults(suiteName: SharedConstants.appGroupIdentifier),
          let data = store.data(forKey: SharedConstants.UserDefaultsKey.widgetSnapshot),
          let snap = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else {
        return .placeholder
    }
    return snap
}

private func nextMidnight() -> Date {
    Calendar.current.startOfDay(for: Date().addingTimeInterval(86_400))
}

// MARK: - Single Goal provider

struct SingleGoalProvider: AppIntentTimelineProvider {
    typealias Entry = SingleGoalEntry
    typealias Intent = SelectGoalIntent

    func placeholder(in context: Context) -> SingleGoalEntry {
        SingleGoalEntry(date: .now, snapshot: .placeholder, selectedGoalId: nil, isMonochrome: false)
    }

    func snapshot(for configuration: SelectGoalIntent, in context: Context) async -> SingleGoalEntry {
        SingleGoalEntry(date: .now, snapshot: loadSnapshot(),
                        selectedGoalId: configuration.goal.flatMap { UUID(uuidString: $0.id) },
                        isMonochrome: configuration.colorMode == .monochrome)
    }

    func timeline(for configuration: SelectGoalIntent, in context: Context) async -> Timeline<SingleGoalEntry> {
        let entry = SingleGoalEntry(date: .now, snapshot: loadSnapshot(),
                                    selectedGoalId: configuration.goal.flatMap { UUID(uuidString: $0.id) },
                                    isMonochrome: configuration.colorMode == .monochrome)
        return Timeline(entries: [entry], policy: .after(nextMidnight()))
    }
}

// MARK: - All Goals provider

struct AllGoalsProvider: AppIntentTimelineProvider {
    typealias Entry = AllGoalsEntry
    typealias Intent = AllGoalsIntent

    func placeholder(in context: Context) -> AllGoalsEntry {
        AllGoalsEntry(date: .now, snapshot: .placeholder, isMonochrome: false)
    }

    func snapshot(for configuration: AllGoalsIntent, in context: Context) async -> AllGoalsEntry {
        AllGoalsEntry(date: .now, snapshot: loadSnapshot(),
                      isMonochrome: configuration.colorMode == .monochrome)
    }

    func timeline(for configuration: AllGoalsIntent, in context: Context) async -> Timeline<AllGoalsEntry> {
        let entry = AllGoalsEntry(date: .now, snapshot: loadSnapshot(),
                                  isMonochrome: configuration.colorMode == .monochrome)
        return Timeline(entries: [entry], policy: .after(nextMidnight()))
    }
}

// MARK: - Weekly provider

struct WeeklyProvider: AppIntentTimelineProvider {
    typealias Entry = WeeklyEntry
    typealias Intent = WeeklyIntent

    func placeholder(in context: Context) -> WeeklyEntry {
        WeeklyEntry(date: .now, snapshot: .placeholder, isMonochrome: false, isWheel: false)
    }

    func snapshot(for configuration: WeeklyIntent, in context: Context) async -> WeeklyEntry {
        WeeklyEntry(date: .now, snapshot: loadSnapshot(),
                    isMonochrome: configuration.colorMode == .monochrome,
                    isWheel: configuration.displayStyle == .wheel)
    }

    func timeline(for configuration: WeeklyIntent, in context: Context) async -> Timeline<WeeklyEntry> {
        let entry = WeeklyEntry(date: .now, snapshot: loadSnapshot(),
                                isMonochrome: configuration.colorMode == .monochrome,
                                isWheel: configuration.displayStyle == .wheel)
        return Timeline(entries: [entry], policy: .after(nextMidnight()))
    }
}
