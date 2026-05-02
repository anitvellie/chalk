# Chalk

A native iOS app for tracking weekly workout goals using Apple HealthKit. Set targets for the workouts you care about — Chalk counts completions automatically by reading from Strong, Strava, Nike Run Club, Apple Fitness, and any other app that writes to Health.

The name references gym chalk and the tradition of chalking up tally marks: a satisfying, physical metaphor for logging progress.

---

## What it does

- Pulls workout data from HealthKit (read-only — never writes back)
- Lets you define workout categories (Strength, Running, Yoga, Cycling, etc.) with a weekly frequency target
- Tracks completions for the current ISO week and shows progress on a ring per category
- Deduplicates overlapping entries from multiple sources (e.g. a run logged by both Nike Run Club and Strava counts once)
- Shows a 7-day activity strip on the home screen with per-day workout icons

## Stack

- SwiftUI only — no UIKit in view layer
- iOS 17+ deployment target
- No third-party dependencies — pure Apple frameworks
- HealthKit for workout data
- App Groups + UserDefaults for data sharing between app and future widget/watch targets

---

## Status

### ✅ Phase 1 — Scaffold
Project structure, data models, xcodegen setup, App Group entitlements, target configuration (iOS app + Widget extension stub + watchOS placeholder).

### ✅ Phase 2 — HealthKit integration
Read-only HealthKit access, workout fetching per category, two-pass deduplication (externalId dedup + overlap dedup for cross-app duplicates), background delivery groundwork.

### ✅ Phase 3 — Core UI
- Home screen: weekly activity strip + 2-column goal card grid with circular progress rings
- History tab: chronological workout entry list with category chips and source badges
- Profile tab: category management (add, delete, reorder) + HealthKit auth status
- Goal creation sheet: workout type picker + frequency stepper
- Custom tab bar (Home · History · Profile)

### 🚧 Phase 3.5 — UI hardening (in progress)
- [x] Weekly activity strip with per-day workout icons
- [x] Unified colour system (`WorkoutCategory.displayColor` — single source of truth across rings, strip, chips)
- [ ] Edit frequency on existing goals (currently delete + re-add)
- [ ] Empty state on Home when no goals are configured
- [ ] Pull-to-refresh confirmation (last-updated timestamp)
- [ ] Goal card tap → category detail / entry history
- [ ] Haptic feedback on interactions
- [ ] VoiceOver labels on Canvas-drawn ring views

### 📋 Phase 4 — Widgets
Home screen widget (medium) and lock screen widget via WidgetKit. Will share goal data from the app via App Groups and refresh timelines using HealthKit background delivery (already wired, not yet activated).

### 📋 Phase 5 — Apple Watch
Companion watchOS app. Architecture is watch-ready from day one: models are HK-free, colour logic is app-target-only, shared constants compile into both app and widget already.

---

## Project structure

```
Chalk/
├── project.yml                         ← xcodegen source of truth (edit this, not .xcodeproj)
├── Config/
│   └── DevelopmentTeam.xcconfig        ← gitignored; copy from .example and set your team ID
├── Chalk/                              ← iOS app sources
│   ├── App/
│   │   ├── ChalkApp.swift              ← entry point, Color(hex:), background modifier
│   │   ├── RootView.swift              ← TabView shell + custom tab bar
│   │   ├── AppState.swift              ← central ObservableObject
│   │   └── WorkoutCategory+Color.swift ← displayColor: single colour source of truth
│   ├── Models/                         ← WorkoutCategory, WorkoutEntry, WeeklyGoal
│   ├── Features/
│   │   ├── Home/                       ← HomeView, GoalCardView, WeeklyActivityStrip
│   │   ├── History/                    ← HistoryView
│   │   ├── Profile/                    ← ProfileView
│   │   ├── Goals/                      ← AddGoalView
│   │   └── Stats/                      ← StatsView
│   ├── HealthKit/
│   │   └── HealthKitManager.swift      ← sole HealthKit importer
│   ├── Shared/
│   │   └── SharedConstants.swift       ← compiled into app + widget (App Group ID, keys)
│   └── Widgets/
│       └── ChalkWidgetExtension/       ← Phase 4 stub
├── ChalkWatch/                         ← Phase 5 placeholder
└── Chalk.xcodeproj/                    ← generated; commit but don't edit directly
```

## Setup

1. Install [xcodegen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
2. Copy the team config: `cp Config/DevelopmentTeam.xcconfig.example Config/DevelopmentTeam.xcconfig`
3. Set your Apple Developer team ID inside that file
4. Generate the project: `xcodegen generate`
5. Open `Chalk.xcodeproj` and run on a device (HealthKit requires a real device)

> To add or move source files, edit `project.yml` then re-run `xcodegen generate`. Never edit `.xcodeproj` directly.
