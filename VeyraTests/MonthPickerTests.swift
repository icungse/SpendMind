//
//  MonthPickerTests.swift
//  VeyraTests
//
//  Created by Icung on 16/07/26.
//

import XCTest
@testable import Veyra

final class MonthPickerTests: XCTestCase {
    func testCurrentMonthIsFirstSelectableMonthForNewBudgets() throws {
        let currentDate = date(year: 2026, month: 7, day: 16)

        let options = MonthPicker.options(currentDate: currentDate, calendar: calendar, futureMonthCount: 2)

        XCTAssertEqual(options.first, date(year: 2026, month: 7, day: 1))
        XCTAssertEqual(options, [
            date(year: 2026, month: 7, day: 1),
            date(year: 2026, month: 8, day: 1),
            date(year: 2026, month: 9, day: 1)
        ])
    }

    func testPreviousMonthIsIncludedOnlyWhenAlreadySelected() {
        let currentDate = date(year: 2026, month: 7, day: 16)
        let selectedDate = date(year: 2026, month: 6, day: 20)

        let options = MonthPicker.options(
            currentDate: currentDate,
            selectedDate: selectedDate,
            calendar: calendar,
            futureMonthCount: 1
        )

        XCTAssertEqual(options, [
            date(year: 2026, month: 6, day: 1),
            date(year: 2026, month: 7, day: 1),
            date(year: 2026, month: 8, day: 1)
        ])
    }

    func testMonthLabelIsLocalized() {
        let label = MonthPicker.label(
            for: date(year: 2026, month: 7, day: 1),
            calendar: calendar,
            locale: Locale(identifier: "id_ID")
        )

        XCTAssertTrue(label.localizedCaseInsensitiveContains("Juli"))
        XCTAssertTrue(label.contains("2026"))
    }

    func testDecemberToJanuaryTransition() {
        let currentDate = date(year: 2026, month: 12, day: 15)

        let options = MonthPicker.options(currentDate: currentDate, calendar: calendar, futureMonthCount: 2)

        XCTAssertEqual(options, [
            date(year: 2026, month: 12, day: 1),
            date(year: 2027, month: 1, day: 1),
            date(year: 2027, month: 2, day: 1)
        ])
    }

    func testStartOfMonthUsesProvidedCalendarTimeZone() throws {
        var jakartaCalendar = Calendar(identifier: .gregorian)
        jakartaCalendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Jakarta"))
        let date = DateComponents(
            calendar: jakartaCalendar,
            timeZone: jakartaCalendar.timeZone,
            year: 2027,
            month: 1,
            day: 31,
            hour: 23
        ).date ?? Date()

        let monthStart = try XCTUnwrap(MonthPicker.startOfMonth(for: date, calendar: jakartaCalendar))
        let components = jakartaCalendar.dateComponents([.year, .month, .day], from: monthStart)

        XCTAssertEqual(components.year, 2027)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 1)
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        DateComponents(calendar: calendar, year: year, month: month, day: day).date ?? Date()
    }
}
