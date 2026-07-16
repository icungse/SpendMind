//
//  BudgetAlertEvaluatorTests.swift
//  SpendMindTests
//
//  Created by Icung on 16/07/26.
//

import XCTest
@testable import SpendMind

final class BudgetAlertEvaluatorTests: XCTestCase {
    func testThresholdCrossingTriggersAlert() throws {
        let result = try BudgetAlertEvaluator().evaluate(progress: progress(spent: 80), previousState: nil)

        XCTAssertEqual(result.event, .thresholdReached)
        XCTAssertEqual(result.state.status, .warning)
    }

    func testExceedingLimitTriggersAlert() throws {
        let result = try BudgetAlertEvaluator().evaluate(
            progress: progress(spent: 101),
            previousState: BudgetAlertState(budgetID: budgetID, status: .warning)
        )

        XCTAssertEqual(result.event, .budgetExceeded)
        XCTAssertEqual(result.state.status, .exceeded)
    }

    func testRepeatedUpdatesDoNotDuplicateAlerts() throws {
        let warning = try BudgetAlertEvaluator().evaluate(
            progress: progress(spent: 90),
            previousState: BudgetAlertState(budgetID: budgetID, status: .warning)
        )
        let exceeded = try BudgetAlertEvaluator().evaluate(
            progress: progress(spent: 120),
            previousState: BudgetAlertState(budgetID: budgetID, status: .exceeded)
        )

        XCTAssertNil(warning.event)
        XCTAssertNil(exceeded.event)
    }

    func testDroppingBelowThresholdResetsFutureEligibility() throws {
        let evaluator = BudgetAlertEvaluator()
        let safe = try evaluator.evaluate(
            progress: progress(spent: 70),
            previousState: BudgetAlertState(budgetID: budgetID, status: .warning)
        )
        let warningAgain = try evaluator.evaluate(progress: progress(spent: 80), previousState: safe.state)

        XCTAssertNil(safe.event)
        XCTAssertEqual(safe.state.status, .safe)
        XCTAssertEqual(warningAgain.event, .thresholdReached)
    }

    private let budgetID = UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()

    private func progress(spent: Decimal) throws -> BudgetProgress {
        BudgetProgress(budget: try budget(), spentAmount: spent)
    }

    private func budget() throws -> Budget {
        try Budget(
            id: budgetID,
            name: "Monthly Budget",
            amount: 100,
            period: .monthly,
            startDate: .now,
            endDate: .now,
            alertThreshold: 0.8
        )
    }
}
