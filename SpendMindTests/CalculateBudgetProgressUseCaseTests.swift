//
//  CalculateBudgetProgressUseCaseTests.swift
//  SpendMindTests
//
//  Created by Icung on 14/07/26.
//

import XCTest
@testable import SpendMind

final class CalculateBudgetProgressUseCaseTests: XCTestCase {
    func testTotalBudgetSumsEligibleExpenses() throws {
        let progress = try useCase.execute(
            budget: budget(amount: 100),
            expenses: [expense(amount: 25), expense(amount: 30)]
        )

        XCTAssertEqual(progress.spentAmount, 55)
        XCTAssertEqual(progress.remainingAmount, 45)
    }

    func testCategoryBudgetSumsMatchingCategoryOnly() throws {
        let food = SpendMind.Category(name: "Food", icon: "fork.knife", colorHex: "#FF7444")
        let transport = SpendMind.Category(name: "Transport", icon: "car.fill", colorHex: "#576A8F")

        let progress = try useCase.execute(
            budget: budget(categoryID: food.id, amount: 100),
            expenses: [expense(amount: 25, category: food), expense(amount: 30, category: transport)]
        )

        XCTAssertEqual(progress.spentAmount, 25)
    }

    func testDeletedExpenseIsExcluded() throws {
        let progress = try useCase.execute(
            budget: budget(amount: 100),
            expenses: [expense(amount: 25), expense(amount: 30, isDeleted: true)]
        )

        XCTAssertEqual(progress.spentAmount, 25)
    }

    func testBudgetDateRangeIncludesStartAndEndDaysOnly() throws {
        let progress = try useCase.execute(
            budget: budget(amount: 100),
            expenses: [
                expense(amount: 10, date: date(year: 2026, month: 6, day: 30)),
                expense(amount: 20, date: date(year: 2026, month: 7, day: 1)),
                expense(amount: 30, date: date(year: 2026, month: 7, day: 31, hour: 23)),
                expense(amount: 40, date: date(year: 2026, month: 8, day: 1))
            ]
        )

        XCTAssertEqual(progress.spentAmount, 50)
    }

    func testNegativeExpenseReducesSpentAmount() throws {
        let progress = try useCase.execute(
            budget: budget(amount: 100),
            expenses: [expense(amount: 50), expense(amount: -15)]
        )

        XCTAssertEqual(progress.spentAmount, 35)
    }

    func testDecimalPrecisionIsPreserved() throws {
        let progress = try useCase.execute(
            budget: budget(amount: decimal("100.00")),
            expenses: [expense(amount: decimal("0.10")), expense(amount: decimal("0.20"))]
        )

        XCTAssertEqual(progress.spentAmount, decimal("0.30"))
    }

    func testMixedCurrenciesAreSummedAsStored() throws {
        let progress = try useCase.execute(
            budget: budget(amount: 100),
            expenses: [expense(amount: 25, currency: .IDR), expense(amount: 30, currency: .USD)]
        )

        XCTAssertEqual(progress.spentAmount, 55)
    }

    private var useCase: DefaultCalculateBudgetProgressUseCase {
        DefaultCalculateBudgetProgressUseCase(calendar: calendar)
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }

    private func budget(categoryID: UUID? = nil, amount: Decimal) throws -> Budget {
        try Budget(
            categoryID: categoryID,
            name: "Monthly",
            amount: amount,
            period: .monthly,
            startDate: date(year: 2026, month: 7, day: 1),
            endDate: date(year: 2026, month: 7, day: 31),
            alertThreshold: decimal("0.8"),
            calendar: calendar
        )
    }

    private func expense(
        amount: Decimal,
        date: Date? = nil,
        isDeleted: Bool = false,
        category: SpendMind.Category? = nil,
        currency: CurrencyCode = .IDR
    ) -> Expense {
        Expense(
            amount: amount,
            expenseDate: date ?? self.date(year: 2026, month: 7, day: 14),
            currency: currency,
            isDeleted: isDeleted,
            category: category
        )
    }

    private func date(year: Int, month: Int, day: Int, hour: Int = 0) -> Date {
        DateComponents(calendar: calendar, year: year, month: month, day: day, hour: hour).date ?? Date()
    }

    private func decimal(_ value: String) -> Decimal {
        Decimal(string: value) ?? 0
    }
}
