//
//  FetchExpensesUseCaseTests.swift
//  SpendMindTests
//
//  Created by Icung on 09/07/26.
//

import XCTest
@testable import SpendMind

@MainActor
final class FetchExpensesUseCaseTests: XCTestCase {
    func testExecuteFetchesAllActiveExpensesNewestFirst() throws {
        let oldExpense = Expense(amount: 10, expenseDate: date(year: 2026, month: 7, day: 1))
        let deletedExpense = Expense(amount: 20, expenseDate: date(year: 2026, month: 7, day: 3), isDeleted: true)
        let newExpense = Expense(amount: 30, expenseDate: date(year: 2026, month: 7, day: 2))

        let expenses = try FetchExpensesUseCase(
            repository: FetchExpensesMockRepository(expenses: [oldExpense, deletedExpense, newExpense])
        ).execute()

        XCTAssertEqual(expenses.map(\.id), [newExpense.id, oldExpense.id])
    }

    func testExecuteFetchesSelectedMonthNewestFirst() throws {
        let julyOldExpense = Expense(amount: 10, expenseDate: date(year: 2026, month: 7, day: 1))
        let augustExpense = Expense(amount: 20, expenseDate: date(year: 2026, month: 8, day: 1))
        let julyNewExpense = Expense(amount: 30, expenseDate: date(year: 2026, month: 7, day: 2))

        let expenses = try FetchExpensesUseCase(
            repository: FetchExpensesMockRepository(expenses: [julyOldExpense, augustExpense, julyNewExpense])
        ).execute(month: date(year: 2026, month: 7, day: 10))

        XCTAssertEqual(expenses.map(\.id), [julyNewExpense.id, julyOldExpense.id])
    }

    func testExecuteFetchesDateRangeNewestFirst() throws {
        let beforeRange = Expense(amount: 10, expenseDate: date(year: 2026, month: 6, day: 30))
        let rangeOldExpense = Expense(amount: 20, expenseDate: date(year: 2026, month: 7, day: 1))
        let rangeNewExpense = Expense(amount: 30, expenseDate: date(year: 2026, month: 7, day: 2))
        let endBoundary = Expense(amount: 40, expenseDate: date(year: 2026, month: 7, day: 3))

        let expenses = try FetchExpensesUseCase(
            repository: FetchExpensesMockRepository(expenses: [beforeRange, rangeOldExpense, rangeNewExpense, endBoundary])
        ).execute(from: date(year: 2026, month: 7, day: 1), to: date(year: 2026, month: 7, day: 3))

        XCTAssertEqual(expenses.map(\.id), [rangeNewExpense.id, rangeOldExpense.id])
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        DateComponents(calendar: .current, year: year, month: month, day: day).date ?? Date()
    }
}

private final class FetchExpensesMockRepository: ExpenseRepository {
    private var expenses: [Expense]

    init(expenses: [Expense] = []) {
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
        expenses.filter {
            Calendar.current.isDate($0.expenseDate, equalTo: month, toGranularity: .month)
            && Calendar.current.isDate($0.expenseDate, equalTo: month, toGranularity: .year)
        }
    }

    func getExpenses(from startDate: Date, to endDate: Date) throws -> [Expense] {
        expenses.filter { $0.expenseDate >= startDate && $0.expenseDate < endDate }
    }
}
