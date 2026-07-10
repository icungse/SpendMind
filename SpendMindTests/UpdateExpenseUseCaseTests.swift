//
//  UpdateExpenseUseCaseTests.swift
//  SpendMindTests
//
//  Created by Icung on 09/07/26.
//

import XCTest
@testable import SpendMind

@MainActor
final class UpdateExpenseUseCaseTests: XCTestCase {
    func testExecuteUpdatesAcceptedFields() throws {
        let oldCategory = Category(name: "Food", icon: "fork.knife", colorHex: "#5B7FFF")
        let newCategory = Category(name: "Transport", icon: "car", colorHex: "#FF9500")
        let oldDate = Date(timeIntervalSince1970: 100)
        let newDate = Date(timeIntervalSince1970: 200)
        let expense = Expense(
            amount: 10,
            note: "Old note",
            merchant: "Old title",
            expenseDate: oldDate,
            category: oldCategory
        )
        let repository = UpdateExpenseMockRepository(expenses: [expense])

        let updated = try UpdateExpenseUseCase(repository: repository).execute(
            id: expense.id,
            title: " Bus ",
            amount: 20,
            category: newCategory,
            note: " Morning ride ",
            date: newDate
        )

        XCTAssertEqual(repository.updatedExpenseId, expense.id)
        XCTAssertEqual(updated.merchant, "Bus")
        XCTAssertEqual(updated.amount, 20)
        XCTAssertTrue(updated.category === newCategory)
        XCTAssertEqual(updated.note, "Morning ride")
        XCTAssertEqual(updated.expenseDate, newDate)
    }

    func testExecuteRejectsMissingExpense() {
        XCTAssertThrowsError(
            try UpdateExpenseUseCase(repository: UpdateExpenseMockRepository()).execute(
                id: UUID(),
                title: "Lunch",
                amount: 10,
                category: Category(name: "Food", icon: "tag", colorHex: "#5B7FFF"),
                note: "Note",
                date: Date()
            )
        ) { error in
            XCTAssertEqual(error as? AppError, .persistence("Expense not found."))
        }
    }

    func testExecuteRejectsEmptyTitle() {
        let expense = Expense(amount: 10)

        XCTAssertThrowsError(
            try UpdateExpenseUseCase(repository: UpdateExpenseMockRepository(expenses: [expense])).execute(
                id: expense.id,
                title: "  ",
                amount: 10,
                category: Category(name: "Food", icon: "tag", colorHex: "#5B7FFF"),
                note: "Note",
                date: Date()
            )
        ) { error in
            XCTAssertEqual(error as? AppError, .validation("Title is required."))
        }
    }

    func testExecuteRejectsAmountLessThanOrEqualToZero() {
        let expense = Expense(amount: 10)
        let useCase = UpdateExpenseUseCase(repository: UpdateExpenseMockRepository(expenses: [expense]))
        let category = Category(name: "Food", icon: "tag", colorHex: "#5B7FFF")

        XCTAssertThrowsError(
            try useCase.execute(id: expense.id, title: "Lunch", amount: 0, category: category, note: "", date: Date())
        ) { error in
            XCTAssertEqual(error as? AppError, .validation("Amount must be greater than zero."))
        }

        XCTAssertThrowsError(
            try useCase.execute(id: expense.id, title: "Lunch", amount: -1, category: category, note: "", date: Date())
        ) { error in
            XCTAssertEqual(error as? AppError, .validation("Amount must be greater than zero."))
        }
    }

    func testExecuteRejectsMissingCategory() {
        let expense = Expense(amount: 10)

        XCTAssertThrowsError(
            try UpdateExpenseUseCase(repository: UpdateExpenseMockRepository(expenses: [expense])).execute(
                id: expense.id,
                title: "Lunch",
                amount: 10,
                category: nil,
                note: "Note",
                date: Date()
            )
        ) { error in
            XCTAssertEqual(error as? AppError, .validation("Category is required."))
        }
    }
}

private final class UpdateExpenseMockRepository: ExpenseRepository {
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
