# Chalk — Project Intelligence File

## What is Chalk?
A native iOS app that helps users track weekly workout goals by pulling data from Apple HealthKit (sourced from Strong, Strava, NRC, Apple Fitness, etc.). Users define workout categories and weekly targets; the app counts completions automatically.

The name "Chalk" references gym chalk and the tradition of chalking up tally marks — a satisfying, physical metaphor for logging progress.

## Current Status
- Phase 1: Scaffold in progress

## Phases
- [ ] Phase 1 — Project scaffold, data models, target setup
- [ ] Phase 2 — HealthKit integration
- [ ] Phase 3 — Core UI (home screen, weekly overview, goal creation)
- [ ] Phase 4 — Widgets (home screen + lock screen via WidgetKit)
- [ ] Phase 5 — watchOS companion app

## Tech Constraints (non-negotiable)
- SwiftUI only — no UIKit
- iOS 17+ minimum deployment target
- No third-party dependencies — pure Apple frameworks only
- WidgetKit for both medium home screen widget and lock screen widget
- watchOS target to be added in Phase 5, but architecture must support it from day one
- Data sharing between app and widget via App Groups + UserDefaults (or SwiftData if appropriate)

## Design Language
- Primary color: #135bec
- Background light: #f6f6f8 / Background dark: #101622
- Dark mode base should evoke a chalkboard: deep slate (~#1a1f2e), not pure black
- Typography: SF Pro (system font) — use a chalk-style display font for headings only if it doesn't hurt legibility; SF Pro for all UI text
- Visual motifs: tally marks as progress metaphor, subtle chalkboard texture in dark mode
- Glass morphism cards: frosted white/dark backgrounds with subtle borders
- Segmented progress rings per category (circular progress, SVG-style)
- Bottom tab bar: Home, Stats, History, Profile + centered floating add button
- Refer to /Design/ folder for screen mockups (widget, weekly overview, goal creation)

## Data Model (agreed)
- `WorkoutCategory`: id, name, icon (SF Symbol name), color, targetPerWeek (Int), HKWorkoutActivityType mappings
- `WorkoutEntry`: id, category, date, duration, source (healthKit / manual), externalId
- `WeeklyGoal`: derived — count of WorkoutEntries per category in current ISO week

## User's Default Goals (for seeding / onboarding)
- Upper Body: 2x/week → maps to HK traditionalStrengthTraining / functionalStrengthTraining
- Legs: 2x/week → maps to HK traditionalStrengthTraining (filtered by name) / cycling
- Running: 3x/week → maps to HK running
- Yoga: 1x/week → maps to HK yoga / mindAndBody

## Decisions Made
- Week = ISO week (Monday–Sunday)
- HealthKit is read-only (no writing back)
- Manual logging will be supported in a later phase
- Claude Code should ask before making any architectural decision not covered in this file

## Version Control
- Git is used from day one
- Default branch: `main`
- Commit style: conventional commits (feat:, chore:, fix:, docs:)
- Claude Code should suggest logical commit points and ask before committing
- Branch strategy: feature branches for each phase (e.g. `phase/1-scaffold`, `phase/2-healthkit`)
- Never force push to main
- Repo is private on GitHub

## Folder Structure (target)
```
Chalk/
├── App/
│   ├── ChalkApp.swift
│   └── AppState.swift
├── Models/
│   ├── WorkoutCategory.swift
│   ├── WorkoutEntry.swift
│   └── WeeklyGoal.swift
├── Features/
│   ├── Home/
│   ├── Stats/
│   ├── History/
│   └── Goals/
├── HealthKit/
│   └── HealthKitManager.swift
├── Widgets/
│   └── ChalkWidgetExtension/
├── Shared/
│   └── (shared models/utilities for App Group)
└── Design/
    └── (mockup PNGs for reference)
```
