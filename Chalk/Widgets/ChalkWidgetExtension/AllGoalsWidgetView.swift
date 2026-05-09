// AllGoalsWidgetView.swift
// Chalk — Widget Extension
//
// Small widget: up to 4 goals, each as icon + "X/Y" count.
// Colour mode: category colours (default) or charcoal-gradient monochrome.

import SwiftUI
import WidgetKit

struct AllGoalsWidgetView: View {

    let entry: AllGoalsEntry

    private var goals: [GoalSnapshot] { Array(entry.snapshot.goals.prefix(4)) }

    var body: some View {
        Group {
            if goals.isEmpty {
                Text("Open Chalk to set up goals")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding()
            } else {
                VStack(alignment: .leading, spacing: rowSpacing) {
                    ForEach(goals) { goal in
                        GoalRowView(goal: goal,
                                    isMonochrome: entry.isMonochrome,
                                    iconSize: iconSize,
                                    fontSize: fontSize)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .padding(14)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var rowSpacing: CGFloat {
        switch goals.count {
        case 1, 2: return 14
        case 3:    return 10
        default:   return 7
        }
    }

    private var iconSize: CGFloat {
        goals.count <= 2 ? 28 : goals.count == 3 ? 24 : 20
    }

    private var fontSize: CGFloat {
        goals.count <= 2 ? 22 : goals.count == 3 ? 18 : 15
    }
}

// MARK: - Goal row

private struct GoalRowView: View {

    let goal: GoalSnapshot
    let isMonochrome: Bool
    let iconSize: CGFloat
    let fontSize: CGFloat

    var body: some View {
        HStack(spacing: 10) {
            icon
            countText
        }
    }

    @ViewBuilder
    private var icon: some View {
        if isMonochrome {
            Image(systemName: "\(goal.icon).circle.fill")
                .resizable()
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(charcoalGradient)
                .frame(width: iconSize, height: iconSize)
        } else {
            Image(systemName: "\(goal.icon).circle.fill")
                .resizable()
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(WorkoutColorMapping.color(for: goal.icon).gradient)
                .frame(width: iconSize, height: iconSize)
        }
    }

    @ViewBuilder
    private var countText: some View {
        if isMonochrome {
            Text("\(goal.completed)/\(goal.target)")
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundStyle(Color(white: 0.20))
        } else {
            Text("\(goal.completed)/\(goal.target)")
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
                .foregroundStyle(WorkoutColorMapping.color(for: goal.icon))
        }
    }

    private var charcoalGradient: LinearGradient {
        LinearGradient(
            colors: [Color(white: 0.28), Color(white: 0.18)],
            startPoint: .top, endPoint: .bottom
        )
    }
}
