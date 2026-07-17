//
//  BudgetProgressTests.swift
//  VeyraTests
//
//  Created by Icung on 13/07/26.
//

import XCTest
@testable import Veyra

final class BudgetProgressTests: XCTestCase {
    func testZeroSpendingIsSafe() throws {
        let progress = BudgetProgress(budget: try makeBudget(), spentAmount: 0)

        XCTAssertEqual(progress.remainingAmount, 100)
        XCTAssertEqual(progress.progress, 0)
        XCTAssertEqual(progress.status, .safe)
    }

    func testPartialSpendingBelowThresholdIsSafe() throws {
        let progress = BudgetProgress(budget: try makeBudget(), spentAmount: 50)

        XCTAssertEqual(progress.remainingAmount, 50)
        XCTAssertEqual(progress.progress, 0.5)
        XCTAssertEqual(progress.status, .safe)
    }

    func testThresholdReachedIsWarning() throws {
        let progress = BudgetProgress(budget: try makeBudget(), spentAmount: 80)

        XCTAssertEqual(progress.remainingAmount, 20)
        XCTAssertEqual(progress.progress, 0.8)
        XCTAssertEqual(progress.status, .warning)
    }

    func testExactLimitIsWarning() throws {
        let progress = BudgetProgress(budget: try makeBudget(), spentAmount: 100)

        XCTAssertEqual(progress.remainingAmount, 0)
        XCTAssertEqual(progress.progress, 1)
        XCTAssertEqual(progress.status, .warning)
    }

    func testExceededBudgetSupportsProgressGreaterThanOne() throws {
        let progress = BudgetProgress(budget: try makeBudget(), spentAmount: 125)

        XCTAssertEqual(progress.remainingAmount, -25)
        XCTAssertEqual(progress.progress, 1.25)
        XCTAssertEqual(progress.status, .exceeded)
    }

    private func makeBudget() throws -> Budget {
        try Budget(
            name: "Monthly spending",
            amount: 100,
            period: .monthly,
            startDate: .now,
            endDate: .now,
            alertThreshold: 0.8
        )
    }
}
