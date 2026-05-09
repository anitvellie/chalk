// WalkingDurationView.swift
// Chalk — Min Walking Duration Preference

import SwiftUI

struct WalkingDurationView: View {

    @EnvironmentObject var appState: AppState

    private let step = 15
    private let minValue = 15
    private let maxValue = 120

    private var current: Int { appState.preferences.minWalkingDurationMinutes }

    var body: some View {
        Form {
            Section {
                durationControl
            } footer: {
                Text("Walking sessions shorter than \(current) minutes won't count toward goals or appear in History. Wearables log every step — this filters out incidental walks.")
            }
        }
        .navigationTitle("Min Walking Duration")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            Task { await appState.refreshGoals() }
        }
    }

    private var durationControl: some View {
        HStack {
            Button {
                guard current > minValue else { return }
                appState.setMinWalkingDuration(current - step)
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title)
                    .foregroundStyle(current > minValue ? Color(hex: "#135bec") : Color.secondary.opacity(0.35))
            }
            .disabled(current <= minValue)
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 2) {
                Text("\(current)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "#135bec"))
                    .contentTransition(.numericText())
                Text("minutes")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                guard current < maxValue else { return }
                appState.setMinWalkingDuration(current + step)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title)
                    .foregroundStyle(current < maxValue ? Color(hex: "#135bec") : Color.secondary.opacity(0.35))
            }
            .disabled(current >= maxValue)
            .buttonStyle(.plain)
        }
        .padding(.vertical, 20)
        .animation(.spring(duration: 0.2), value: current)
    }
}
