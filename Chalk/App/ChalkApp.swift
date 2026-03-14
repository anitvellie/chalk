// ChalkApp.swift
// Chalk — iOS App Entry Point
//
// TODO: Phase 3 — Replace ContentView with the real bottom-tab navigation shell.

import SwiftUI

@main
struct ChalkApp: App {

    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}

// MARK: - Phase 2 Debug Root View
//
// Temporary view that proves HealthKit data flows correctly end-to-end.
// Replaced in Phase 3 with the real tab-bar navigation shell.

struct ContentView: View {

    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            Group {
                if appState.weeklyGoals.isEmpty && !appState.isLoading {
                    emptyState
                } else {
                    goalList
                }
            }
            .navigationTitle("Chalk")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if appState.isLoading {
                        ProgressView()
                    } else {
                        Button {
                            Task { await appState.refreshGoals() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if let message = appState.errorMessage {
                    errorBanner(message)
                }
            }
        }
        .task {
            await appState.setupHealthKit()
        }
    }

    // MARK: - Sub-views

    private var goalList: some View {
        List(appState.weeklyGoals) { goal in
            HStack(spacing: 14) {
                Image(systemName: goal.category.icon)
                    .font(.title3)
                    .foregroundStyle(Color(hex: goal.category.colorHex))
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.category.name)
                        .font(.body.weight(.medium))
                    Text("\(goal.remaining) remaining this week")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("\(goal.completedCount) / \(goal.targetCount)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(goal.isComplete ? Color.green : Color.primary)
            }
            .padding(.vertical, 4)
        }
        .listStyle(.insetGrouped)
        .refreshable {
            await appState.refreshGoals()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: "#135bec"))
            Text("Chalk")
                .font(.largeTitle.bold())
            if !HealthKitManager.isAvailable {
                Text("HealthKit not available on this device.\nUsing placeholder data.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#f6f6f8"))
    }

    private func errorBanner(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.red.opacity(0.85), in: RoundedRectangle(cornerRadius: 10))
            .padding()
    }
}

// MARK: - Color Hex Helper

/// Converts a hex colour string (e.g. `"#135bec"`) to a SwiftUI `Color`.
/// Supports 6-digit (RGB) and 8-digit (ARGB) hex strings.
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 6:
            (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8:
            (r, g, b, a) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(
            .sRGB,
            red:   Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
