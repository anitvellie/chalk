// GoalCardView.swift
// Chalk — Goal Progress Card + Segmented Ring

import SwiftUI

// MARK: - Goal Card

/// A glass-morphism card showing one category's weekly progress.
/// Displays a segmented circular ring, tally count, and status label.
struct GoalCardView: View {

    let goal: WeeklyGoal

    private var categoryColor: Color { Color(hex: goal.category.colorHex) }

    var body: some View {
        VStack(spacing: 12) {

            // ── Header: icon chip + category name + completion badge ──
            HStack(spacing: 8) {
                Image(systemName: goal.category.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(categoryColor)
                    .frame(width: 28, height: 28)
                    .background(categoryColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text(goal.category.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer(minLength: 0)

                if goal.isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.system(size: 14))
                }
            }

            // ── Ring + count ──
            ZStack {
                SegmentedRingView(
                    completed: goal.completedCount,
                    target: goal.targetCount,
                    color: categoryColor
                )
                .frame(width: 84, height: 84)

                VStack(spacing: 0) {
                    Text("\(goal.completedCount)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(goal.isComplete ? .green : .primary)
                    Text("of \(goal.targetCount)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            // ── Status label ──
            Text(statusLabel)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(goal.isComplete ? Color.green : Color.secondary)
                .lineLimit(1)
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
        }
    }

    private var statusLabel: String {
        if goal.isComplete      { return "Goal complete!" }
        if goal.remaining == 1  { return "1 more this week" }
        return "\(goal.remaining) more this week"
    }
}

// MARK: - Segmented Ring

/// A circular progress indicator made of N discrete arc segments.
///
/// Each segment represents one session in the weekly target.
/// Completed segments are drawn in the category colour; pending ones in muted grey.
/// Segments are separated by a fixed 6° gap so individual arcs are always legible.
struct SegmentedRingView: View {

    let completed: Int
    let target: Int
    let color: Color
    var strokeWidth: CGFloat = 6.5

    var body: some View {
        Canvas { ctx, size in
            guard target > 0 else { return }

            let center    = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius    = min(size.width, size.height) / 2 - strokeWidth / 2
            let gapDeg    = 6.0
            let segDeg    = (360.0 - gapDeg * Double(target)) / Double(target)

            for i in 0 ..< target {
                let startDeg = -90.0 + Double(i) * (segDeg + gapDeg)
                let endDeg   = startDeg + segDeg

                var path = Path()
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(startDeg),
                    endAngle:   .degrees(endDeg),
                    clockwise: false
                )

                let segColor: Color = i < completed ? color : .gray.opacity(0.2)
                ctx.stroke(
                    path,
                    with: .color(segColor),
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
            }
        }
    }
}
