// WorkoutCircleIcon.swift
// Chalk — Shared Layer
// Compiled into both the app and widget extension.
//
// Single rendering of a workout's circular SF Symbol icon (e.g.
// "figure.run.circle.fill"), used by the weekly strip and the monthly
// calendar so every workout icon looks identical.

import SwiftUI

struct WorkoutCircleIcon: View {

    /// SF Symbol base name (without the ".circle.fill" suffix).
    let icon: String
    let isMonochrome: Bool
    let size: CGFloat

    var body: some View {
        Image(systemName: "\(icon).circle.fill")
            .resizable()
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(isMonochrome
                ? AnyShapeStyle(Self.monochromeGradient)
                : AnyShapeStyle(WorkoutColorMapping.color(for: icon).gradient))
            .frame(width: size, height: size)
    }

    static let monochromeGradient = LinearGradient(
        colors: [Color(white: 0.28), Color(white: 0.18)],
        startPoint: .top,
        endPoint: .bottom
    )
}
