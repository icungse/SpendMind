//
//  BudgetTests.swift
//  VeyraTests
//
//  Created by Icung on 13/07/26.
//

import XCTest
@testable import Veyra

final class BudgetTests: XCTestCase {
    func testCreatesTotalBudget() throws {
        let budget = try Budget(
            name: "Monthly spending",
            amount: 1_000,
            period: .monthly,
            startDate: Date(timeIntervalSince1970: 1_000),
            endDate: Date(timeIntervalSince1970: 2_000),
            alertThreshold: 0.8
        )

        XCTAssertNil(budget.categoryID)
        XCTAssertTrue(budget.isTotalBudget)
        XCTAssertFalse(budget.isCategoryBudget)
        XCTAssertEqual(budget.amount, 1_000)
        XCTAssertEqual(budget.alertThreshold, 0.8)
    }

    func testCreatesCategoryBudget() throws {
        let categoryID = UUID()
        let budget = try Budget(
            categoryID: categoryID,
            name: "Food",
            amount: 500,
            period: .monthly,
            startDate: .now,
            endDate: .now,
            alertThreshold: 1
        )

        XCTAssertEqual(budget.categoryID, categoryID)
        XCTAssertFalse(budget.isTotalBudget)
        XCTAssertTrue(budget.isCategoryBudget)
    }

    func testBudgetPeriodSupportsMonthlyOnly() {
        XCTAssertEqual(BudgetPeriod.allCases, [.monthly])
        XCTAssertEqual(BudgetPeriod.monthly.rawValue, "monthly")
        XCTAssertEqual(String(localized: BudgetPeriod.monthly.localizedTitle), "Monthly")
    }

    func testRejectsInvalidAmounts() {
        XCTAssertThrowsError(
            try Budget(
                name: "Invalid",
                amount: 0,
                period: .monthly,
                startDate: .now,
                endDate: .now,
                alertThreshold: 0.8
            )
        ) { error in
            XCTAssertEqual(error as? AppError, .validation("Budget amount must be greater than zero."))
        }

        XCTAssertThrowsError(
            try Budget(
                name: "Invalid",
                amount: -1,
                period: .monthly,
                startDate: .now,
                endDate: .now,
                alertThreshold: 0.8
            )
        ) { error in
            XCTAssertEqual(error as? AppError, .validation("Budget amount must be greater than zero."))
        }
    }

    func testRejectsInvalidAlertThresholds() {
        XCTAssertThrowsError(
            try Budget(
                name: "Invalid",
                amount: 100,
                period: .monthly,
                startDate: .now,
                endDate: .now,
                alertThreshold: -0.1
            )
        ) { error in
            XCTAssertEqual(error as? AppError, .validation("Budget alert threshold must be between 0 and 1."))
        }

        XCTAssertThrowsError(
            try Budget(
                name: "Invalid",
                amount: 100,
                period: .monthly,
                startDate: .now,
                endDate: .now,
                alertThreshold: 1.1
            )
        ) { error in
            XCTAssertEqual(error as? AppError, .validation("Budget alert threshold must be between 0 and 1."))
        }
    }

    func testDatesUseProvidedCalendarStartOfDay() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 7 * 60 * 60))
        let startDate = Date(timeIntervalSince1970: 1_000_000)
        let endDate = Date(timeIntervalSince1970: 2_000_000)

        let budget = try Budget(
            name: "Monthly spending",
            amount: 1_000,
            period: .monthly,
            startDate: startDate,
            endDate: endDate,
            alertThreshold: 0.8,
            calendar: calendar
        )

        XCTAssertEqual(budget.startDate, calendar.startOfDay(for: startDate))
        XCTAssertEqual(budget.endDate, calendar.startOfDay(for: endDate))
    }

    func testActiveBudgetConflictsWithSameCategoryAndPeriod() throws {
        let categoryID = UUID()
        let first = try Budget(
            categoryID: categoryID,
            name: "Food",
            amount: 500,
            period: .monthly,
            startDate: .now,
            endDate: .now,
            alertThreshold: 0.8
        )
        let second = try Budget(
            categoryID: categoryID,
            name: "Food again",
            amount: 700,
            period: .monthly,
            startDate: .now,
            endDate: .now,
            alertThreshold: 0.8
        )
        let inactive = try Budget(
            categoryID: categoryID,
            name: "Food inactive",
            amount: 100,
            period: .monthly,
            startDate: .now,
            endDate: .now,
            alertThreshold: 0.8,
            isActive: false
        )

        XCTAssertTrue(first.conflictsWith(second))
        XCTAssertFalse(first.conflictsWith(inactive))
    }
}
