// HomeView.swift
// Chalk — Home Tab
//
// Shows the current week's goal progress for every category as a
// 2-column grid of GoalCards. Pull-to-refresh re-fetches HealthKit data.

import SwiftUI

struct HomeView: View {

    private struct Constants {
        static let appName = "Chalk"
        static let weekOverview = "Your week in overview"
        static let goalProgress = "Goal progress"
        static let noGoals = "No goals yet"
        static let healthKitAccessError = "HealthKit isn't available on this device."
        static let weekOf = "Week of"
        static let weekOfFallback = "This week"
        static let dateFormatWeek = "MMM d"
        static let dumbellIcon = "dumbbell.fill"
        static let dumbellIconColour = "#135bec"
        static let dumbellIconSize: CGFloat = 48
        static let horizonalPadding: CGFloat = 16
        static let bottomPadding: CGFloat = 16
        static let bottomPaddingIncreased: CGFloat = 20
    }

    @EnvironmentObject var appState: AppState

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // Header
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Constants.weekOverview)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(weekRangeLabel)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if let ts = appState.lastRefreshed {
                            Text("Updated \(ts, formatter: Self.relativeFormatter)")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .padding(.horizontal, Constants.horizonalPadding)
                    .padding(.top, 4)
                    .padding(.bottom, Constants.bottomPaddingIncreased)

                    // Weekly activity strip
                    WeeklyActivityStrip(
                        entries: appState.stripEntries,
                        categories: HealthKitManager.categoryLibrary
                    )
                    .padding(.horizontal, Constants.horizonalPadding)
                    .padding(.bottom, Constants.bottomPadding)

                    Text(Constants.goalProgress)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, Constants.horizonalPadding)
                        .padding(.top, 12)
                        .padding(.bottom, Constants.bottomPadding)

                    if appState.isLoading && appState.weeklyGoals.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 40)

                    } else if appState.weeklyGoals.isEmpty {
                        emptyState

                    } else {
                        LazyVGrid(columns: columns, spacing: Constants.horizonalPadding) {
                            ForEach(appState.weeklyGoals) { goal in
                                GoalCardView(goal: goal)
                            }
                        }
                        .padding(.horizontal, Constants.horizonalPadding)
                        .padding(.bottom, 24)
                    }
                }
            }
            .scrollBounceBehavior(.always)
            .refreshable { await appState.refreshGoals() }
            .chalkBackground()
            .navigationTitle(Constants.appName)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if appState.isLoading {
                        ProgressView().scaleEffect(0.8)
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if let message = appState.errorMessage {
                    errorBanner(message)
                        .padding()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - Sub-views

    private var emptyState: some View {
        VStack(spacing: Constants.horizonalPadding) {
            Image(systemName: Constants.dumbellIcon)
                .font(.system(size: Constants.dumbellIconSize))
                .foregroundStyle(Color(hex: Constants.dumbellIconColour))
            Text(Constants.noGoals)
                .font(.headline)
            if !HealthKitManager.isAvailable {
                Text(Constants.healthKitAccessError)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    private func errorBanner(_ message: String) -> some View {
        Text(message)
            .font(.caption)
            .foregroundStyle(.white)
            .padding(.horizontal, Constants.horizonalPadding)
            .padding(.vertical, 10)
            .background(Color.red.opacity(0.85), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Helpers

    private static let relativeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    private var weekRangeLabel: String {
        let cal = Calendar.iso8601
        guard let interval = cal.dateInterval(of: .weekOfYear, for: Date()) else {
            return Constants.weekOfFallback
        }
        let fmt = DateFormatter()
        fmt.dateFormat = Constants.dateFormatWeek
        let start = fmt.string(from: interval.start)
        let end   = fmt.string(from: interval.end.addingTimeInterval(-1))
        return "\(Constants.weekOf) \(start) – \(end)"
    }
}
