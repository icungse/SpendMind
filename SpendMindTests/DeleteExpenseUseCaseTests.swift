//
//  DeleteExpenseUseCaseTests.swift
//  SpendMindTests
//
//  Created by Icung on 09/07/26.
//

import XCTest
@testable import SpendMind

@MainActor
final class DeleteExpenseUseCaseTests: XCTestCase {
    func testExecuteSoftDeletesSelectedExpense() throws {
        let expense = Expense(amount: 10)
        let repository = DeleteExpenseMockRepository(expenses: [expense])

        try DeleteExpenseUseCase(repository: repository).execute(id: expense.id, isConfirmed: true)

        XCTAssertTrue(expense.isDeleted)
        XCTAssertEqual(repository.updatedExpenseId, expense.id)
    }

    func testExecuteRejectsUnconfirmedDelete() {
        let expense = Expense(amount: 10)

        XCTAssertThrowsError(
            try DeleteExpenseUseCase(repository: DeleteExpenseMockRepository(expenses: [expense]))
                .execute(id: expense.id, isConfirmed: false)
        ) { error in
            XCTAssertEqual(error as? AppError, .validation("Confirm delete before continuing."))
        }
    }

    func testExecuteRejectsMissingExpense() {
        XCTAssertThrowsError(
            try DeleteExpenseUseCase(repository: DeleteExpenseMockRepository())
                .execute(id: UUID(), isConfirmed: true)
        ) { error in
            XCTAssertEqual(error as? AppError, .persistence("Expense not found."))
        }
    }
}

private final class DeleteExpenseMockRepository: ExpenseRepository {
    private var expenses: [Expense]
    private(set) var updatedExpenseId: UUID?

    init(expenses: [Expense] = []) {
        self.expenses = expenses
    }

    func createExpense(_ expense: Expense) throws {
        expenses.append(expense)
    }

    func updateExpense(_ expense: Expense) throws {
        updatedExpenseId = expense.id
    }

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
