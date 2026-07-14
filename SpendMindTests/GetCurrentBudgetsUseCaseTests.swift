//
//  GetCurrentBudgetsUseCaseTests.swift
//  SpendMindTests
//
//  Created by Icung on 14/07/26.
//

import XCTest
@testable import SpendMind

final class GetCurrentBudgetsUseCaseTests: XCTestCase {
    func testExecuteReturnsCurrentActiveBudgets() async throws {
        let budget = try makeBudget(name: "Monthly", amount: 100)
        let progress = try await makeUseCase(budgets: [budget]).execute(referenceDate: july(14))

        XCTAssertEqual(progress.map(\.budget), [budget])
    }

    func testExecuteCalculatesTotalBudgetFromAllEligibleExpenses() async throws {
        let budget = try makeBudget(name: "Total", amount: 100)
        let expenses = [expense(amount: 25), expense(amount: 30)]

        let progress = try await makeUseCase(budgets: [budget], expenses: expenses).execute(referenceDate: july(14))

        XCTAssertEqual(progress.first?.spentAmount, 55)
        XCTAssertEqual(progress.first?.remainingAmount, 45)
    }

    func testExecuteCalculatesCategoryBudgetFromMatchingExpensesOnly() async throws {
        let food = SpendMind.Category(name: "Food", icon: "fork.knife", colorHex: "#FF7444")
        let transport = SpendMind.Category(name: "Transport", icon: "car.fill", colorHex: "#576A8F")
        let budget = try makeBudget(categoryID: food.id, name: "Food", amount: 100)
        let expenses = [
            expense(amount: 25, category: food),
            expense(amount: 30, category: transport),
            expense(amount: 10, category: food)
        ]

        let progress = try await makeUseCase(budgets: [budget], expenses: expenses).execute(referenceDate: july(14))

        XCTAssertEqual(progress.first?.spentAmount, 35)
    }

    func testExecuteExcludesDeletedExpenses() async throws {
        let budget = try makeBudget(name: "Total", amount: 100)
        let expenses = [
            expense(amount: 25),
            expense(amount: 30, isDeleted: true)
        ]

        let progress = try await makeUseCase(budgets: [budget], expenses: expenses).execute(referenceDate: july(14))

        XCTAssertEqual(progress.first?.spentAmount, 25)
    }

    func testExecuteExcludesExpensesOutsideCurrentMonth() async throws {
        let budget = try makeBudget(name: "Total", amount: 100)
        let expenses = [
            expense(amount: 25, date: july(2)),
            expense(amount: 30, date: date(year: 2026, month: 8, day: 1))
        ]

        let progress = try await makeUseCase(budgets: [budget], expenses: expenses).execute(referenceDate: july(14))

        XCTAssertEqual(progress.first?.spentAmount, 25)
    }

    func testExecuteSortsByStatusThenTotalBudgetFirst() async throws {
        let category = SpendMind.Category(name: "Food", icon: "fork.knife", colorHex: "#FF7444")
        let safeCategory = SpendMind.Category(name: "Transport", icon: "car.fill", colorHex: "#576A8F")
        let safeBudget = try makeBudget(categoryID: safeCategory.id, name: "Safe", amount: 100)
        let warningTotalBudget = try makeBudget(name: "Warning Total", amount: 100)
        let warningCategoryBudget = try makeBudget(categoryID: category.id, name: "Warning Food", amount: 100)
        let exceededBudget = try makeBudget(name: "Exceeded", amount: 40)
        let expenses = [expense(amount: 85, category: category)]

        let progress = try await makeUseCase(
            budgets: [safeBudget, warningCategoryBudget, warningTotalBudget, exceededBudget],
            expenses: expenses
        ).execute(referenceDate: july(14))

        XCTAssertEqual(progress.map(\.budget.name), ["Exceeded", "Warning Total", "Warning Food", "Safe"])
        XCTAssertEqual(progress.map(\.status), [.exceeded, .warning, .warning, .safe])
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }

    private func makeUseCase(
        budgets: [Budget] = [],
        expenses: [Expense] = []
    ) -> DefaultGetCurrentBudgetsUseCase {
        DefaultGetCurrentBudgetsUseCase(
            budgetRepository: GetCurrentBudgetsMockBudgetRepository(budgets: budgets),
            expenseRepository: GetCurrentBudgetsMockExpenseRepository(expenses: expenses),
            calendar: calendar
        )
    }

    private func makeBudget(categoryID: UUID? = nil, name: String, amount: Decimal) throws -> Budget {
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

    private func expense(
        amount: Decimal,
        date: Date? = nil,
        isDeleted: Bool = false,
        category: SpendMind.Category? = nil
    ) -> Expense {
        Expense(
            amount: amount,
            expenseDate: date ?? july(14),
            isDeleted: isDeleted,
            category: category
        )
    }

    private func july(_ day: Int) -> Date {
        date(year: 2026, month: 7, day: day)
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        DateComponents(calendar: calendar, year: year, month: month, day: day).date ?? Date()
    }
}

private final class GetCurrentBudgetsMockBudgetRepository: BudgetRepository {
    private var budgets: [Budget]

    init(budgets: [Budget]) {
        self.budgets = budgets
    }

    func create(_ budget: Budget) async throws {
        budgets.append(budget)
    }

    func update(_ budget: Budget) async throws { }

    func delete(id: UUID) async throws {
        budgets.removeAll { $0.id == id }
    }

    func budget(id: UUID) async throws -> Budget? {
        budgets.first { $0.id == id }
    }

    func activeBudgets(for date: Date) async throws -> [Budget] {
        budgets.filter(\.isActive)
    }

    func budgets(from startDate: Date, to endDate: Date) async throws -> [Budget] {
        budgets
    }
}

private final class GetCurrentBudgetsMockExpenseRepository: ExpenseRepository {
    private var expenses: [Expense]

    init(expenses: [Expense]) {
        self.expenses = expenses
    }

    func createExpense(_ expense: Expense) throws {
        expenses.append(expense)
    }

    func updateExpense(_ expense: Expense) throws { }

    func deleteExpense(id: UUID) throws {
        expenses.removeAll { $0.id == id }
    }

    func getExpense(id: UUID) throws -> Expense? {
        expenses.first { $0.id == id }
    }

    func getExpenses() throws -> [Expense] {
        expenses
    }

    func getExpensesByMonth(_ month: Date) throws -> [Expense] {
        expenses
    }

    func getExpenses(from startDate: Date, to endDate: Date) throws -> [Expense] {
        expenses.filter { $0.expenseDate >= startDate && $0.expenseDate < endDate }
    }
}
