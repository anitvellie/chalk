// WeeklyActivityStrip.swift
// Chalk — Weekly Workout Calendar Strip

import SwiftUI

// MARK: - Strip root

struct WeeklyActivityStrip: View {

    let entries: [WorkoutEntry]
    let categories: [WorkoutCategory]

    /// Measured from the HStack on first layout; drives icon sizing.
    @State private var columnWidth: CGFloat = 50

    private var iconSize: CGFloat { columnWidth * 0.85 }

    private var categoryMap: [UUID: WorkoutCategory] {
        Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
    }

    /// Entries grouped by the start-of-day key, hidden ones excluded.
    private var entriesByDay: [Date: [(WorkoutEntry, WorkoutCategory)]] {
        let cal = Calendar.current
        var dict: [Date: [(WorkoutEntry, WorkoutCategory)]] = [:]
        for entry in entries where !entry.isHidden {
            guard let category = categoryMap[entry.categoryId] else { continue }
            let day = cal.startOfDay(for: entry.date)
            dict[day, default: []].append((entry, category))
        }
        return dict
    }

    /// The 7 days of the current week starting from the locale's first weekday.
    private var weekDays: [Date] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let weekday = cal.component(.weekday, from: today)
        let daysFromStart = (weekday - cal.firstWeekday + 7) % 7
        guard let weekStart = cal.date(byAdding: .day, value: -daysFromStart, to: today) else {
            return []
        }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: weekStart) }
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(weekDays, id: \.self) { day in
                DayColumn(
                    day: day,
                    pairs: entriesByDay[day] ?? [],
                    today: Calendar.current.startOfDay(for: Date()),
                    iconSize: iconSize
                )
            }
        }
        .background {
            GeometryReader { geo in
                Color.clear.onAppear { columnWidth = geo.size.width / 7 }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 20)
        .modifier(GlassCardModifier())
    }
}

// MARK: - Day column

private struct DayColumn: View {

    let day: Date
    let pairs: [(WorkoutEntry, WorkoutCategory)]
    let today: Date
    let iconSize: CGFloat

    private var textColor: Color {
        DayRelation(day: day, relativeTo: today).textColor
    }

    private var sorted: [(WorkoutEntry, WorkoutCategory)] {
        pairs.sorted { $0.0.duration > $1.0.duration }
    }

    var body: some View {
        VStack(spacing: 10) {
            StripDayIconArea(
                icons: sorted.map(\.1.icon),
                isMonochrome: false,
                iconSize: iconSize,
                emptyText: dayNumber,
                textColor: textColor
            )
            Text(dayLetter)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(textColor)
        }
        .frame(maxWidth: .infinity)
    }

    private var dayLetter: String { DateFormatter.narrowWeekday.string(from: day) }
    private var dayNumber: String { DateFormatter.dayOfMonth.string(from: day) }
}

// MARK: - Date formatters

private extension DateFormatter {
    /// Single-character weekday: M T W T F S S
    static let narrowWeekday: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEEE"
        return f
    }()

    /// Day-of-month number: 1, 2, … 31
    static let dayOfMonth: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f
    }()
}
