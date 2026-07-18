//
//  MockServices.swift
//  VeyraTests
//
//  Created by Icung on 05/07/26.
//

import Foundation
@testable import Veyra

final class MockAppSettingsManager: AppSettingsManagerProtocol, @unchecked Sendable {
    var stubbedSettings: AppSettings = .default
    var loadCalled = false
    var saveCalled = false
    var savedSettings: AppSettings?

    func load() -> AppSettings {
        loadCalled = true
        return stubbedSettings
    }

    func save(_ settings: AppSettings) {
        saveCalled = true
        savedSettings = settings
    }
}

final class MockDateService: DateServiceProtocol, @unchecked Sendable {
    var stubbedRelativeString = "just now"
    var stubbedFormattedString = "Jul 5, 2026"
    var stubbedIsToday = true
    var stubbedStartOfDay = Date()
    var stubbedStartOfMonth = Date()
    var stubbedDateIntervalOfMonth: DateInterval?

    var relativeStringCalled = false
    var formatCalled = false
    var isTodayCalled = false
    var startOfDayCalled = false
    var startOfMonthCalled = false
    var dateIntervalOfMonthCalled = false

    func relativeString(for date: Date) -> String {
        relativeStringCalled = true
        return stubbedRelativeString
    }

    func format(_ date: Date, dateStyle: DateFormatter.Style, timeStyle: DateFormatter.Style) -> String {
        formatCalled = true
        return stubbedFormattedString
    }

    func isToday(_ date: Date) -> Bool {
        isTodayCalled = true
        return stubbedIsToday
    }

    func startOfDay(for date: Date) -> Date {
        startOfDayCalled = true
        return stubbedStartOfDay
    }

    func startOfMonth(for date: Date) -> Date {
        startOfMonthCalled = true
        return stubbedStartOfMonth
    }

    func dateIntervalOfMonth(containing date: Date) -> DateInterval? {
        dateIntervalOfMonthCalled = true
        return stubbedDateIntervalOfMonth
    }
}
