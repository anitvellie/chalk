// HistoryView.swift
// Chalk — History Tab
//
// Lists this week's workout entries sourced from HealthKit,
// sorted newest-first. Each row shows the category, date/time, and duration.

import SwiftUI

struct HistoryView: View {

    @EnvironmentObject var appState: AppState

    private var sortedEntries: [WorkoutEntry] {
        appState.entries.sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            Group {
                if appState.entries.isEmpty && !appState.isLoading {
                    ContentUnavailableView(
                        "No Workouts",
                        systemImage: "figure.run.circle",
                        description: Text("Workouts from Apple Health will appear here.")
                    )
                } else {
                    List(sortedEntries) { entry in
                        entryRow(entry)
                    }
                }
            }
            .navigationTitle("History")
            .overlay {
                if appState.isLoading && appState.entries.isEmpty {
                    ProgressView()
                }
            }
        }
        .refreshable { await appState.refreshGoals() }
    }

    @ViewBuilder
    private func entryRow(_ entry: WorkoutEntry) -> some View {
        let category = appState.categories.first { $0.id == entry.categoryId }

        HStack(spacing: 12) {
            // Category icon chip
            Group {
                if let cat = category {
                    Image(systemName: cat.icon)
                        .foregroundStyle(Color(hex: cat.colorHex))
                        .frame(width: 36, height: 36)
                        .background(Color(hex: cat.colorHex).opacity(0.12))
                } else {
                    Image(systemName: "figure.mixed.cardio")
                        .foregroundStyle(.secondary)
                        .frame(width: 36, height: 36)
                        .background(Color.secondary.opacity(0.12))
                }
            }
            .font(.system(size: 14, weight: .semibold))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            // Name + date
            VStack(alignment: .leading, spacing: 2) {
                Text(category?.name ?? "Workout")
                    .font(.body.weight(.medium))
                Text(entry.date, format: .dateTime
                        .weekday(.abbreviated)
                        .month(.abbreviated)
                        .day()
                        .hour()
                        .minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Duration + source badge
            VStack(alignment: .trailing, spacing: 2) {
                Text(durationLabel(entry.duration))
                    .font(.subheadline.monospacedDigit())
                if entry.source == .healthKit {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(Color.red.opacity(0.6))
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func durationLabel(_ duration: TimeInterval) -> String {
        let mins = Int(duration / 60)
        if mins >= 60 { return "\(mins / 60)h \(mins % 60)m" }
        return "\(mins)m"
    }
}
