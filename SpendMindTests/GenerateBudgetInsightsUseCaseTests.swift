//
//  GenerateBudgetInsightsUseCaseTests.swift
//  SpendMindTests
//
//  Created by Icung on 17/07/26.
//

import XCTest
@testable import SpendMind

final class GenerateBudgetInsightsUseCaseTests: XCTestCase {
    func testOverallInsightIncludesPercentageAndRemainingDays() throws {
        let progress = BudgetProgress(budget: try budget(name: "Total", amount: 100), spentAmount: 65)

        let insights = useCase.execute(progress: [progress], referenceDate: july(20))

        XCTAssertEqual(insights.first?.id, "overallMonthlyProgress")
        XCTAssertEqual(insights.first?.message, "You have used 65% of your monthly budget with 12 days remaining.")
    }

    func testCategoryBudgetAtApproachingThresholdCreatesInsight() throws {
        let food = BudgetProgress(budget: try budget(categoryID: UUID(), name: "Food", amount: 100), spentAmount: 80)

        let insights = useCase.execute(progress: [food], referenceDate: july(20))

        XCTAssertTrue(insights.contains(BudgetInsight(
            id: "categoryApproachingLimit",
            message: "Your Food budget is close to its limit."
        )))
    }

    func testCategoryBudgetBelowApproachingThresholdDoesNotCreateWarningInsight() throws {
        let food = BudgetProgress(budget: try budget(categoryID: UUID(), name: "Food", amount: 100), spentAmount: 79)

        let insights = useCase.execute(progress: [food], referenceDate: july(20))

        XCTAssertFalse(insights.contains { $0.id == "categoryApproachingLimit" })
    }

    func testExceededCategoryBudgetCreatesSingularInsight() throws {
        let food = BudgetProgress(budget: try budget(categoryID: UUID(), name: "Food", amount: 100), spentAmount: 101)

        let insights = useCase.execute(progress: [food], referenceDate: july(20))

        XCTAssertTrue(insights.contains(BudgetInsight(
            id: "categoryBudgetsExceeded",
            message: "You have exceeded 1 category budget this month."
        )))
    }

    func testMultipleExceededCategoryBudgetsCreatesPluralInsight() throws {
        let food = BudgetProgress(budget: try budget(categoryID: UUID(), name: "Food", amount: 100), spentAmount: 101)
        let bills = BudgetProgress(budget: try budget(categoryID: UUID(), name: "Bills", amount: 100), spentAmount: 125)

        let insights = useCase.execute(progress: [food, bills], referenceDate: july(20))

        XCTAssertTrue(insights.contains(BudgetInsight(
            id: "categoryBudgetsExceeded",
            message: "You have exceeded 2 category budgets this month."
        )))
    }

    func testEmptyBudgetsCreateNoInsights() {
        XCTAssertEqual(useCase.execute(progress: [], referenceDate: july(20)), [])
    }

    func testMissingCategoryMetadataUsesBudgetName() throws {
        let budget = BudgetProgress(budget: try budget(categoryID: UUID(), name: "Groceries", amount: 100), spentAmount: 80)

        let insights = useCase.execute(progress: [budget], referenceDate: july(20))

        XCTAssertTrue(insights.contains(BudgetInsight(
            id: "categoryApproachingLimit",
            message: "Your Groceries budget is close to its limit."
        )))
    }

    func testZeroValueBudgetsAreRejectedBeforeInsightGeneration() {
        XCTAssertThrowsError(try budget(name: "Invalid", amount: 0))
    }

    func testExpensesWithoutMatchingBudgetsCreateNoInsights() {
        XCTAssertEqual(useCase.execute(progress: [], referenceDate: july(20)), [])
    }

    func testInsightOrderingIsDeterministic() throws {
        let total = BudgetProgress(budget: try budget(name: "Total", amount: 100), spentAmount: 65)
        let food = BudgetProgress(budget: try budget(categoryID: UUID(), name: "Food", amount: 100), spentAmount: 80)
        let bills = BudgetProgress(budget: try budget(categoryID: UUID(), name: "Bills", amount: 100), spentAmount: 125)

        let insights = useCase.execute(progress: [food, bills, total], referenceDate: july(20))

        XCTAssertEqual(insights.map(\.id), [
            "overallMonthlyProgress",
            "categoryApproachingLimit",
            "categoryBudgetsExceeded"
        ])
    }

    func testWarningTieBreakUsesBudgetName() throws {
        let food = BudgetProgress(budget: try budget(categoryID: UUID(), name: "Food", amount: 100), spentAmount: 80)
        let bills = BudgetProgress(budget: try budget(categoryID: UUID(), name: "Bills", amount: 100), spentAmount: 80)

        let insights = useCase.execute(progress: [food, bills], referenceDate: july(20))

        XCTAssertEqual(
            insights.first { $0.id == "categoryApproachingLimit" }?.message,
            "Your Bills budget is close to its limit."
        )
    }

    func testPastBudgetEndDateClampsRemainingDaysToZero() throws {
        let progress = BudgetProgress(budget: try budget(name: "Total", amount: 100), spentAmount: 65)

        let insights = useCase.execute(progress: [progress], referenceDate: date(year: 2026, month: 8, day: 10))

        XCTAssertEqual(insights.first?.message, "You have used 65% of your monthly budget with 0 days remaining.")
    }

    private var useCase: DefaultGenerateBudgetInsightsUseCase {
        DefaultGenerateBudgetInsightsUseCase(calendar: calendar)
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }

    private func budget(categoryID: UUID? = nil, name: String, amount: Decimal) throws -> Budget {
        try Budget(
            categoryID: categoryID,
            name: name,
            amount: amount,
            period: .monthly,
            startDate: july(1),
            endDate: july(31),
            alertThreshold: 0.8,
            calendar: calendar
        )
    }

    private func july(_ day: Int) -> Date {
        date(year: 2026, month: 7, day: day)
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        DateComponents(calendar: calendar, year: year, month: month, day: day).date ?? Date()
    }
}
