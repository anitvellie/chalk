# Chalk — Project Intelligence File

## What is Chalk?
A native iOS app that helps users track weekly workout goals by pulling data from Apple HealthKit (sourced from Strong, Strava, NRC, Apple Fitness, etc.). Users define workout categories and weekly targets; the app counts completions automatically.

The name "Chalk" references gym chalk and the tradition of chalking up tally marks — a satisfying, physical metaphor for logging progress.

## Current Status
- Phase 1: ✅ Complete
- Phase 2: ✅ Complete
- Phase 3: ✅ Complete
- Phase 3.5: 🚧 In progress (UI hardening + feedback)

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
- `WorkoutCategory`: id, name, icon (SF Symbol name), targetPerWeek (Int), activityTypeRawValues ([Int])
- `WorkoutEntry`: id, categoryId (UUID ref), date, duration, source (WorkoutSource enum), externalId (UUID?)
- `WeeklyGoal`: derived struct — never persisted; computed from WorkoutEntry records for current ISO week
- `UserPreferences`: Codable struct — minWorkoutDurationMinutes (Int, default 5), minWalkingDurationMinutes (Int, default 45), excludedActivityTypeRawValues (Set\<Int\>); persisted in App Group UserDefaults

## Default Goals (updated from original spec)
Upper Body and Legs were **merged into a single Strength category** because both map to
`HKWorkoutActivityType.traditionalStrengthTraining` in HealthKit with no reliable way to
distinguish them from workout metadata. Current seed defaults (written once on first launch via `HealthKitManager.defaultCategories`):

- **Strength**: 4x/week → HK `.traditionalStrengthTraining` + `.functionalStrengthTraining` (combined in defaultCategories for legacy reasons)
- **Running**: 3x/week → HK `.running`
- **Yoga**: 1x/week → HK `.yoga` + `.mindAndBody`

In `categoryLibrary` (the picker catalog), Strength and Functional Strength are **separate entries** mapping to one HK type each. Yoga still bundles yoga + mindAndBody since they're indistinguishable in practice.

## Decisions Made

### Data model
- `WorkoutCategory` has **no `colorHex` field** — colour is derived entirely in the view layer
- `WorkoutCategory.displayColor: Color` — app-only view extension in `Chalk/App/WorkoutCategory+Color.swift`; switches on the `icon` SF Symbol string to return a `Color(uiColor:)` system colour for every known workout type; this is the **single source of truth for category colours** used by goal-card rings, weekly strip icons, history chips, and profile chips. Add a new `case` here whenever a new type is added to `categoryLibrary`
- Rowing icon is `figure.indoor.rowing` (not `figure.rowing` — that symbol does not exist in SF Symbols)
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
- `HealthKitManager.walkingActivityTypeRawValue: Int` — static property exposing the walking raw value as a plain `Int` so `AppState` can identify walking entries for threshold filtering without importing HealthKit
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
- **UserPreferences**: JSON-encoded to App Group UserDefaults under `SharedConstants.UserDefaultsKey.preferences`; loaded in `AppState.init()`, saved via `AppState.savePreferences()`
- **WorkoutEntries**: not cached — fetched fresh from HealthKit on every `refreshGoals()` call
- **WeeklyGoals**: never stored; derived on the fly

