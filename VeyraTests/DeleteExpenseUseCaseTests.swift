//
//  DeleteExpenseUseCaseTests.swift
//  VeyraTests
//
//  Created by Icung on 09/07/26.
//

import XCTest
@testable import Veyra

@MainActor
final class DeleteExpenseUseCaseTests: XCTestCase {
    func testExecuteSoftDeletesSelectedExpense() throws {
        let expense = Expense(amount: 10)
        let repository = DeleteExpenseMockRepository(expenses: [expense])

        try DeleteExpenseUseCase(repository: repository).execute(id: expense.id, isConfirmed: true)

        XCTAssertTrue(expense.isDeleted)
        XCTAssertEqual(repository.updatedExpenseId, expense.id)
    }

    func testExecutePostsExpenseChangeNotification() throws {
        let date = Date(timeIntervalSince1970: 100)
        let expense = Expense(amount: 10, expenseDate: date)
        let repository = DeleteExpenseMockRepository(expenses: [expense])
        let expectation = expectation(description: "expense changed")
        var notifiedDates: [Date] = []
        let observer = NotificationCenter.default.addObserver(
            forName: AppConstants.Notifications.expensesDidChange,
            object: nil,
            queue: nil
        ) { notification in
            notifiedDates = notification.userInfo?[AppConstants.Notifications.expenseDatesKey] as? [Date] ?? []
            expectation.fulfill()
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        try DeleteExpenseUseCase(repository: repository).execute(id: expense.id, isConfirmed: true)

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(notifiedDates, [date])
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
