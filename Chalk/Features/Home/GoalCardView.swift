// GoalCardView.swift
// Chalk — Goal Progress Card + Continuous Ring

import SwiftUI

// MARK: - Goal Card

struct GoalCardView: View {

    let goal: WeeklyGoal

    private var categoryColor: Color { Color(hex: goal.category.colorHex) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // ── Header: category name + SF symbol icon (top-right) ──
            HStack(alignment: .top) {
                Text(goal.category.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer(minLength: 4)

                Image(systemName: goal.category.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(categoryColor)
            }

            // ── Ring + count (centred) ──
            ZStack {
                ContinuousRingView(
                    completed: goal.completedCount,
                    target: goal.targetCount,
                    color: categoryColor
                )
                .frame(width: 90, height: 90)

                VStack(spacing: 1) {
                    Text("\(goal.completedCount)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("out of \(goal.targetCount)")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .modifier(GlassCardModifier())
    }
}

// MARK: - Glass Card Modifier

private struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .glassEffect(in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        } else {
            content
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
                }
        }
    }
}

// MARK: - Continuous Ring

/// A single continuous arc showing progress against a target.
/// The track is drawn as a full circle in muted grey; the progress arc
/// overlays it in the category colour with rounded caps.
struct ContinuousRingView: View {

    let completed: Int
    let target: Int
    let color: Color
    var strokeWidth: CGFloat = 9.0

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(completed) / Double(target), 1.0)
    }

    var body: some View {
        Canvas { ctx, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - strokeWidth / 2

            // Track
            var trackPath = Path()
            trackPath.addArc(
                center: center,
                radius: radius,
                startAngle: .degrees(0),
                endAngle: .degrees(360),
                clockwise: false
            )
            ctx.stroke(
                trackPath,
                with: .color(.gray.opacity(0.15)),
                style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
            )

            // Progress arc
            guard progress > 0 else { return }
            var progressPath = Path()
            progressPath.addArc(
                center: center,
                radius: radius,
                startAngle: .degrees(-90),
                endAngle: .degrees(-90 + progress * 360),
                clockwise: false
            )
            ctx.stroke(
                progressPath,
                with: .color(color),
                style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
            )
        }
    }
}
