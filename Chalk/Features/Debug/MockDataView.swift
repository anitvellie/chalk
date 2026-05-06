#if DEBUG
// MockDataView.swift
// Chalk — Debug-only mock data picker

import SwiftUI

struct MockDataView: View {

    @EnvironmentObject var appState: AppState
    @StateObject private var manager = MockDataManager()

    var body: some View {
        List {
            if appState.isMockActive {
                activeBanner
            }

            presetSection

            if manager.selectedPreset == .custom {
                customBuilderSection
            }
        }
        .navigationTitle("Mock Data")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            applyBar
        }
    }

    // MARK: - Sections

    private var activeBanner: some View {
        Section {
            HStack(spacing: 10) {
                Image(systemName: "flask.fill")
                    .foregroundStyle(.orange)
                Text("Mock data is active")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Button("Clear") {
                    Task { await appState.clearMock() }
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.red)
            }
        }
    }

    private var presetSection: some View {
        Section("Preset") {
            ForEach(MockDataManager.Preset.allCases) { preset in
                presetRow(preset)
            }
        }
    }

    @ViewBuilder
    private var customBuilderSection: some View {
        let days = manager.weekDays()
        Section("Schedule") {
            ForEach(0..<7, id: \.self) { i in
                CustomDayRow(
                    dayName: MockDataManager.dayNames[i],
                    date: days.indices.contains(i) ? days[i] : Date(),
                    dayIndex: i,
                    categories: appState.categories,
                    schedule: $manager.customSchedule
                )
            }
        }
    }

    // MARK: - Preset Row

    private func presetRow(_ preset: MockDataManager.Preset) -> some View {
        Button {
            manager.selectedPreset = preset
        } label: {
            HStack(spacing: 12) {
                Image(systemName: preset.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.blue)
                    .frame(width: 32, height: 32)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.rawValue)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    Text(preset.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if manager.selectedPreset == preset {
                    Image(systemName: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.blue)
                }
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Apply Bar

    private var applyBar: some View {
        Button {
            let entries = manager.generateEntries(for: appState.categories)
            appState.applyMock(entries: entries)
        } label: {
            Text(appState.isMockActive ? "Re-apply Preset" : "Apply Mock")
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(hex: "#135bec"))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .background(.regularMaterial)
    }
}

// MARK: - CustomDayRow

private struct CustomDayRow: View {

    let dayName: String
    let date: Date
    let dayIndex: Int
    let categories: [WorkoutCategory]
    @Binding var schedule: [Int: [UUID]]

    @State private var showingPicker = false

    private var scheduledIds: [UUID] { schedule[dayIndex] ?? [] }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(dayName)
                    .font(.subheadline.weight(.semibold))
                Text(date, format: .dateTime.month(.abbreviated).day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    showingPicker = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                        .imageScale(.medium)
                }
                .confirmationDialog("Add to \(dayName)", isPresented: $showingPicker) {
                    ForEach(categories) { category in
                        Button(category.name) {
                            schedule[dayIndex, default: []].append(category.id)
                        }
                    }
                }
            }

            if !scheduledIds.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(scheduledIds.enumerated()), id: \.offset) { (index, categoryId) in
                            if let category = categories.first(where: { $0.id == categoryId }) {
                                workoutChip(category: category, index: index)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func workoutChip(category: WorkoutCategory, index: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: category.icon)
                .font(.caption2.weight(.semibold))
            Text(category.name)
                .font(.caption.weight(.medium))
            Button {
                schedule[dayIndex]?.remove(at: index)
                if schedule[dayIndex]?.isEmpty == true {
                    schedule.removeValue(forKey: dayIndex)
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
            }
        }
        .foregroundStyle(category.displayColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(category.displayColor.opacity(0.12))
        .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        MockDataView()
            .environmentObject(AppState())
    }
}
#endif
