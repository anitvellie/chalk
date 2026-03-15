# Chalk — Project Intelligence File

## What is Chalk?
A native iOS app that helps users track weekly workout goals by pulling data from Apple HealthKit (sourced from Strong, Strava, NRC, Apple Fitness, etc.). Users define workout categories and weekly targets; the app counts completions automatically.

The name "Chalk" references gym chalk and the tradition of chalking up tally marks — a satisfying, physical metaphor for logging progress.

## Current Status
- Phase 1: ✅ Complete
- Phase 2: ✅ Complete
- Phase 3: In progress

## Phases
- [x] Phase 1 — Project scaffold, data models, target setup
- [x] Phase 2 — HealthKit integration
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
- `WorkoutCategory`: id, name, icon (SF Symbol name), colorHex (String), targetPerWeek (Int), activityTypeRawValues ([Int])
- `WorkoutEntry`: id, categoryId (UUID ref), date, duration, source (WorkoutSource enum), externalId (UUID?)
- `WeeklyGoal`: derived struct — never persisted; computed from WorkoutEntry records for current ISO week

## Default Goals (updated from original spec)
Upper Body and Legs were **merged into a single Strength category** because both map to
`HKWorkoutActivityType.traditionalStrengthTraining` in HealthKit with no reliable way to
distinguish them from workout metadata. Current defaults:

- **Strength**: 4x/week → HK `.traditionalStrengthTraining` + `.functionalStrengthTraining`
- **Running**: 3x/week → HK `.running`
- **Yoga**: 1x/week → HK `.yoga` + `.mindAndBody`

## Decisions Made

### Data model
- `WorkoutCategory.colorHex` stored as hex String (e.g. `"#135bec"`) — convert to SwiftUI `Color` via `Color(hex:)` in view layer only
- `WorkoutEntry.categoryId` is a UUID reference, not an embedded object
- `WorkoutSource` is an enum: `.healthKit` / `.manual`
- `activityTypeRawValues: [Int]` stores `HKWorkoutActivityType.rawValue` — keeps Models layer free of HealthKit import
- `WeeklyGoal` is derived and never persisted; always recomputed from entries
- Week = ISO 8601 (Monday–Sunday) via `Calendar.iso8601`

### HealthKit
- HealthKit is **read-only** — no writing back
- `HealthKitManager` is the **sole file** that imports HealthKit; all other layers are HK-free
- HK activity type raw values are populated via `HealthKitManager.defaultCategories` (resolves from `HKWorkoutActivityType.case.rawValue`) — never hardcoded in model layer
- A single `HKWorkoutType` authorisation request covers all activity types; no per-category request needed
- Background delivery is **implemented** in `HealthKitManager.enableBackgroundDelivery()` but **not yet activated** — wire it up in Phase 4 alongside widget timeline refreshes; requires "Background Delivery" sub-capability in Xcode

### Persistence
- **Categories**: JSON-encoded to App Group UserDefaults; falls back to `UserDefaults.standard` when App Group is not yet configured (safe for development before signing is finalised)
- **WorkoutEntries**: not cached — fetched fresh from HealthKit on every `refreshGoals()` call
- **WeeklyGoals**: never stored; derived on the fly

### Project generation
- `project.yml` (xcodegen 2.25) is the source of truth for the Xcode project
- **Always edit `project.yml`, then run `xcodegen generate`** — never edit `.xcodeproj` directly
- Entitlements are declared in `project.yml` under `entitlements.properties` — editing `.entitlements` files directly is pointless because xcodegen overwrites them on every regeneration
- DEVELOPMENT_TEAM lives in `Config/DevelopmentTeam.xcconfig` (gitignored) — see `Config/DevelopmentTeam.xcconfig.example`

### Manual logging
- Supported in a later phase (Phase 3+)

## Phase 3 Starting Point
`ContentView` in `ChalkApp.swift` is currently a **temporary Phase 2 debug harness** (goal list + pull-to-refresh). Phase 3 replaces it entirely with the real bottom-tab navigation shell:
- Bottom tab bar: Home, Stats, History, Profile
- Centered floating Add button
- `AppState` already exposes `categories`, `weeklyGoals`, `isLoading`, `errorMessage`, `refreshGoals()`, `setupHealthKit()`
- Category management stubs in `AppState` are ready to be implemented: `addCategory`, `deleteCategory`, `updateCategory`

## Version Control
- Git is used from day one
- Default branch: `main`
- Commit style: conventional commits (feat:, chore:, fix:, docs:)
- Branch strategy: feature branches for each phase (e.g. `phase/1-scaffold`, `phase/2-healthkit`)
- Never force push to main
- Repo is private on GitHub: https://github.com/anitvellie/chalk
- Claude Code should make small decisions independently; align on bigger architectural decisions and commits

## Folder Structure
```
Chalk/                              ← git repo root
├── project.yml                     ← xcodegen spec (source of truth for .xcodeproj)
├── Config/
│   ├── DevelopmentTeam.xcconfig.example
│   └── DevelopmentTeam.xcconfig    ← gitignored; set DEVELOPMENT_TEAM here
├── Chalk/                          ← iOS app sources
│   ├── App/
│   │   ├── ChalkApp.swift          ← @main entry + Color(hex:) utility + ContentView (temp Phase 2 harness)
│   │   └── AppState.swift          ← central @MainActor ObservableObject
│   ├── Models/
│   │   ├── WorkoutCategory.swift
│   │   ├── WorkoutEntry.swift      ← includes WorkoutSource enum
│   │   └── WeeklyGoal.swift        ← includes Calendar.iso8601 extension
│   ├── Features/                   ← empty; Phase 3 fills these in
│   │   ├── Home/
│   │   ├── Stats/
│   │   ├── History/
│   │   └── Goals/
│   ├── HealthKit/
│   │   └── HealthKitManager.swift  ← sole HealthKit importer; includes defaultCategories seed data
│   ├── Shared/
│   │   └── SharedConstants.swift   ← App Group ID, UserDefaults keys, WidgetKind; compiled into app + widget
│   ├── Widgets/
│   │   └── ChalkWidgetExtension/
│   │       └── ChalkWidgetExtension.swift  ← Phase 1 stub; implement in Phase 4
│   ├── Assets.xcassets             ← AccentColor (#135bec), AppIcon stub
│   ├── Chalk.entitlements          ← generated by xcodegen; edit via project.yml not directly
│   └── Design/                     ← mockup PNGs (add manually)
├── ChalkWatch/                     ← watchOS placeholder; Phase 5
│   └── ChalkWatchApp.swift
└── Chalk.xcodeproj/                ← generated by xcodegen; commit it but don't edit directly
```
