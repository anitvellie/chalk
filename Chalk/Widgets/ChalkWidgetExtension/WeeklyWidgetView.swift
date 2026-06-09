// WeeklyWidgetView.swift
// Chalk — Widget Extension
//
// Medium widget: goals panel on the left, 7-day activity strip on the right.
// Left panel style: numbered (icon + X/Y count per goal) or wheel (progress rings).
// Colour mode: category colours or charcoal monochrome.

import SwiftUI
import WidgetKit

// MARK: - Root

struct WeeklyWidgetView: View {

    let entry: WeeklyEntry

    private var goals: [GoalSnapshot] { Array(entry.snapshot.goals.prefix(4)) }

    var body: some View {
        HStack(spacing: 0) {
            GoalsPanelView(goals: goals,
                           isMonochrome: entry.isMonochrome,
                           isWheel: entry.isWheel)

            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(width: 0.5)
                .padding(.vertical, 6)
                .padding(.leading, 10)

            WeeklyStripView(weekDays: entry.snapshot.weekDays,
                            isMonochrome: entry.isMonochrome)
                .frame(maxWidth: .infinity)
                .padding(.leading, 6)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Goals panel (left side)

private struct GoalsPanelView: View {

    let goals: [GoalSnapshot]
    let isMonochrome: Bool
    let isWheel: Bool

    var body: some View {
        if isWheel {
            WheelPanelView(goals: Array(goals.prefix(2)), isMonochrome: isMonochrome)
        } else {
            NumberedPanelView(goals: goals, isMonochrome: isMonochrome)
        }
    }
}

// MARK: Numbered panel

private struct NumberedPanelView: View {

    let goals: [GoalSnapshot]
    let isMonochrome: Bool

    private var rowSpacing: CGFloat {
        switch goals.count {
        case 1, 2: return 12
        case 3:    return 8
        default:   return 5
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: rowSpacing) {
            ForEach(goals) { goal in
                PanelGoalRow(goal: goal, isMonochrome: isMonochrome)
            }
        }
        .frame(maxHeight: .infinity, alignment: .leading)
        .padding(.trailing, 0)
    }
}

private struct PanelGoalRow: View {

    let goal: GoalSnapshot
    let isMonochrome: Bool

    private let iconSize: CGFloat = 20

    var body: some View {
        HStack(spacing: 6) {
            iconView
            countText
        }
    }

    @ViewBuilder
    private var iconView: some View {
        if isMonochrome {
            Image(systemName: goal.icon)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundStyle(charcoalGradient)
                .frame(width: iconSize, height: iconSize)
        } else {
            Image(systemName: goal.icon)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundStyle(WorkoutColorMapping.color(for: goal.icon))
                .frame(width: iconSize, height: iconSize)
        }
    }

    @ViewBuilder
    private var countText: some View {
        if isMonochrome {
            Text("\(goal.completed)/\(goal.target)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Color(white: 0.20))
        } else {
            Text("\(goal.completed)/\(goal.target)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(WorkoutColorMapping.color(for: goal.icon))
        }
    }

    private var charcoalGradient: LinearGradient {
        LinearGradient(colors: [Color(white: 0.28), Color(white: 0.18)], startPoint: .top, endPoint: .bottom)
    }
}

// MARK: Wheel panel (max 2 goals)

private struct WheelPanelView: View {

    let goals: [GoalSnapshot]  // already capped at 2 by caller
    let isMonochrome: Bool

    var body: some View {
        VStack(spacing: 8) {
            ForEach(goals) { goal in
                SmallRingView(goal: goal, isMonochrome: isMonochrome)
            }
        }
        .frame(maxHeight: .infinity, alignment: .leading)
        .padding(.trailing, 4)
    }
}

private struct SmallRingView: View {

    let goal: GoalSnapshot
    let isMonochrome: Bool

    private var ringColor: Color {
        isMonochrome ? Color(white: 0.22) : WorkoutColorMapping.color(for: goal.icon)
    }

    private let diameter: CGFloat = 52

    var body: some View {
        ZStack {
            WidgetRingCanvas(progress: goal.progress, color: ringColor, strokeWidth: 6)
                .frame(width: diameter, height: diameter)

            VStack(spacing: 1) {
                Image(systemName: goal.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(ringColor)

                Text("\(goal.completed)/\(goal.target)")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(isMonochrome ? Color(white: 0.22) : .primary)
            }
        }
    }
}

// MARK: - Weekly strip (right side)

private struct WeeklyStripView: View {

    let weekDays: [DaySnapshot]
    let isMonochrome: Bool

    var body: some View {
        GeometryReader { geo in
            let iconSize = geo.size.width / 7 * 0.75
            HStack(alignment: .bottom, spacing: 0) {
                if weekDays.isEmpty {
                    // Placeholder columns when no snapshot exists yet
                    ForEach(0..<7, id: \.self) { _ in
                        StripDayColumn(daySnapshot: nil, isMonochrome: isMonochrome,
                                       today: Calendar.current.startOfDay(for: Date()),
                                       iconSize: iconSize)
                    }
                } else {
                    ForEach(weekDays, id: \.date) { day in
                        StripDayColumn(daySnapshot: day, isMonochrome: isMonochrome,
                                       today: Calendar.current.startOfDay(for: Date()),
                                       iconSize: iconSize)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}

private struct StripDayColumn: View {

    let daySnapshot: DaySnapshot?
    let isMonochrome: Bool
    let today: Date
    let iconSize: CGFloat

    private enum Relation { case past, today, future }

    private var day: Date { daySnapshot?.date ?? today }

    private var relation: Relation {
        if day < today { return .past }
        if day == today { return .today }
        return .future
    }

    private var textColor: Color {
        switch relation {
        case .today:  return .primary
        case .past:   return Color(white: 0.84)
        case .future: return Color(white: 0.54)
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            StripDayIconArea(
                icons: daySnapshot?.workoutIcons ?? [],
                isMonochrome: isMonochrome,
                iconSize: iconSize,
                emptyText: dayNumber,
                textColor: textColor
            )
            Text(dayLetter)
                .font(.system(size: 10, weight: relation == .today ? .semibold : .regular))
                .foregroundStyle(textColor)
        }
        .frame(maxWidth: .infinity)
    }

    private var dayLetter: String { DateFormatter.narrowWeekday.string(from: day) }
    private var dayNumber: String { DateFormatter.dayOfMonth.string(from: day) }
}

// MARK: - Date formatters (local to this file)

private extension DateFormatter {
    static let narrowWeekday: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "EEEEE"; return f
    }()
    static let dayOfMonth: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "d"; return f
    }()
}
