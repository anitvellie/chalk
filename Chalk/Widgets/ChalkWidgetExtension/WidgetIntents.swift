// WidgetIntents.swift
// Chalk — Widget Extension

import AppIntents
import WidgetKit

// MARK: - Enums

enum ColorModeAppEnum: String, AppEnum {
    case color
    case monochrome

    static var typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation(name: "Style")
    static var caseDisplayRepresentations: [ColorModeAppEnum: DisplayRepresentation] = [
        .color:      DisplayRepresentation(title: "Colour"),
        .monochrome: DisplayRepresentation(title: "Monochrome"),
    ]
}

enum DisplayStyleAppEnum: String, AppEnum {
    case numbered
    case wheel

    static var typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation(name: "Display")
    static var caseDisplayRepresentations: [DisplayStyleAppEnum: DisplayRepresentation] = [
        .numbered: DisplayRepresentation(title: "Numbered"),
        .wheel:    DisplayRepresentation(title: "Wheel"),
    ]
}

// MARK: - Intents

/// Single-goal small widget — user picks which goal to show and the colour style.
struct SelectGoalIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Goal"
    static var description = IntentDescription("Choose which goal to display.")

    @Parameter(title: "Goal")  var goal: GoalEntity?
    @Parameter(title: "Style") var colorMode: ColorModeAppEnum?
}

/// All-goals small widget — colour or monochrome style.
struct AllGoalsIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "All Goals"
    static var description = IntentDescription("Display all your goals.")

    @Parameter(title: "Style") var colorMode: ColorModeAppEnum?
}

/// Weekly medium widget — numbered or wheel progress, colour or monochrome.
struct WeeklyIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Weekly Progress"
    static var description = IntentDescription("Your weekly activity and goal progress.")

    @Parameter(title: "Display") var displayStyle: DisplayStyleAppEnum?
    @Parameter(title: "Style")   var colorMode: ColorModeAppEnum?
}
