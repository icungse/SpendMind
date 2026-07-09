//
//  SwiftDataExpenseRepositoryTests.swift
//  SpendMindTests
//
//  Created by Icung on 09/07/26.
//

import SwiftData
import XCTest
@testable import SpendMind

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

    func testDeleteMissingExpenseThrowsAppError() throws {
        let store = try makeStore()

        XCTAssertThrowsError(try store.repository.deleteExpense(id: UUID())) { error in
            XCTAssertEqual(error as? AppError, .persistence("Expense not found."))
        }
    }

    private func makeStore() throws -> TestStore {
        let container = try ModelContainer(
            for: SpendMind.Category.self, Expense.self,
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
