// SingleGoalWidgetView.swift
// Chalk — Widget Extension
//
// Small widget: one large progress ring filling the widget.
// Icon + "2/3" count centred inside the ring.
// User picks which goal to display via SelectGoalIntent.

import SwiftUI
import WidgetKit

struct SingleGoalWidgetView: View {

    let entry: SingleGoalEntry

    private var goal: GoalSnapshot? {
        if let id = entry.selectedGoalId {
            return entry.snapshot.goals.first(where: { $0.id == id })
        }
        return entry.snapshot.goals.first
    }

    var body: some View {
        Group {
            if let goal {
                SingleGoalRingView(goal: goal, isMonochrome: entry.isMonochrome)
            } else {
                Text("Open Chalk to set up goals")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Ring view

struct SingleGoalRingView: View {

    let goal: GoalSnapshot
    let isMonochrome: Bool

    private var ringColor: Color {
        isMonochrome ? Color(white: 0.22) : WorkoutColorMapping.color(for: goal.icon)
    }

    var body: some View {
        ZStack {
            WidgetRingCanvas(progress: goal.progress, color: ringColor, strokeWidth: 11)
                .padding(10)

            VStack(spacing: 3) {
                if isMonochrome {
                    Image(systemName: goal.icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(colors: [Color(white: 0.28), Color(white: 0.18)],
                                           startPoint: .top, endPoint: .bottom)
                        )
                } else {
                    Image(systemName: goal.icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(WorkoutColorMapping.color(for: goal.icon))
                }

                Text("\(goal.completed)/\(goal.target)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(isMonochrome ? Color(white: 0.20) : .primary)
            }
        }
    }
}

// MARK: - Shared ring canvas (reused by WeeklyWidgetView wheel panels)

struct WidgetRingCanvas: View {

    let progress: Double
    let color: Color
    var strokeWidth: CGFloat = 9

    var body: some View {
        Canvas { ctx, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - strokeWidth / 2

            var track = Path()
            track.addArc(center: center, radius: radius,
                         startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
            ctx.stroke(track, with: .color(.gray.opacity(0.15)),
                       style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))

            guard progress > 0 else { return }
            var arc = Path()
            arc.addArc(center: center, radius: radius,
                       startAngle: .degrees(-90), endAngle: .degrees(-90 + progress * 360), clockwise: false)
            ctx.stroke(arc, with: .color(color),
                       style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
        }
    }
}