### Project generation
- `project.yml` (xcodegen 2.25) is the source of truth for the Xcode project
- **Always edit `project.yml`, then run `./regen.sh`** — never edit `.xcodeproj` directly, and never run `xcodegen generate` directly
- `regen.sh` wraps `xcodegen generate` and automatically re-applies the manual pbxproj patches for `chalk_app_icon.icon` (xcodegen 2.25 cannot model `folder.iconcomposer.icon`, so the Icon Composer file must be wired in via stable GUIDs after every regeneration)
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
- Header: "Your week in overview" + week range subtitle
- `WeeklyActivityStrip` — 7-column horizontal strip showing workout icons for the current week:
  - Week start derived from `Calendar.current.firstWeekday` (locale-aware, not hardcoded Mon)
  - Each column: icon(s) top, day letter bottom; `VStack(spacing: 10)` gives 10 pt between bottom of lowest icon and letter
  - Day text colours: today = `.primary`, past = `#D6D6D6`, future = `#898989`
  - 0 workouts → date number in icon slot; 1 workout → single icon; 2 workouts → `TwoIconStack` (VStack with negative spacing for overlap — **not** ZStack+offset, which is layout-incorrect); 3+ → `OverflowIconStack` (top 2 by duration + red badge showing total count)
  - Icons: `"\(category.icon).circle.fill"`, `.resizable()`, `.symbolRenderingMode(.monochrome)`, `.foregroundStyle(category.displayColor.gradient)`, 37 pt frame
  - `TwoIconStack` uses `VStack(spacing: -13)` so the layout frame genuinely ends at the bottom of the lower icon; a `Color(.systemBackground)` circle (31 pt) sits behind the lower icon to plug the SF Symbol's transparent cutout
  - `HStack(alignment: .bottom)` in the strip keeps all day letters at the same baseline; multi-icon columns extend upward
- Divider + "Goal progress" section header below the strip
- 2-column `LazyVGrid` of `GoalCardView`s
- `.chalkBackground()` is a `ViewModifier` reading `@Environment(\.colorScheme)` — picks `#f6f6f8` (light) or `#101622` (dark), no UIKit needed

#### Goal card
- `GoalCardView`: glass card via `.background(.regularMaterial)` + `RoundedRectangle` stroke border
- `SegmentedRingView`: `Canvas`-drawn arcs — N segments with **6° gap** between each; completed segments use category colour, pending use `.gray.opacity(0.2)`

#### History / Profile
- History: sorted entry list; each row shows category chip, date/time, duration, HK source badge; `ContentUnavailableView` for empty state
- Profile: category list (name, target, icon chip) + HK auth status; goal editing wired up in goal-creation flow
- Stats tab removed in Phase 3.5 cleanup (summary data will move to Home in a later pass)

#### AppState / HealthKit
- `refreshGoals()` fetches raw entries via `fetchCurrentWeekEntries` (not `fetchCurrentWeekGoals`), runs them through `filterEntries(_:using:)`, then computes `weeklyGoals` via `WeeklyGoal.compute`; this single path applies user preferences to goals, History, and the strip consistently
- `filterEntries(_:using:)` — private method in `AppState`; takes entries + the category array whose IDs they reference; drops excluded types and entries below the duration threshold (walking uses its own threshold, everything else uses the global one)
- `AppState.lastRefreshed: Date?` — set after every successful sync; displayed as "Updated HH:MM" below the week range in HomeView
- `addCategory`, `deleteCategory`, `updateCategory` implemented in `AppState`
- `setMinWorkoutDuration`, `setMinWalkingDuration` — save the preference and trigger `refreshGoals` on view dismiss
- `excludeActivityType(_ rawValues:)` — removes conflicting goals, adds to excluded set, saves, refreshes; called after user confirms the confirmation dialog in `ExcludedTypesView`
- `includeActivityType(_ rawValues:)` — inverse of the above; removes from excluded set and refreshes

#### Goal management (GoalSetupView)
- `HealthKitManager.categoryLibrary` — `static let` (lazy, evaluated once) with **65 entries** covering the full HealthKit workout type catalog, sorted alphabetically by display name; stable UUIDs for identity-based rendering; superset of `defaultCategories`
- `GoalSetupView` is the primary goal management surface, used in two modes — `.onboarding` and `.profile`; `AddGoalView` still exists but is no longer wired into the main flow
- Tapping a sport tile in `GoalSetupView` immediately adds the goal at `targetPerWeek = 2` (no intermediate picker step); existing goals show inline +/- stepper and delete button
- Excluded types appear in the add grid as `ExcludedWorkoutTile` (dimmed, eye-slash icon, non-selectable); tapping shows an alert directing the user to Profile → Excluded Types
- `ProfileView` Edit button → `GoalSetupView(mode: .profile)` sheet; swipe-to-delete still available in the Profile list as a secondary path
- Onboarding "Get Started" → `GoalSetupView(mode: .onboarding)` full-screen cover → `completeOnboarding()` on Continue or Skip

