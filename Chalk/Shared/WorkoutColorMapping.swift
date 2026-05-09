// WorkoutColorMapping.swift
// Chalk — Shared Layer
//
// Maps SF Symbol icon names to display colours.
// Compiled into both the app and widget extension so both targets derive
// colours from the same source without duplicating the switch statement.
// WorkoutCategory+Color.swift (app-only) forwards to this.

import SwiftUI

enum WorkoutColorMapping {

    static func color(for icon: String) -> Color {
        switch icon {

        // ── Strength & Core ──────────────────────────────────────────
        case "figure.strengthtraining.traditional",
             "figure.strengthtraining.functional",
             "figure.core.training":
            return Color(uiColor: .systemCyan)

        // ── Running & Wheels ─────────────────────────────────────────
        case "figure.run",
             "figure.roll",
             "figure.roll.runningpace":
            return Color(uiColor: .systemOrange)

        // ── Walking ──────────────────────────────────────────────────
        case "figure.walk":
            return Color(uiColor: .systemGreen)

        // ── Cycling ──────────────────────────────────────────────────
        case "figure.outdoor.cycle",
             "figure.indoor.cycle",
             "figure.hand.cycling":
            return Color(uiColor: .systemBlue)

        // ── HIIT & Jump Rope ─────────────────────────────────────────
        case "figure.highintensity.intervaltraining",
             "figure.jumprope":
            return Color(uiColor: .systemYellow)

        // ── Mind, Body & Recovery ────────────────────────────────────
        case "figure.yoga",
             "figure.mind.and.body",
             "figure.pilates",
             "figure.barre",
             "figure.flexibility",
             "figure.taichi",
             "figure.cooldown":
            return Color(uiColor: .systemPink)

        // ── Swimming & Water Sports ──────────────────────────────────
        case "figure.pool.swim",
             "figure.open.water.swim",
             "figure.water.fitness",
             "figure.water.polo":
            return Color(uiColor: .systemTeal)

        // ── Rowing ───────────────────────────────────────────────────
        case "figure.indoor.rowing":
            return Color(uiColor: .systemIndigo)

        // ── Combat Sports ────────────────────────────────────────────
        case "figure.boxing",
             "figure.kickboxing",
             "figure.martial.arts",
             "figure.wrestling",
             "figure.fencing":
            return Color(uiColor: .systemRed)

        // ── Racquet & Paddle Sports ──────────────────────────────────
        case "figure.tennis",
             "figure.badminton",
             "figure.squash",
             "figure.racquetball",
             "figure.table.tennis",
             "figure.pickleball":
            return Color(uiColor: .systemGreen)

        // ── Team & Ball Sports ───────────────────────────────────────
        case "figure.soccer",
             "figure.basketball",
             "figure.volleyball",
             "figure.handball",
             "figure.rugby",
             "figure.american.football",
             "figure.australian.football",
             "figure.baseball",
             "figure.softball",
             "figure.cricket",
             "figure.lacrosse":
            return Color(uiColor: .systemOrange)

        // ── Ice & Snow Sports ────────────────────────────────────────
        case "figure.skiing.downhill",
             "figure.skiing.crosscountry",
             "figure.snowboarding",
             "figure.curling",
             "figure.skating",
             "figure.hockey":
            return Color(uiColor: .systemBlue)

        // ── Outdoor & Adventure ──────────────────────────────────────
        case "figure.hiking",
             "figure.climbing",
             "figure.surfing",
             "figure.sailing",
             "figure.fishing",
             "figure.hunting",
             "figure.disc.sports":
            return Color(uiColor: .systemGreen)

        // ── General Cardio & Training ────────────────────────────────
        case "figure.elliptical",
             "figure.mixed.cardio",
             "figure.cross.training",
             "figure.stair.stepper",
             "figure.stairs",
             "figure.step.training":
            return Color(uiColor: .systemOrange)

        // ── Dance & Performance ──────────────────────────────────────
        case "figure.dance",
             "figure.gymnastics",
             "figure.archery",
             "figure.track.and.field":
            return Color(uiColor: .systemPurple)

        // ── Country & Leisure ────────────────────────────────────────
        case "figure.equestrian.sports",
             "figure.golf",
             "figure.bowling":
            return Color(uiColor: .systemBrown)

        default:
            return Color(uiColor: .systemPurple)
        }
    }
}
