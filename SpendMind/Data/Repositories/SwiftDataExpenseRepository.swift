//
//  SwiftDataExpenseRepository.swift
//  SpendMind
//
//  Created by Icung on 09/07/26.
//

import Foundation
import SwiftData

struct SwiftDataExpenseRepository: ExpenseRepository {
    private let context: ModelContext
    private let calendar: Calendar

    init(context: ModelContext, calendar: Calendar = .current) {
        self.context = context
        self.calendar = calendar
    }

    func createExpense(_ expense: Expense) throws {
        context.insert(expense)
        try save("create")
    }

    func updateExpense(_ expense: Expense) throws {
        guard try getExpense(id: expense.id) != nil else {
            throw AppError.persistence("Expense not found.")
        }

        expense.updatedAt = Date()
        try save("update")
    }

    func deleteExpense(id: UUID) throws {
        guard let expense = try getExpense(id: id) else {
            throw AppError.persistence("Expense not found.")
        }

        context.delete(expense)
        try save("delete")
    }

    func getExpense(id: UUID) throws -> Expense? {
        var descriptor = FetchDescriptor<Expense>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1

        do {
            return try context.fetch(descriptor).first
        } catch {
            throw AppError.persistence("Failed to fetch expense: \(error.localizedDescription)")
        }
    }

    func getExpenses() throws -> [Expense] {
        do {
            return try context.fetch(FetchDescriptor<Expense>())
        } catch {
            throw AppError.persistence("Failed to fetch expenses: \(error.localizedDescription)")
        }
    }

    func getExpensesByMonth(_ month: Date) throws -> [Expense] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else {
            throw AppError.persistence("Invalid expense month.")
        }

        let start = monthInterval.start
        let end = monthInterval.end
        let descriptor = FetchDescriptor<Expense>(predicate: #Predicate {
            $0.expenseDate >= start && $0.expenseDate < end
        })

        do {
            return try context.fetch(descriptor)
        } catch {
            throw AppError.persistence("Failed to fetch expenses by month: \(error.localizedDescription)")
        }
    }

    private func save(_ action: String) throws {
        do {
            try context.save()
        } catch {
            throw AppError.persistence("Failed to \(action) expense: \(error.localizedDescription)")
        }
    }
}
