//
//  AddExpenseUseCaseTests.swift
//  SpendMindTests
//
//  Created by Icung on 09/07/26.
//

import XCTest
@testable import SpendMind

@MainActor
final class AddExpenseUseCaseTests: XCTestCase {
    func testExecuteSavesExpense() throws {
        let repository = AddExpenseMockRepository()
        let category = Category(name: "Food", icon: "fork.knife", colorHex: "#5B7FFF")
        let useCase = AddExpenseUseCase(repository: repository)
        let date = Date(timeIntervalSince1970: 200)

        let expense = try useCase.execute(
            title: " Lunch ",
            amount: 25,
            category: category,
            date: date,
            note: " Team meal "
        )

        XCTAssertEqual(repository.expenses.count, 1)
        XCTAssertEqual(repository.expenses.first?.id, expense.id)
        XCTAssertEqual(expense.merchant, "Lunch")
        XCTAssertEqual(expense.note, "Team meal")
        XCTAssertEqual(expense.amount, 25)
        XCTAssertTrue(expense.category === category)
        XCTAssertEqual(expense.expenseDate, date)
    }

    func testExecuteRejectsEmptyTitle() {
        XCTAssertThrowsError(
            try AddExpenseUseCase(repository: AddExpenseMockRepository())
                .execute(title: "  ", amount: 25, category: Category(name: "Food", icon: "tag", colorHex: "#5B7FFF"))
        ) { error in
            XCTAssertEqual(error as? AppError, .validation("Title is required."))
        }
    }

    func testExecuteRejectsAmountLessThanOrEqualToZero() {
        let useCase = AddExpenseUseCase(repository: AddExpenseMockRepository())
        let category = Category(name: "Food", icon: "tag", colorHex: "#5B7FFF")

        XCTAssertThrowsError(try useCase.execute(title: "Lunch", amount: 0, category: category)) { error in
            XCTAssertEqual(error as? AppError, .validation("Amount must be greater than zero."))
        }

        XCTAssertThrowsError(try useCase.execute(title: "Lunch", amount: -1, category: category)) { error in
            XCTAssertEqual(error as? AppError, .validation("Amount must be greater than zero."))
        }
    }

    func testExecuteRejectsMissingCategory() {
        XCTAssertThrowsError(
            try AddExpenseUseCase(repository: AddExpenseMockRepository())
                .execute(title: "Lunch", amount: 25, category: nil)
        ) { error in
            XCTAssertEqual(error as? AppError, .validation("Category is required."))
        }
    }
}

private final class AddExpenseMockRepository: ExpenseRepository {
    private(set) var expenses: [Expense] = []

    func createExpense(_ expense: Expense) throws {
        expenses.append(expense)
    }

    func updateExpense(_ expense: Expense) throws { }

    func deleteExpense(id: UUID) throws { }

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
