//
//  DateService.swift
//  SpendMind
//
//  Created by Icung on 05/07/26.
//

import Foundation

struct DateService {
    private let calendar: Calendar
    private let locale: Locale
    private let now: () -> Date

    init(
        calendar: Calendar = .current,
        locale: Locale = .current,
        now: @escaping () -> Date = Date.init
    ) {
        self.calendar = calendar
        self.locale = locale
        self.now = now
    }

    func relativeString(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.unitsStyle = .full

        return formatter.localizedString(for: date, relativeTo: now())
    }

    func format(
        _ date: Date,
        dateStyle: DateFormatter.Style = .medium,
        timeStyle: DateFormatter.Style = .none
    ) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.timeZone = calendar.timeZone
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle

        return formatter.string(from: date)
    }

    func isToday(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: now())
    }

    func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    func startOfMonth(for date: Date) -> Date {
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? startOfDay(for: date)
    }

    func dateIntervalOfMonth(containing date: Date) -> DateInterval? {
        calendar.dateInterval(of: .month, for: date)
    }
}