#### History
- `HistoryView` sources from `appState.stripEntries` (all 65 HealthKit types) — not `appState.entries` (goal-matched only); category names and icons resolved from `HealthKitManager.categoryLibrary`; this means all workouts logged that week appear in History regardless of whether the user has a matching goal

#### Profile preferences
- ProfileView has a **Preferences** section above Goals with three `NavigationLink` rows:
  - **Min Workout Duration** → `WorkoutDurationView`: ±5 min stepper (5–60 min); saves on tap, triggers refresh on dismiss
  - **Min Walking Duration** → `WalkingDurationView`: ±15 min stepper (15–120 min); same save/refresh pattern
  - **Excluded Types** → `ExcludedTypesView`: full 65-type list; toggle per type (ON = shown, OFF = excluded); if the user excludes a type that has an existing goal, a `.confirmationDialog` warns them the goal will be removed before proceeding

## Phase 3 Status: ✅ Complete
All Phase 3 deliverables shipped:
- Navigation shell (tab bar + FAB)
- Home screen (goal card grid with segmented rings)
- Stats / History / Profile (real data, generic presentation)
- Goal creation flow (AddGoalView sheet with type picker + frequency stepper)
- Goal deletion (swipe-to-delete in Profile)

## Phase 3.5 — UI Hardening (post-widget, pre-watch)
This phase happens after Phase 4 (Widgets) and before Phase 5 (watchOS). It tightens up the core UI.

### Shipped in 3.5
- **Onboarding flow** — `Chalk/Features/Onboarding/OnboardingView.swift`; two-page TabView (`.page` style) gated by `AppState.hasCompletedOnboarding` (UserDefaults `"hasCompletedOnboarding"` key); page 1 has three floating goal cards with independent sine-wave animation via `TimelineView`; page 2 has two floating weekly strip cards with mock workout data; `AppState.completeOnboarding()` flips the flag and SwiftUI transitions to `RootView`, which fires `setupHealthKit()` as usual
- **Goal setup screen** — `Chalk/Features/Goals/GoalSetupView.swift`; replaces `AddGoalView` as the primary goal management surface; two modes: `.onboarding` (shown after "Get Started" via `.fullScreenCover`; has Continue + Skip bottom bar) and `.profile` (shown from Profile → Edit as a `.sheet`; has Done toolbar button). Top section lists configured goals with inline +/- frequency stepper and trash delete. Bottom section shows a 2-column grid of all untracked sport types — tapping adds the goal immediately at 2×/week default. Sport library expanded to 65 entries covering the full HealthKit workout type catalog, sorted alphabetically. `WorkoutCategory+Color.swift` updated with semantic color groupings for all new icons.
- **Weekly strip shows all workouts** — `AppState` now fetches `stripEntries` (entries for all `categoryLibrary` types) separately from `entries` (user-configured categories only); `WeeklyActivityStrip` on Home receives `stripEntries` + `HealthKitManager.categoryLibrary` so it shows every workout logged that week even when no matching goal is configured
- **Debug: force onboarding** — `AppState.init()` checks `UserDefaults "debug.forceOnboarding"` (DEBUG only); if set, `hasCompletedOnboarding` starts `false` each launch and `completeOnboarding()` skips the UserDefaults persist, so onboarding shows every launch without permanently clearing the real flag. Toggled via Profile → Developer → Mock Data → Onboarding section.
- **Pull-to-refresh + last-synced timestamp** — `HomeView` pull-to-refresh calls `AppState.refreshGoals()`; `AppState.lastRefreshed: Date?` is set on every successful sync and displayed as "Updated HH:MM" (caption2, tertiary) below the week range header so the user can always confirm a refresh completed.
- **History shows all workouts** — `HistoryView` switched from `appState.entries` (goal-matched) to `appState.stripEntries` (all 65 HK types); category lookup uses `HealthKitManager.categoryLibrary` so names and icons resolve for every workout type.
- **User preferences** — three new preference screens pushed from a new "Preferences" section in ProfileView (above Goals): Min Workout Duration (5–60 min, 5-min steps), Min Walking Duration (15–120 min, 15-min steps), Excluded Types (toggle per activity type with goal-removal confirmation). Preferences persisted in App Group UserDefaults as `UserPreferences` (Codable). Filtering applied in `AppState.filterEntries(_:using:)` after every HealthKit fetch — affects goal counts, History, and the weekly strip equally.

