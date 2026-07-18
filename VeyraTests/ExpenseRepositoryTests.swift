//
//  ExpenseRepositoryTests.swift
//  VeyraTests
//
//  Created by Icung on 09/07/26.
//

import XCTest
@testable import Veyra

@MainActor
final class ExpenseRepositoryTests: XCTestCase {
    func testExpenseRepositoryCanBeMocked() throws {
        let expense = Expense(amount: 12, expenseDate: Date())
        let mock = MockExpenseRepository(expenses: [expense])
        let repository: any ExpenseRepository = mock

        XCTAssertEqual(try repository.getExpense(id: expense.id)?.amount, 12)
    }
}

private final class MockExpenseRepository: ExpenseRepository {
    private var expenses: [Expense]

    init(expenses: [Expense] = []) {
        self.expenses = expenses
    }

    func createExpense(_ expense: Expense) throws {
        expenses.append(expense)
    }

    func updateExpense(_ expense: Expense) throws {
        guard let index = expenses.firstIndex(where: { $0.id == expense.id }) else {
            return
        }

        expenses[index] = expense
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
        expenses.filter {
            Calendar.current.isDate($0.expenseDate, equalTo: month, toGranularity: .month)
            && Calendar.current.isDate($0.expenseDate, equalTo: month, toGranularity: .year)
        }
    }

    func getExpenses(from startDate: Date, to endDate: Date) throws -> [Expense] {
        expenses.filter { $0.expenseDate >= startDate && $0.expenseDate < endDate }
    }
}
