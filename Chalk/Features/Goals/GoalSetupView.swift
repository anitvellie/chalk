// GoalSetupView.swift
// Chalk — Goal Setup / Management Screen
//
// Used in two modes:
//   .onboarding — shown after "Get Started"; has Continue + Skip bottom bar
//   .profile    — shown from Profile → Edit; has a Done toolbar button

import SwiftUI

struct GoalSetupView: View {

    enum Mode { case onboarding, profile }

    let mode: Mode

    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var excludedAlertType: WorkoutCategory?

    private var availableTemplates: [WorkoutCategory] {
        let tracked = Set(appState.categories.flatMap { $0.activityTypeRawValues })
        return HealthKitManager.categoryLibrary.filter { t in
            !t.activityTypeRawValues.contains(where: { tracked.contains($0) })
        }
    }

    private func isExcluded(_ template: WorkoutCategory) -> Bool {
        template.activityTypeRawValues.contains(where: {
            appState.preferences.excludedActivityTypeRawValues.contains($0)
        })
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    if mode == .onboarding {
                        onboardingHeader
                    }

                    if !appState.categories.isEmpty {
                        configuredSection
                    }

                    addSection
                }
                .padding(.horizontal, 20)
                .padding(.top, mode == .onboarding ? 4 : 16)
                .padding(.bottom, 40)
                .animation(.spring(duration: 0.35), value: appState.categories.count)
            }
            .chalkBackground()
            .navigationTitle(mode == .onboarding ? "Your Goals" : "Manage Goals")
            .navigationBarTitleDisplayMode(mode == .onboarding ? .large : .inline)
            .toolbar {
                if mode == .profile {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { dismiss() }
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if mode == .onboarding { onboardingBottomBar }
            }
        }
    }

    // MARK: - Onboarding header

    private var onboardingHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("What are your\nfitness targets?")
                .font(.system(size: 28, weight: .bold))
                .lineSpacing(2)
            Text("Tap a sport to add it as a goal. You can change these anytime.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 4)
    }

    // MARK: - Configured goals

    private var configuredSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Your Goals")
            ForEach(appState.categories) { category in
                GoalRow(
                    category: category,
                    onFrequencyChange: { newValue in
                        var updated = category
                        updated.targetPerWeek = newValue
                        appState.updateCategory(updated)
                    },
                    onDelete: { appState.deleteCategory(id: category.id) }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
            }
        }
    }

    // MARK: - Add a goal

    private var addSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel(appState.categories.isEmpty ? "Choose Your Goals" : "Add a Goal")

            if availableTemplates.isEmpty {
                Text("You're tracking all available workout types.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 12
                ) {
                    ForEach(availableTemplates) { template in
                        if isExcluded(template) {
                            ExcludedWorkoutTile(template: template) {
                                excludedAlertType = template
                            }
                        } else {
                            WorkoutTile(template: template) { addGoal(template) }
                        }
                    }
                }
                .alert(
                    "\(excludedAlertType?.name ?? "") is Excluded",
                    isPresented: Binding(
                        get: { excludedAlertType != nil },
                        set: { if !$0 { excludedAlertType = nil } }
                    )
                ) {
                    Button("OK") { excludedAlertType = nil }
                } message: {
                    Text("This workout type is hidden in your preferences. Go to Profile → Excluded Types to re-enable it.")
                }
            }
        }
    }

    // MARK: - Onboarding bottom bar

    private var onboardingBottomBar: some View {
        VStack(spacing: 12) {
            Button(action: finish) {
                Text("Continue")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Color(hex: "#135bec"),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
            }
            .buttonStyle(.plain)

            Button("Skip for now", action: finish)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(uiColor: .separator))
                .frame(height: 0.5)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Helpers

    private func sectionLabel(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(Color(hex: "#135bec"))
            .tracking(1)
    }

    private func addGoal(_ template: WorkoutCategory) {
        var category = template
        category.targetPerWeek = 2
        appState.addCategory(category)
        Task { await appState.refreshGoals() }
    }

    private func finish() {
        appState.completeOnboarding()
    }
}

// MARK: - Goal Row

private struct GoalRow: View {
    let category: WorkoutCategory
    let onFrequencyChange: (Int) -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(category.displayColor)
                .frame(width: 36, height: 36)
                .background(category.displayColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            Text(category.name)
                .font(.body.weight(.medium))

            Spacer()

            HStack(spacing: 10) {
                Button {
                    if category.targetPerWeek > 1 {
                        onFrequencyChange(category.targetPerWeek - 1)
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .foregroundStyle(
                            category.targetPerWeek > 1
                                ? category.displayColor
                                : Color.secondary.opacity(0.4)
                        )
                }
                .disabled(category.targetPerWeek <= 1)

                Text("\(category.targetPerWeek)×")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(category.displayColor)
                    .frame(minWidth: 28)

                Button {
                    if category.targetPerWeek < 7 {
                        onFrequencyChange(category.targetPerWeek + 1)
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(
                            category.targetPerWeek < 7
                                ? category.displayColor
                                : Color.secondary.opacity(0.4)
                        )
                }
                .disabled(category.targetPerWeek >= 7)
            }
            .font(.title2)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 13))
                    .foregroundStyle(.red.opacity(0.7))
            }
            .padding(.leading, 4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Excluded Workout Type Tile

private struct ExcludedWorkoutTile: View {
    let template: WorkoutCategory
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: template.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(.secondary)
                    .frame(height: 36)
                Text(template.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Image(systemName: "eye.slash.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(0.55)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Workout Type Tile

private struct WorkoutTile: View {
    let template: WorkoutCategory
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                Image(systemName: template.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(template.displayColor)
                    .frame(height: 36)
                Text(template.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
