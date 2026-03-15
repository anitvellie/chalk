// HomeView.swift
// Chalk — Home Tab
//
// Shows the current week's goal progress for every category as a
// 2-column grid of GoalCards. Pull-to-refresh re-fetches HealthKit data.

import SwiftUI

struct HomeView: View {

    @EnvironmentObject var appState: AppState

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // Week range subtitle
                    Text(weekRangeLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                        .padding(.bottom, 16)

                    if appState.isLoading && appState.weeklyGoals.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 80)

                    } else if appState.weeklyGoals.isEmpty {
                        emptyState

                    } else {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(appState.weeklyGoals) { goal in
                                GoalCardView(goal: goal)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            .refreshable { await appState.refreshGoals() }
            .background(Color.chalkBackground)
            .navigationTitle("Chalk")
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
        VStack(spacing: 16) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: "#135bec"))
            Text("No goals yet")
                .font(.headline)
            if !HealthKitManager.isAvailable {
                Text("HealthKit isn't available on this device.")
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
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.red.opacity(0.85), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Helpers

    private var weekRangeLabel: String {
        let cal = Calendar.iso8601
        guard let interval = cal.dateInterval(of: .weekOfYear, for: Date()) else {
            return "This Week"
        }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        let start = fmt.string(from: interval.start)
        let end   = fmt.string(from: interval.end.addingTimeInterval(-1))
        return "Week of \(start) – \(end)"
    }
}
