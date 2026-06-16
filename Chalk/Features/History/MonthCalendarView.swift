// MonthCalendarView.swift
// Chalk — History Tab month calendar
//
// Glass card showing the current calendar month. Each day cell shows:
//   • 0 workouts  → day-of-month number (coloured by DayRelation)
//   • 1 workout   → the workout's circle icon
//   • 2 workouts  → longest workout as the main icon + the second as a
//                   smaller icon to its lower-right
//   • 3+ workouts → same as 2, plus a small red count badge
//
// Week start follows the device locale (Calendar.current.firstWeekday).

import SwiftUI

struct MonthCalendarView: View {

    /// All workouts for the current month (library types, hidden excluded upstream).
    let entries: [WorkoutEntry]
    let categories: [WorkoutCategory]

    /// Measured from the grid on first layout; drives cell + icon sizing.
    @State private var columnWidth: CGFloat = 44

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    private var iconSize: CGFloat { columnWidth * 0.7 }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(monthTitle)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.primary)

            // Weekday header — narrow symbols ordered by first weekday.
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day grid.
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(Array(gridDays.enumerated()), id: \.offset) { _, day in
                    if let day {
                        CalendarDayCell(
                            day: day,
                            pairs: entriesByDay[calendar.startOfDay(for: day)] ?? [],
                            today: today,
                            iconSize: iconSize
                        )
                        .frame(maxWidth: .infinity)
                    } else {
                        Color.clear.frame(height: iconSize)
                    }
                }
            }
            .background {
                GeometryReader { geo in
                    Color.clear.preference(key: GridWidthKey.self, value: geo.size.width)
                }
            }
            .onPreferenceChange(GridWidthKey.self) { width in
                if width > 0 { columnWidth = width / 7 }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    // MARK: - Data

    private var today: Date { calendar.startOfDay(for: Date()) }

    private var categoryMap: [UUID: WorkoutCategory] {
        Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
    }

    /// Entries grouped by start-of-day, hidden ones excluded.
    private var entriesByDay: [Date: [(WorkoutEntry, WorkoutCategory)]] {
        var dict: [Date: [(WorkoutEntry, WorkoutCategory)]] = [:]
        for entry in entries where !entry.isHidden {
            guard let category = categoryMap[entry.categoryId] else { continue }
            let day = calendar.startOfDay(for: entry.date)
            dict[day, default: []].append((entry, category))
        }
        return dict
    }

    /// Leading `nil`s to align the 1st under its weekday, then each day of month.
    private var gridDays: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: Date()) else {
            return []
        }
        let firstOfMonth = monthInterval.start
        let weekdayOfFirst = calendar.component(.weekday, from: firstOfMonth)
        let leadingBlanks = (weekdayOfFirst - calendar.firstWeekday + 7) % 7
        let dayCount = calendar.range(of: .day, in: .month, for: firstOfMonth)?.count ?? 0

        var result: [Date?] = Array(repeating: nil, count: leadingBlanks)
        for offset in 0..<dayCount {
            result.append(calendar.date(byAdding: .day, value: offset, to: firstOfMonth))
        }
        return result
    }

    private var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "MMM yyyy"
        return f.string(from: Date())
    }

    /// Narrow weekday symbols (M T W …) rotated to start at `firstWeekday`.
    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols // index 0 == Sunday
        let start = calendar.firstWeekday - 1
        return (0..<7).map { symbols[(start + $0) % 7] }
    }
}

// MARK: - Width measurement

/// Reports the grid's measured width so column/icon sizing tracks layout
/// continuously, instead of latching a stale value via a one-shot `.onAppear`.
private struct GridWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

// MARK: - Day Cell

private struct CalendarDayCell: View {

    let day: Date
    let pairs: [(WorkoutEntry, WorkoutCategory)]
    let today: Date
    let iconSize: CGFloat

    private var sorted: [(WorkoutEntry, WorkoutCategory)] {
        pairs.sorted { $0.0.duration > $1.0.duration }
    }

    private var secondarySize: CGFloat { iconSize * 0.75 }
    private var badgeSize: CGFloat { iconSize * 0.42 }

    var body: some View {
        ZStack {
            switch sorted.count {
            case 0:
                Text(dayNumber)
                    .font(.system(size: iconSize * 0.4, weight: .medium))
                    .foregroundStyle(DayRelation(day: day, relativeTo: today).textColor)
            case 1:
                WorkoutCircleIcon(icon: sorted[0].1.icon, isMonochrome: false, size: iconSize)
            default:
                mainPlusSecondary
            }
        }
        .frame(width: iconSize, height: iconSize)
    }

    /// Main (longest) icon with the second workout overlapping its lower-right,
    /// plus a count badge in the top-right when there are 3 or more.
    private var mainPlusSecondary: some View {
        WorkoutCircleIcon(icon: sorted[0].1.icon, isMonochrome: false, size: iconSize)
            .overlay(alignment: .bottomTrailing) {
                ZStack {
                    // Plug the SF Symbol cutout so the main icon doesn't bleed through.
                    Circle()
                        .fill(Color(.systemBackground))
                        .frame(width: secondarySize * 1.18, height: secondarySize * 1.18)
                    WorkoutCircleIcon(icon: sorted[1].1.icon, isMonochrome: false, size: secondarySize)
                }
                .offset(x: secondarySize * 0.30, y: secondarySize * 0.30)
            }
            .overlay(alignment: .topTrailing) {
                if sorted.count >= 3 {
                    countBadge(sorted.count)
                        .offset(x: badgeSize * 0.35, y: -badgeSize * 0.25)
                }
            }
    }

    private func countBadge(_ count: Int) -> some View {
        ZStack {
            Circle().fill(Color.red)
            Text("\(count)")
                .font(.system(size: badgeSize * 0.6, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: badgeSize, height: badgeSize)
    }

    private var dayNumber: String {
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: day)
    }
}
