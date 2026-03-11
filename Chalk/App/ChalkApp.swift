// ChalkApp.swift
// Chalk — iOS App Entry Point
//
// Phase 1: Scaffold stub.
// TODO: Phase 3 — Replace ContentView placeholder with real root TabView navigation.

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

// MARK: - Placeholder Root View

/// Temporary placeholder root view.
/// Will be replaced in Phase 3 with the bottom-tab navigation shell.
struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: "#135bec"))
            Text("Chalk")
                .font(.largeTitle.bold())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "#f6f6f8"))
    }
}

// MARK: - Color Hex Helper (Shared Utility)

/// Convenience initialiser for creating a SwiftUI Color from a hex string.
/// Used throughout the app to render category colours stored as hex strings.
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
