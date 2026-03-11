// ChalkWatchApp.swift
// Chalk — watchOS Companion App
//
// Phase 1: Placeholder only. Full implementation is scheduled for Phase 5.
//
// Phase 5 will implement:
//   - Reading weekly goal progress from the shared App Group container.
//   - Displaying today's goal summary and tally-mark progress.
//   - Quick-log capability (manual entry from the wrist).
//   - Complications for watch faces.

import SwiftUI

@main
struct ChalkWatchApp: App {
    var body: some Scene {
        WindowGroup {
            ChalkWatchContentView()
        }
    }
}

// MARK: - Placeholder Root View

/// Temporary placeholder view for the watchOS target.
/// Will be replaced in Phase 5 with the full watch UI.
struct ChalkWatchContentView: View {
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "dumbbell.fill")
                .font(.title2)
                .foregroundStyle(Color(red: 0.075, green: 0.357, blue: 0.925))
            Text("Chalk")
                .font(.headline)
            Text("Phase 5")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        // TODO: Phase 5 — Replace with NavigationStack → GoalListView
    }
}
