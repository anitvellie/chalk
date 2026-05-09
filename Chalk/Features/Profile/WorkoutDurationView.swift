// WorkoutDurationView.swift
// Chalk — Min Workout Duration Preference

import SwiftUI

struct WorkoutDurationView: View {

    @EnvironmentObject var appState: AppState

    private let step = 5
    private let minValue = 5
    private let maxValue = 60

    private var current: Int { appState.preferences.minWorkoutDurationMinutes }

    var body: some View {
        Form {
            Section {
                durationControl
            } footer: {
                Text("Workouts shorter than \(current) minute\(current == 1 ? "" : "s") won't count toward your goals or appear in History and the weekly strip.")
            }
        }
        .navigationTitle("Min Workout Duration")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            Task { await appState.refreshGoals() }
        }
    }

    private var durationControl: some View {
        HStack {
            Button {
                guard current > minValue else { return }
                appState.setMinWorkoutDuration(current - step)
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
                appState.setMinWorkoutDuration(current + step)
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
