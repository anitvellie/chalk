// ChalkApp.swift
// Chalk — iOS App Entry Point

import SwiftUI

@main
struct ChalkApp: App {

    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
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

// MARK: - Adaptive Background

/// Applies Chalk's background colour: `#f6f6f8` in light mode, `#101622` in dark mode.
private struct ChalkBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    func body(content: Content) -> some View {
        content.background(
            colorScheme == .dark
                ? Color(hex: "#101622")
                : Color(hex: "#f6f6f8")
        )
    }
}

extension View {
    func chalkBackground() -> some View {
        modifier(ChalkBackgroundModifier())
    }
}
