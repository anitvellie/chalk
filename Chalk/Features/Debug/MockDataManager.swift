#if DEBUG
// MockDataManager.swift
// Chalk — Debug-only mock data generator

import Foundation

@MainActor
final class MockDataManager: ObservableObject {

    // MARK: - Preset

    enum Preset: String, CaseIterable, Identifiable {
        case emptyWeek       = "Empty Week"
        case allCompleted    = "All Goals Completed"
        case workoutEveryDay = "Workout Every Day"
        case twoEveryOtherDay = "2 Workouts Every Other Day"
        case mixed           = "Mixed Progress"
        case custom          = "Custom"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .emptyWeek:        return "calendar.badge.minus"
            case .allCompleted:     return "checkmark.seal.fill"
            case .workoutEveryDay:  return "flame.fill"
            case .twoEveryOtherDay: return "repeat"
            case .mixed:            return "chart.bar.fill"
            case .custom:           return "slider.horizontal.3"
            }
        }

        var description: String {
            switch self {
            case .emptyWeek:        return "No workouts recorded this week"
            case .allCompleted:     return "Every goal met or exceeded"
            case .workoutEveryDay:  return "One workout logged each day"
            case .twoEveryOtherDay: return "Double sessions on alternating days"
            case .mixed:            return "Some goals on track, some falling behind"
            case .custom:           return "Pick exactly what goes on each day"
            }
        }
    }

    // MARK: - State

    @Published var selectedPreset: Preset = .emptyWeek
    /// dayIndex (0 = Mon … 6 = Sun) → ordered list of categoryIds
    @Published var customSchedule: [Int: [UUID]] = [:]

    // MARK: - Week Helpers

    func weekDays() -> [Date] {
        let calendar = Calendar.iso8601
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: Date()) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekInterval.start) }
    }

    static let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

    // MARK: - Entry Generation

    func generateEntries(for categories: [WorkoutCategory]) -> [WorkoutEntry] {
        guard !categories.isEmpty else { return [] }
        let days = weekDays()
        guard days.count == 7 else { return [] }

        switch selectedPreset {
        case .emptyWeek:
            return []

        case .allCompleted:
            return categories.flatMap { category in
                (0..<category.targetPerWeek).map { i in
                    makeEntry(category: category, on: days[i % 7], hour: 9 + (i % 3) * 4)
                }
            }

        case .workoutEveryDay:
            return days.enumerated().map { (i, day) in
                makeEntry(category: categories[i % categories.count], on: day)
            }

        case .twoEveryOtherDay:
            return days.enumerated().flatMap { (i, day) -> [WorkoutEntry] in
                guard i % 2 == 0 else { return [] }
                let cat1 = categories[0]
                let cat2 = categories.count > 1 ? categories[1] : categories[0]
                return [
                    makeEntry(category: cat1, on: day, hour: 9),
                    makeEntry(category: cat2, on: day, hour: 18)
                ]
            }

        case .mixed:
            return categories.enumerated().flatMap { (i, category) -> [WorkoutEntry] in
                let count: Int
                switch i % 3 {
                case 0: count = max(1, category.targetPerWeek - 1)   // behind
                case 1: count = category.targetPerWeek               // complete
                default: count = max(1, category.targetPerWeek / 2)  // halfway
                }
                return (0..<count).map { j in makeEntry(category: category, on: days[j % 7]) }
            }

        case .custom:
            return customSchedule.sorted(by: { $0.key < $1.key }).flatMap { (dayIndex, categoryIds) -> [WorkoutEntry] in
                guard dayIndex < days.count else { return [] }
                return categoryIds.enumerated().compactMap { (slot, categoryId) -> WorkoutEntry? in
                    guard let category = categories.first(where: { $0.id == categoryId }) else { return nil }
                    return makeEntry(category: category, on: days[dayIndex], hour: 9 + (slot % 4) * 3)
                }
            }
        }
    }

    // MARK: - Private

    private func makeEntry(category: WorkoutCategory, on date: Date, hour: Int = 10) -> WorkoutEntry {
        let adjusted = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: date) ?? date
        return WorkoutEntry(
            categoryId: category.id,
            date: adjusted,
            duration: 3600,
            source: .manual
        )
    }
}
#endif
