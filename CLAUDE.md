# Chalk — Project Intelligence File

## What is Chalk?
A native iOS app that helps users track weekly workout goals by pulling data from Apple HealthKit (sourced from Strong, Strava, NRC, Apple Fitness, etc.). Users define workout categories and weekly targets; the app counts completions automatically.

The name "Chalk" references gym chalk and the tradition of chalking up tally marks — a satisfying, physical metaphor for logging progress.

## Current Status
- Phase 1: ✅ Complete
- Phase 2: ✅ Complete
- Phase 3: ✅ Complete
- Phase 3.5: Upcoming (UI hardening + feedback)

## Phases
- [x] Phase 1 — Project scaffold, data models, target setup
- [x] Phase 2 — HealthKit integration
- [x] Phase 3 — Core UI (home screen, weekly overview, goal creation)
- [ ] Phase 3.5 — UI hardening (feedback, polish, edge cases)
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
- Bottom tab bar: Home, History, Profile (3 tabs, no FAB)
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

### Duplicate workout detection
- `WorkoutEntry.isHidden: Bool` (default `false`) marks entries suppressed by overlap deduplication
- Hidden entries are retained in `AppState.entries` for future use but excluded from goal counts and History
- Dedup runs in `HealthKitManager.fetchWorkouts` as a two-pass process:
  1. **Pass 1** — externalId dedup (defensive; prevents a single HK sample matching two activity types from being double-counted)
  2. **Pass 2** — overlap dedup: entries are sorted by start date, grouped into overlapping time windows, and within each group all but the longest are marked `isHidden = true`; ties broken by earliest start date
- Motivation: cross-app integrations (e.g. Nike Run Club → Strava) create duplicate HK samples for the same workout; since Chalk only tracks *that* a workout happened (not pace/distance), one entry per session is sufficient

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

### Phase 3 — UI (decisions made so far)

#### Navigation shell
- `Tab` enum defined in `RootView.swift`; `RootView` owns the `.task { setupHealthKit() }` call
- `TabView` with `.toolbar(.hidden, for: .tabBar)` + `.safeAreaInset(edge: .bottom)` reserves space for the custom bar
- `CustomTabBar` has 3 slots: Home | History | Profile — Stats and FAB removed in Phase 3.5 cleanup
- Tab bar background: `.ultraThinMaterial` with `.ignoresSafeArea(edges: .bottom)` so it covers the home-indicator area
- Active tab icon uses `"\(icon).fill"` variant in `#135bec`; inactive uses outline in `.secondary`

#### Home screen
- 2-column `LazyVGrid` of `GoalCardView`s; week range shown as subtitle below the large nav title
- `.chalkBackground()` is a `ViewModifier` reading `@Environment(\.colorScheme)` — picks `#f6f6f8` (light) or `#101622` (dark), no UIKit needed

#### Goal card
- `GoalCardView`: glass card via `.background(.regularMaterial)` + `RoundedRectangle` stroke border
- `SegmentedRingView`: `Canvas`-drawn arcs — N segments with **6° gap** between each; completed segments use category colour, pending use `.gray.opacity(0.2)`

#### History / Profile
- History: sorted entry list; each row shows category chip, date/time, duration, HK source badge; `ContentUnavailableView` for empty state
- Profile: category list (name, target, icon chip) + HK auth status; goal editing wired up in goal-creation flow
- Stats tab removed in Phase 3.5 cleanup (summary data will move to Home in a later pass)

#### AppState / HealthKit
- `refreshGoals()` now also populates `entries` (two sequential HK fetches: goals then entries)
- `HealthKitManager.fetchCurrentWeekEntries(for:)` mirrors `fetchCurrentWeekGoals` but returns flat `[WorkoutEntry]` sorted newest-first
- `addCategory`, `deleteCategory`, `updateCategory` implemented in `AppState`

#### Goal creation (AddGoalView)
- `HealthKitManager.categoryLibrary` — `static let` (lazy, evaluated once) giving all 8 supported types stable UUIDs; superset of `defaultCategories`
- `AddGoalView` filters the library to exclude already-tracked HK activity raw values so you can't add duplicates
- Tile selection stores the template in `@State`; tapping again deselects; frequency resets to library default on each new selection
- `commitSelection()` copies the template, overwrites `targetPerWeek`, calls `appState.addCategory`, dismisses, then fires `Task { await appState.refreshGoals() }`
- `ProfileView` has `.onDelete` (swipe-to-delete) + `EditButton` in toolbar

## Phase 3 Status: ✅ Complete
All Phase 3 deliverables shipped:
- Navigation shell (tab bar + FAB)
- Home screen (goal card grid with segmented rings)
- Stats / History / Profile (real data, generic presentation)
- Goal creation flow (AddGoalView sheet with type picker + frequency stepper)
- Goal deletion (swipe-to-delete in Profile)

## Phase 3.5 — UI Hardening (post-widget, pre-watch)
This phase happens after Phase 4 (Widgets) and before Phase 5 (watchOS). It tightens up the core UI.

### Known issues carried forward
- No edit-frequency flow for existing goals (can only delete + re-add)
- History/Profile use generic `List` presentation — visual polish deferred
- `ProfileView` has a dead `showingAddGoal` state; Add Goal only reachable via Profile

### Ideas / backlog
- **Goal management from Home** — add a way to add/edit/delete goals directly from the home screen (e.g. long-press on a card → context menu, or an "Edit" button in the nav bar) so users never need to go to Profile for this
- **Edit-frequency flow** — let users change `targetPerWeek` on an existing goal without delete + re-add
- **Stats surface on Home** — fold the key stats (total sessions this week, streak, etc.) into the Home screen as a header or collapsible section, since the standalone Stats tab was removed
- **Empty state for Home** — when no goals are configured yet, show an onboarding-style prompt to add the first goal
- **Pull-to-refresh feedback** — visual confirmation that a refresh completed (e.g. last-updated timestamp below the week range header)
- **Goal card tap** — tapping a goal card could open a detail view with full entry history for that category
- **Haptic feedback** — light haptics on tab switch and goal card interactions
- **Accessibility** — audit VoiceOver labels on `SegmentedRingView` (Canvas-drawn, so needs explicit `accessibilityLabel`)
- **User-selectable duplicate resolution** — when overlap dedup hides an entry, surface both options in a UI and let the user choose which one to keep (e.g. prefer Nike's active duration vs Strava's elapsed time); hidden entries are already retained in `AppState.entries` to support this

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
│   │   ├── ChalkApp.swift          ← @main entry + Color(hex:) + chalkBackground modifier
│   │   ├── RootView.swift          ← TabView shell + CustomTabBar + Tab enum
│   │   └── AppState.swift          ← central @MainActor ObservableObject
│   ├── Models/
│   │   ├── WorkoutCategory.swift
│   │   ├── WorkoutEntry.swift      ← includes WorkoutSource enum
│   │   └── WeeklyGoal.swift        ← includes Calendar.iso8601 extension
│   ├── Features/
│   │   ├── Home/
│   │   │   ├── HomeView.swift      ← 2-col goal card grid + week range header
│   │   │   └── GoalCardView.swift  ← glass card + SegmentedRingView (Canvas)
│   │   ├── Stats/
│   │   │   └── StatsView.swift     ← total sessions + per-category progress bars
│   │   ├── History/
│   │   │   └── HistoryView.swift   ← sorted entry list with category chip + duration
│   │   ├── Profile/
│   │   │   └── ProfileView.swift   ← category list + HK auth status
│   │   └── Goals/
│   │       └── AddGoalView.swift   ← type picker grid + frequency stepper sheet
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
