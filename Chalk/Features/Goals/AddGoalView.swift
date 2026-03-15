// AddGoalView.swift
// Chalk — Goal Creation Sheet
//
// Presented as a sheet from the floating Add button.
// Shows a 2-column grid of available workout types (those not already tracked),
// a frequency stepper, and a primary "Add Goal" CTA.

import SwiftUI

struct AddGoalView: View {

    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTemplate: WorkoutCategory? = nil
    @State private var targetPerWeek: Int = 3

    // Library entries whose HK activity types aren't already tracked
    private var availableTemplates: [WorkoutCategory] {
        let tracked = Set(appState.categories.flatMap { $0.activityTypeRawValues })
        return HealthKitManager.categoryLibrary.filter { template in
            !template.activityTypeRawValues.contains(where: { tracked.contains($0) })
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {

                    // ── Heading ──
                    VStack(alignment: .leading, spacing: 6) {
                        Text("What are your\nfitness targets?")
                            .font(.system(size: 28, weight: .bold))
                            .lineSpacing(2)
                        Text("Choose a workout type and set your weekly frequency.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)

                    // ── Workout type grid ──
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("Workout Type")

                        if availableTemplates.isEmpty {
                            Text("You've added all available goal types.")
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
                                    WorkoutTypeTile(
                                        template: template,
                                        isSelected: selectedTemplate?.id == template.id
                                    ) {
                                        selectTemplate(template)
                                    }
                                }
                            }
                        }
                    }

                    // ── Frequency stepper (appears after selection) ──
                    if let template = selectedTemplate {
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader("Frequency")

                            FrequencyCard(
                                targetPerWeek: $targetPerWeek,
                                accentColor: Color(hex: template.colorHex)
                            )
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .chalkBackground()
            .animation(.spring(duration: 0.3), value: selectedTemplate?.id)
            .navigationTitle("Add Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                addButton
            }
        }
    }

    // MARK: - Sub-views

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(Color(hex: "#135bec"))
            .tracking(1)
    }

    private var addButton: some View {
        Button {
            commitSelection()
        } label: {
            Text(selectedTemplate.map { "Add \($0.name)" } ?? "Select a Workout Type")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    selectedTemplate != nil
                        ? Color(hex: "#135bec")
                        : Color.secondary.opacity(0.3),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
        }
        .disabled(selectedTemplate == nil)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(uiColor: .separator))
                .frame(height: 0.5)
        }
    }

    // MARK: - Actions

    private func selectTemplate(_ template: WorkoutCategory) {
        if selectedTemplate?.id == template.id {
            // Tapping the same tile deselects
            selectedTemplate = nil
        } else {
            selectedTemplate = template
            targetPerWeek = template.targetPerWeek
        }
    }

    private func commitSelection() {
        guard var category = selectedTemplate else { return }
        category.targetPerWeek = targetPerWeek
        appState.addCategory(category)
        dismiss()
        Task { await appState.refreshGoals() }
    }
}

// MARK: - Workout Type Tile

private struct WorkoutTypeTile: View {

    let template: WorkoutCategory
    let isSelected: Bool
    let onTap: () -> Void

    private var categoryColor: Color { Color(hex: template.colorHex) }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                Image(systemName: template.icon)
                    .font(.system(size: 28, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? categoryColor : Color.secondary)
                    .frame(height: 36)

                Text(template.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isSelected ? categoryColor : Color.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        isSelected ? categoryColor : Color.clear,
                        lineWidth: 2
                    )
            }
            .shadow(
                color: isSelected ? categoryColor.opacity(0.2) : Color.clear,
                radius: 8, y: 4
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.25), value: isSelected)
    }
}

// MARK: - Frequency Card

private struct FrequencyCard: View {

    @Binding var targetPerWeek: Int
    let accentColor: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Sessions per week")
                    .font(.body.weight(.medium))
                Text(frequencyDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 16) {
                Button {
                    if targetPerWeek > 1 { targetPerWeek -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(targetPerWeek > 1 ? accentColor : Color.secondary)
                }
                .disabled(targetPerWeek <= 1)

                Text("\(targetPerWeek)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(accentColor)
                    .frame(minWidth: 32, alignment: .center)

                Button {
                    if targetPerWeek < 7 { targetPerWeek += 1 }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(targetPerWeek < 7 ? accentColor : Color.secondary)
                }
                .disabled(targetPerWeek >= 7)
            }
        }
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.5), lineWidth: 1)
        }
    }

    private var frequencyDescription: String {
        switch targetPerWeek {
        case 1:       return "Light — once a week"
        case 2:       return "Easy — twice a week"
        case 3:       return "Moderate — 3× a week"
        case 4:       return "Active — 4× a week"
        case 5:       return "Dedicated — 5× a week"
        case 6:       return "Intensive — 6× a week"
        default:      return "Daily"
        }
    }
}
