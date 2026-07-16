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

    func testPreviewBudgetImpactDetectsMatchingCategoryBudget() async throws {
        let food = SpendMind.Category(name: "Food", icon: "fork.knife", colorHex: "#FF7444")
        let transport = SpendMind.Category(name: "Transport", icon: "car.fill", colorHex: "#576A8F")
        let foodBudget = try budget(categoryID: food.id, amount: 100)
        let expenses = [expense(amount: 20, category: food), expense(amount: 40, category: transport)]

        let progress = try await previewUseCase(budgets: [foodBudget], expenses: expenses)
            .execute(amount: 30, categoryID: food.id, date: date(year: 2026, month: 7, day: 14), editingExpenseID: nil)

        XCTAssertEqual(progress?.budget, foodBudget)
        XCTAssertEqual(progress?.spentAmount, 50)
        XCTAssertEqual(progress?.remainingAmount, 50)
    }

    func testPreviewBudgetImpactUsesDraftAmountBeforeSave() async throws {
        let food = SpendMind.Category(name: "Food", icon: "fork.knife", colorHex: "#FF7444")
        let foodBudget = try budget(categoryID: food.id, amount: 100)

        let progress = try await previewUseCase(budgets: [foodBudget], expenses: [expense(amount: 20, category: food)])
            .execute(amount: 25, categoryID: food.id, date: date(year: 2026, month: 7, day: 14), editingExpenseID: nil)

        XCTAssertEqual(progress?.spentAmount, 45)
        XCTAssertEqual(progress?.remainingAmount, 55)
    }

    func testPreviewBudgetImpactCalculatesExceededAmount() async throws {
        let food = SpendMind.Category(name: "Food", icon: "fork.knife", colorHex: "#FF7444")
        let foodBudget = try budget(categoryID: food.id, amount: 100)

        let progress = try await previewUseCase(budgets: [foodBudget], expenses: [expense(amount: 80, category: food)])
            .execute(amount: 50, categoryID: food.id, date: date(year: 2026, month: 7, day: 14), editingExpenseID: nil)

        XCTAssertEqual(progress?.remainingAmount, -30)
        XCTAssertEqual(progress?.status, .exceeded)
    }

    func testPreviewBudgetImpactExcludesEditedExpense() async throws {
        let food = SpendMind.Category(name: "Food", icon: "fork.knife", colorHex: "#FF7444")
        let foodBudget = try budget(categoryID: food.id, amount: 100)
        let existing = expense(amount: 40, category: food)

        let progress = try await previewUseCase(budgets: [foodBudget], expenses: [existing])
            .execute(amount: 25, categoryID: food.id, date: date(year: 2026, month: 7, day: 14), editingExpenseID: existing.id)

        XCTAssertEqual(progress?.spentAmount, 25)
        XCTAssertEqual(progress?.remainingAmount, 75)
    }

    func testPreviewBudgetImpactReturnsNilWhenNoMatchingBudgetExists() async throws {
        let food = SpendMind.Category(name: "Food", icon: "fork.knife", colorHex: "#FF7444")
        let transport = SpendMind.Category(name: "Transport", icon: "car.fill", colorHex: "#576A8F")
        let transportBudget = try budget(categoryID: transport.id, amount: 100)

        let progress = try await previewUseCase(budgets: [transportBudget], expenses: [])
            .execute(amount: 25, categoryID: food.id, date: date(year: 2026, month: 7, day: 14), editingExpenseID: nil)

        XCTAssertNil(progress)
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

    private func previewUseCase(budgets: [Budget], expenses: [Expense]) -> DefaultPreviewBudgetImpactUseCase {
        DefaultPreviewBudgetImpactUseCase(
            budgetRepository: PreviewBudgetMockBudgetRepository(budgets: budgets),
            expenseRepository: PreviewBudgetMockExpenseRepository(expenses: expenses),
            calendar: calendar
        )
    }
}

private final class PreviewBudgetMockBudgetRepository: BudgetRepository {
    private let budgets: [Budget]

    init(budgets: [Budget]) {
        self.budgets = budgets
    }

    func create(_ budget: Budget) async throws { }
    func update(_ budget: Budget) async throws { }
    func delete(id: UUID) async throws { }
    func budget(id: UUID) async throws -> Budget? { budgets.first { $0.id == id } }
    func activeBudgets(for date: Date) async throws -> [Budget] { budgets.filter(\.isActive) }
    func budgets(from startDate: Date, to endDate: Date) async throws -> [Budget] { budgets }
}

private final class PreviewBudgetMockExpenseRepository: ExpenseRepository {
    private let expenses: [Expense]

    init(expenses: [Expense]) {
        self.expenses = expenses
    }

    func createExpense(_ expense: Expense) throws { }
    func updateExpense(_ expense: Expense) throws { }
    func deleteExpense(id: UUID) throws { }
    func getExpense(id: UUID) throws -> Expense? { expenses.first { $0.id == id } }
    func getExpenses() throws -> [Expense] { expenses }
    func getExpensesByMonth(_ month: Date) throws -> [Expense] { expenses }

    func getExpenses(from startDate: Date, to endDate: Date) throws -> [Expense] {
        expenses.filter { $0.expenseDate >= startDate && $0.expenseDate < endDate }
    }
}
