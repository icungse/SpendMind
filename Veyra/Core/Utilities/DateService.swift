//
//  DateService.swift
//  Veyra
//
//  Created by Icung on 05/07/26.
//

import Foundation

protocol DateServiceProtocol: Sendable {
    func relativeString(for date: Date) -> String
    func format(_ date: Date, dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String
    func isToday(_ date: Date) -> Bool
    func startOfDay(for date: Date) -> Date
    func startOfMonth(for date: Date) -> Date
    func dateIntervalOfMonth(containing date: Date) -> DateInterval?
}

extension DateServiceProtocol {
    func format(
        _ date: Date,
        dateStyle: DateFormatter.Style = .medium,
        timeStyle: DateFormatter.Style = .none
    ) -> String {
        format(date, dateStyle: dateStyle, timeStyle: timeStyle)
    }
}

struct DateService: DateServiceProtocol, Sendable {
    private let calendar: Calendar
    private let locale: Locale
    private let now: @Sendable () -> Date

    init(
        calendar: Calendar = .current,
        locale: Locale = .current,
        now: @escaping @Sendable () -> Date = Date.init
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
