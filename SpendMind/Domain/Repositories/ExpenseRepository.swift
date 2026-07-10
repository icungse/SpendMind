//
//  ExpenseRepository.swift
//  SpendMind
//
//  Created by Icung on 09/07/26.
//

import Foundation

// reuse the current Expense type; split domain/persistence models when Data mappers exist.
protocol ExpenseRepository {
    func createExpense(_ expense: Expense) throws
    func updateExpense(_ expense: Expense) throws
    func deleteExpense(id: UUID) throws
    func getExpense(id: UUID) throws -> Expense?
    func getExpenses() throws -> [Expense]
    func getExpensesByMonth(_ month: Date) throws -> [Expense]
    func getExpenses(from startDate: Date, to endDate: Date) throws -> [Expense]
}
