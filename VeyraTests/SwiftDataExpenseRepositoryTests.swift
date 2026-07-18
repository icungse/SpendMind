//
//  SwiftDataExpenseRepositoryTests.swift
//  VeyraTests
//
//  Created by Icung on 09/07/26.
//

import SwiftData
import XCTest
@testable import Veyra

@MainActor
final class SwiftDataExpenseRepositoryTests: XCTestCase {
    func testGetExpensesReturnsEmptyArrayWhenStoreIsEmpty() throws {
        let store = try makeStore()

        XCTAssertTrue(try store.repository.getExpenses().isEmpty)
    }

    func testCreatesFetchesUpdatesAndDeletesExpense() throws {
        let store = try makeStore()
        let expense = Expense(amount: 10, note: "Coffee")

        try store.repository.createExpense(expense)
        XCTAssertEqual(try store.repository.getExpense(id: expense.id)?.note, "Coffee")

        expense.note = "Coffee and snack"
        try store.repository.updateExpense(expense)
        XCTAssertEqual(try store.repository.getExpense(id: expense.id)?.note, "Coffee and snack")

        try store.repository.deleteExpense(id: expense.id)
        XCTAssertNil(try store.repository.getExpense(id: expense.id))
    }

    func testGetExpensesByMonthReturnsOnlyMatchingMonth() throws {
        let store = try makeStore()
        let julyDate = try XCTUnwrap(DateComponents(calendar: .current, year: 2026, month: 7, day: 9).date)
        let augustDate = try XCTUnwrap(DateComponents(calendar: .current, year: 2026, month: 8, day: 1).date)
        let julyExpense = Expense(amount: 10, expenseDate: julyDate)
        let augustExpense = Expense(amount: 20, expenseDate: augustDate)

        try store.repository.createExpense(julyExpense)
        try store.repository.createExpense(augustExpense)

        let expenses = try store.repository.getExpensesByMonth(julyExpense.expenseDate)

        XCTAssertEqual(expenses.map(\.id), [julyExpense.id])
    }

    func testGetExpensesByDateRangeIncludesStartAndExcludesEnd() throws {
        let store = try makeStore()
        let startDate = try XCTUnwrap(DateComponents(calendar: .current, year: 2026, month: 7, day: 1).date)
        let middleDate = try XCTUnwrap(DateComponents(calendar: .current, year: 2026, month: 7, day: 2).date)
        let endDate = try XCTUnwrap(DateComponents(calendar: .current, year: 2026, month: 7, day: 3).date)
        let startExpense = Expense(amount: 10, expenseDate: startDate)
        let middleExpense = Expense(amount: 20, expenseDate: middleDate)
        let endExpense = Expense(amount: 30, expenseDate: endDate)

        try store.repository.createExpense(startExpense)
        try store.repository.createExpense(middleExpense)
        try store.repository.createExpense(endExpense)

        let expenses = try store.repository.getExpenses(from: startDate, to: endDate)

        XCTAssertEqual(Set(expenses.map(\.id)), Set([startExpense.id, middleExpense.id]))
    }

    func testGetExpensesByDateRangeRejectsInvalidRange() throws {
        let store = try makeStore()
        let date = Date()

        XCTAssertThrowsError(try store.repository.getExpenses(from: date, to: date)) { error in
            XCTAssertEqual(error as? AppError, .persistence("Invalid expense date range."))
        }
    }

    func testDeleteMissingExpenseThrowsAppError() throws {
        let store = try makeStore()

        XCTAssertThrowsError(try store.repository.deleteExpense(id: UUID())) { error in
            XCTAssertEqual(error as? AppError, .persistence("Expense not found."))
        }
    }

    private func makeStore() throws -> TestStore {
        let container = try ModelContainer(
            for: Veyra.Category.self, Expense.self, PersistentBudget.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )

        return TestStore(
            container: container,
            repository: SwiftDataExpenseRepository(context: container.mainContext)
        )
    }
}

private struct TestStore {
    let container: ModelContainer
    let repository: SwiftDataExpenseRepository
}