### Known issues carried forward
- History/Profile use generic `List` presentation — visual polish deferred

### Ideas / backlog
- **Goal management from Home** — add a way to add/edit/delete goals directly from the home screen (e.g. long-press on a card → context menu, or an "Edit" button in the nav bar) so users never need to go to Profile for this
- **Stats surface on Home** — fold the key stats (total sessions this week, streak, etc.) into the Home screen as a header or collapsible section, since the standalone Stats tab was removed
- **Empty state for Home** — when no goals are configured yet, show an onboarding-style prompt to add the first goal
- **Goal card tap** — tapping a goal card could open a detail view with full entry history for that category
- **Haptic feedback** — light haptics on tab switch and goal card interactions
- **Accessibility** — audit VoiceOver labels on `SegmentedRingView` (Canvas-drawn, so needs explicit `accessibilityLabel`)
- **Indoor vs outdoor cycling** — HealthKit uses `HKWorkoutActivityType.cycling` for both; distinction is in `HKMetadataKeyIndoorWorkout` metadata. Deferred — would require reading metadata in `HealthKitManager.fetchWorkouts`.
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
│   │   ├── ChalkApp.swift              ← @main entry + Color(hex:) + chalkBackground modifier
│   │   ├── RootView.swift              ← TabView shell + CustomTabBar + Tab enum
│   │   ├── AppState.swift              ← central @MainActor ObservableObject
│   │   └── WorkoutCategory+Color.swift ← displayColor extension; single source of truth for category colours
│   ├── Models/
│   │   ├── WorkoutCategory.swift
│   │   ├── WorkoutEntry.swift      ← includes WorkoutSource enum
│   │   ├── WeeklyGoal.swift        ← includes Calendar.iso8601 extension
│   │   └── UserPreferences.swift   ← Codable prefs: duration thresholds + excluded types
│   ├── Features/
│   │   ├── Home/
│   │   │   ├── HomeView.swift              ← week overview header + strip + goal card grid
│   │   │   ├── GoalCardView.swift          ← glass card + ContinuousRingView (Canvas)
│   │   │   └── WeeklyActivityStrip.swift   ← 7-day workout icon strip
│   │   ├── Stats/
│   │   │   └── StatsView.swift     ← total sessions + per-category progress bars
│   │   ├── History/
│   │   │   └── HistoryView.swift   ← sorted entry list with category chip + duration
│   │   ├── Profile/
│   │   │   ├── ProfileView.swift           ← preferences section + goal list + HK auth status
│   │   │   ├── WorkoutDurationView.swift   ← min workout duration stepper (5–60 min, 5-min steps)
│   │   │   ├── WalkingDurationView.swift   ← min walking duration stepper (15–120 min, 15-min steps)
│   │   │   └── ExcludedTypesView.swift     ← per-type exclusion toggles with goal-removal confirmation
│   │   ├── Goals/
│   │   │   ├── GoalSetupView.swift ← primary goal management (onboarding + profile modes); tap-to-add grid + inline frequency stepper
│   │   │   └── AddGoalView.swift   ← legacy single-goal sheet (not wired into main flow)
│   │   └── Onboarding/
│   │       └── OnboardingView.swift ← two-page first-launch flow; floating cards + floating weekly strips
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
