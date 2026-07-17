//
//  MonthPicker.swift
//  Veyra
//
//  Created by Icung on 16/07/26.
//

import SwiftUI

struct MonthPicker: View {
    @Binding var selection: Date
    let currentDate: Date
    let selectedDate: Date?
    let calendar: Calendar
    let locale: Locale
    let futureMonthCount: Int

    init(
        selection: Binding<Date>,
        currentDate: Date = .now,
        selectedDate: Date? = nil,
        calendar: Calendar = .current,
        locale: Locale = .current,
        futureMonthCount: Int = 24
    ) {
        self._selection = selection
        self.currentDate = currentDate
        self.selectedDate = selectedDate
        self.calendar = calendar
        self.locale = locale
        self.futureMonthCount = futureMonthCount
    }

    var body: some View {
        Picker("Month", selection: $selection) {
            ForEach(Self.options(
                currentDate: currentDate,
                selectedDate: selectedDate ?? selection,
                calendar: calendar,
                futureMonthCount: futureMonthCount
            ), id: \.self) { month in
                Text(Self.label(for: month, calendar: calendar, locale: locale))
                    .tag(month)
            }
        }
        .accessibilityLabel("Budget Month")
    }

    nonisolated static func options(
        currentDate: Date,
        selectedDate: Date? = nil,
        calendar: Calendar = .current,
        futureMonthCount: Int = 24
    ) -> [Date] {
        guard let currentMonth = startOfMonth(for: currentDate, calendar: calendar) else { return [] }

        var months: [Date] = []
        if let selectedDate,
           let selectedMonth = startOfMonth(for: selectedDate, calendar: calendar),
           selectedMonth < currentMonth {
            months.append(selectedMonth)
        }

        // 24 future months is enough for v0.3.0; make it configurable only when product asks.
        for offset in 0...futureMonthCount {
            guard let month = calendar.date(byAdding: .month, value: offset, to: currentMonth) else { continue }
            months.append(month)
        }

        return Array(Set(months)).sorted()
    }

    nonisolated static func label(for month: Date, calendar: Calendar = .current, locale: Locale = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.timeZone = calendar.timeZone
        formatter.setLocalizedDateFormatFromTemplate("MMMM yyyy")

        return formatter.string(from: month)
    }

    nonisolated static func startOfMonth(for date: Date, calendar: Calendar = .current) -> Date? {
        calendar.dateInterval(of: .month, for: date)?.start
    }
}
