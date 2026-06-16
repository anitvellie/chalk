// Theme.swift
// Chalk — Shared UI theme primitives
//
// Single source of truth for cross-feature visual styling: the glass card
// surface (Home goal cards, weekly strip, History calendar) and the
// past/today/future day colouring used by every calendar-style view.

import SwiftUI

// MARK: - Glass Card

/// The frosted "glass" card surface used across the app (goal cards, weekly
/// strip, monthly calendar). Edit here to change every card at once.
struct GlassCardModifier: ViewModifier {
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

extension View {
    /// Applies Chalk's standard glass card surface.
    func glassCard() -> some View { modifier(GlassCardModifier()) }
}

// MARK: - Day Relation Colouring

/// Where a calendar day sits relative to today. Drives the day-number colour
/// in both the weekly strip and the monthly calendar so the rule lives in one
/// place: today is primary (black in light mode), past days are light grey,
/// upcoming days are a medium grey.
enum DayRelation {
    case past, today, future

    init(day: Date, relativeTo today: Date, calendar: Calendar = .current) {
        let d = calendar.startOfDay(for: day)
        let t = calendar.startOfDay(for: today)
        if d < t { self = .past }
        else if d == t { self = .today }
        else { self = .future }
    }

    /// Colour for the day-of-month number when no workout icon is shown.
    var textColor: Color {
        switch self {
        case .today:  return .primary
        case .past:   return Color(hex: "#D6D6D6")
        case .future: return Color(hex: "#898989")
        }
    }
}
