//
//  ExpenseRepositoryTests.swift
//  SpendMindTests
//
//  Created by Icung on 09/07/26.
//

import XCTest
@testable import SpendMind

@MainActor
final class ExpenseRepositoryTests: XCTestCase {
    func testExpenseRepositoryCanBeMocked() {
        let expense = Expense(amount: 12, expenseDate: Date())
        let mock = MockExpenseRepository(expenses: [expense])
        let repository: any ExpenseRepository = mock

        XCTAssertEqual(repository.getExpense(id: expense.id)?.amount, 12)
    }
}

private final class MockExpenseRepository: ExpenseRepository {
    private var expenses: [Expense]

    init(expenses: [Expense] = []) {
        self.expenses = expenses
    }

    func createExpense(_ expense: Expense) {
        expenses.append(expense)
    }

    func updateExpense(_ expense: Expense) {
        guard let index = expenses.firstIndex(where: { $0.id == expense.id }) else {
            return
        }

        expenses[index] = expense
    }

    func deleteExpense(id: UUID) {
        expenses.removeAll { $0.id == id }
    }

    func getExpense(id: UUID) -> Expense? {
        expenses.first { $0.id == id }
    }

    func getExpenses() -> [Expense] {
        expenses
    }

    func getExpensesByMonth(_ month: Date) -> [Expense] {
        expenses.filter {
            Calendar.current.isDate($0.expenseDate, equalTo: month, toGranularity: .month)
            && Calendar.current.isDate($0.expenseDate, equalTo: month, toGranularity: .year)
        }
    }
}
