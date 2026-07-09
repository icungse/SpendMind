//
//  ExpenseRepository.swift
//  SpendMind
//
//  Created by Icung on 09/07/26.
//

import Foundation

// reuse the current Expense type; split domain/persistence models when Data mappers exist.
protocol ExpenseRepository {
    func createExpense(_ expense: Expense)
    func updateExpense(_ expense: Expense)
    func deleteExpense(id: UUID)
    func getExpense(id: UUID) -> Expense?
    func getExpenses() -> [Expense]
    func getExpensesByMonth(_ month: Date) -> [Expense]
}
