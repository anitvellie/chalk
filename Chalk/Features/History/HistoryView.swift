// HistoryView.swift
// Chalk — History Tab
//
// Shows the current month as a calendar card at the top, then this week's
// workout entries (newest-first) under a "Current week" heading.
// Covers all activity types, not just configured goals.

import SwiftUI

struct HistoryView: View {

    @EnvironmentObject var appState: AppState

    private static let horizontalPadding: CGFloat = 16

    private var categoryMap: [UUID: WorkoutCategory] {
        Dictionary(uniqueKeysWithValues: HealthKitManager.categoryLibrary.map { ($0.id, $0) })
    }

    private var sortedEntries: [WorkoutEntry] {
        appState.stripEntries.filter { !$0.isHidden }.sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // Current month calendar
                    MonthCalendarView(
                        entries: appState.monthEntries,
                        categories: HealthKitManager.categoryLibrary
                    )
                    .padding(.horizontal, Self.horizontalPadding)
                    .padding(.top, 4)
                    .padding(.bottom, 28)

                    Divider()
                        .padding(.horizontal, Self.horizontalPadding)

                    Text("Current week")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, Self.horizontalPadding)
                        .padding(.top, 20)
                        .padding(.bottom, 8)

                    weekSection
                }
            }
            .scrollBounceBehavior(.always)
            .refreshable { await appState.refreshGoals() }
            .chalkBackground()
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if appState.isLoading {
                        ProgressView().scaleEffect(0.8)
                    }
                }
            }
        }
    }

    // MARK: - Week section

    @ViewBuilder
    private var weekSection: some View {
        if sortedEntries.isEmpty {
            if appState.isLoading && appState.stripEntries.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 32)
            } else {
                ContentUnavailableView(
                    "No Workouts This Week",
                    systemImage: "figure.run.circle",
                    description: Text("Workouts from Apple Health will appear here.")
                )
                .padding(.top, 12)
            }
        } else {
            VStack(spacing: 0) {
                ForEach(Array(sortedEntries.enumerated()), id: \.element.id) { index, entry in
                    entryRow(entry)
                        .padding(.vertical, 10)
                    if index < sortedEntries.count - 1 {
                        Divider()
                    }
                }
            }
            .padding(.horizontal, Self.horizontalPadding)
            .padding(.bottom, 24)
        }
    }

    @ViewBuilder
    private func entryRow(_ entry: WorkoutEntry) -> some View {
        let category = categoryMap[entry.categoryId]

        HStack(spacing: 12) {
            // Category icon chip
            Group {
                if let cat = category {
                    Image(systemName: cat.icon)
                        .foregroundStyle(cat.displayColor)
                        .frame(width: 36, height: 36)
                        .background(cat.displayColor.opacity(0.12))
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
    }

    private func durationLabel(_ duration: TimeInterval) -> String {
        let mins = Int(duration / 60)
        if mins >= 60 { return "\(mins / 60)h \(mins % 60)m" }
        return "\(mins)m"
    }
}
