// StripDayIconArea.swift
// Chalk — Shared Layer
// Compiled into both the app and widget extension.

import SwiftUI

/// Renders the icon slot for one day column in the weekly activity strip.
/// - 0 workouts: day-of-month number
/// - 1 workout: single circle icon
/// - 2 workouts: overlapping stack (top over bottom, separator circle plugs the SF Symbol cutout)
/// - 3+: overlapping stack + red badge with total count
///
/// `iconSize` drives all proportional sizing; use 37 for the app strip and 20 for the widget strip.
struct StripDayIconArea: View {

    let icons: [String]     // SF Symbol base names, sorted longest-duration first
    let isMonochrome: Bool
    let iconSize: CGFloat
    let emptyText: String   // day-of-month shown when icons is empty
    let textColor: Color

    var body: some View {
        switch icons.count {
        case 0:
            Text(emptyText)
                .font(.system(size: scale * 14, weight: .medium))
                .foregroundStyle(textColor)
                .frame(width: iconSize, height: iconSize, alignment: .center)
        case 1:
            circleIcon(icons[0])
        case 2:
            stackedIcons(top: icons[0], bottom: icons[1])
        default:
            stackedIcons(top: icons[0], bottom: icons[1])
                .overlay(alignment: .topTrailing) {
                    overflowBadge(count: icons.count)
                        .offset(x: scale * 6, y: scale * 14)
                }
        }
    }

    // MARK: - Sub-views

    @ViewBuilder
    private func circleIcon(_ icon: String) -> some View {
        if isMonochrome {
            Image(systemName: "\(icon).circle.fill")
                .resizable()
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(monochromeGradient)
                .frame(width: iconSize, height: iconSize)
        } else {
            Image(systemName: "\(icon).circle.fill")
                .resizable()
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(WorkoutColorMapping.color(for: icon).gradient)
                .frame(width: iconSize, height: iconSize)
        }
    }

    private func stackedIcons(top: String, bottom: String) -> some View {
        VStack(spacing: -(scale * 13)) {
            circleIcon(top)
            ZStack {
                // Covers the SF Symbol's transparent inner cutout so the bottom
                // icon's colour doesn't bleed through the top icon.
                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: scale * 31, height: scale * 31)
                circleIcon(bottom)
            }
        }
    }

    private func overflowBadge(count: Int) -> some View {
        ZStack {
            Circle().fill(Color.red)
            Text("\(count)")
                .font(.system(size: max(8, scale * 11), weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: max(15, scale * 23), height: max(15, scale * 23))
    }

    // MARK: - Sizing

    private var scale: CGFloat { iconSize / 36 }

    private var monochromeGradient: LinearGradient {
        LinearGradient(
            colors: [Color(white: 0.28), Color(white: 0.18)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
