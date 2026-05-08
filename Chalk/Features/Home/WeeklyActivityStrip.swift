// WeeklyActivityStrip.swift
// Chalk — Weekly Workout Calendar Strip

import SwiftUI

// MARK: - Strip root

struct WeeklyActivityStrip: View {

    let entries: [WorkoutEntry]
    let categories: [WorkoutCategory]

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
                    today: Calendar.current.startOfDay(for: Date())
                )
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

    private enum Relation { case past, today, future }

    private var relation: Relation {
        if day < today { return .past }
        if day == today { return .today }
        return .future
    }

    private var textColor: Color {
        switch relation {
        case .today:  return .primary
        case .past:   return Color(hex: "#D6D6D6")
        case .future: return Color(hex: "#898989")
        }
    }

    /// Entries sorted longest-first.
    private var sorted: [(WorkoutEntry, WorkoutCategory)] {
        pairs.sorted { $0.0.duration > $1.0.duration }
    }

    var body: some View {
        VStack(spacing: 10) {
            iconArea
            Text(dayLetter)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(textColor)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var iconArea: some View {
        switch sorted.count {
        case 0:
            Text(dayNumber)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(textColor)
                .frame(width: 37, height: 37, alignment: .center)
        case 1:
            WorkoutIcon(category: sorted[0].1)
        case 2:
            TwoIconStack(top: sorted[0].1, bottom: sorted[1].1)
        default:
            OverflowIconStack(top: sorted[0].1, bottom: sorted[1].1, totalCount: sorted.count)
        }
    }

    private var dayLetter: String { DateFormatter.narrowWeekday.string(from: day) }
    private var dayNumber: String { DateFormatter.dayOfMonth.string(from: day) }
}

// MARK: - Icon views

private struct WorkoutIcon: View {
    let category: WorkoutCategory

    var body: some View {
        Image(systemName: "\(category.icon).circle.fill")
            .resizable()
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(category.displayColor.gradient)
            .frame(width: 37, height: 37)
    }
}

private struct TwoIconStack: View {
    let top: WorkoutCategory
    let bottom: WorkoutCategory

    // Amount the bottom icon slides up behind the top one.
    // VStack with negative spacing keeps the layout frame layout-correct —
    // no .offset() tricks that fool the VStack spacing in DayColumn.
    private static let overlap: CGFloat = 13

    var body: some View {
        VStack(spacing: -Self.overlap) {
            WorkoutIcon(category: top)
            // ZStack here only to layer the separator behind the bottom icon.
            ZStack {
                // Plugs the transparent cutout in the top icon so the
                // bottom icon's colour doesn't bleed through.
                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: 31, height: 31)
                WorkoutIcon(category: bottom)
            }
        }
    }
}

private struct OverflowIconStack: View {
    let top: WorkoutCategory
    let bottom: WorkoutCategory
    let totalCount: Int

    var body: some View {
        TwoIconStack(top: top, bottom: bottom)
            .overlay(alignment: .topTrailing) {
                ZStack {
                    Circle().fill(Color.red.opacity(1.0))
                    Text("\(totalCount)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 23, height: 23)
                // Sits at the top-right corner of the icon stack, overlapping slightly outward.
                .offset(x: 6, y: 14)
            }
    }
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
