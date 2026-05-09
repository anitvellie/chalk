// ExcludedTypesView.swift
// Chalk — Excluded Workout Types Preference

import SwiftUI

struct ExcludedTypesView: View {

    @EnvironmentObject var appState: AppState

    /// Category pending exclusion — set when a conflicting goal exists, triggers the dialog.
    @State private var pendingExclusion: WorkoutCategory?

    var body: some View {
        List(HealthKitManager.categoryLibrary) { category in
            typeRow(category)
        }
        .navigationTitle("Excluded Types")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            pendingExclusion.map { "Exclude \($0.name)?" } ?? "",
            isPresented: Binding(
                get: { pendingExclusion != nil },
                set: { if !$0 { pendingExclusion = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Remove Goal & Exclude", role: .destructive) {
                if let category = pendingExclusion {
                    appState.excludeActivityType(category.activityTypeRawValues)
                }
                pendingExclusion = nil
            }
            Button("Cancel", role: .cancel) { pendingExclusion = nil }
        } message: {
            if let category = pendingExclusion, let goal = conflictingGoal(for: category) {
                Text("You have a \(goal.name) goal. Excluding \(category.name) will remove it and stop counting it toward your progress.")
            }
        }
    }

    // MARK: - Row

    @ViewBuilder
    private func typeRow(_ category: WorkoutCategory) -> some View {
        let excluded = isExcluded(category)
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(excluded ? .secondary : category.displayColor)
                .frame(width: 32, height: 32)
                .background((excluded ? Color.secondary : category.displayColor).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            Text(category.name)
                .foregroundStyle(excluded ? .secondary : .primary)

            Spacer()

            Toggle(
                "",
                isOn: Binding(
                    get: { !excluded },
                    set: { isEnabled in
                        if isEnabled {
                            appState.includeActivityType(category.activityTypeRawValues)
                        } else {
                            tryExclude(category)
                        }
                    }
                )
            )
            .labelsHidden()
        }
    }

    // MARK: - Helpers

    private func isExcluded(_ category: WorkoutCategory) -> Bool {
        category.activityTypeRawValues.contains(where: {
            appState.preferences.excludedActivityTypeRawValues.contains($0)
        })
    }

    private func conflictingGoal(for category: WorkoutCategory) -> WorkoutCategory? {
        let rawSet = Set(category.activityTypeRawValues)
        return appState.categories.first { $0.activityTypeRawValues.contains(where: { rawSet.contains($0) }) }
    }

    private func tryExclude(_ category: WorkoutCategory) {
        if conflictingGoal(for: category) != nil {
            pendingExclusion = category
        } else {
            appState.excludeActivityType(category.activityTypeRawValues)
        }
    }
}
