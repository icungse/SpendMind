//
//  AddExpenseUseCase.swift
//  SpendMind
//
//  Created by Icung on 09/07/26.
//

import Foundation

struct AddExpenseUseCase {
    private let repository: any ExpenseRepository

    init(repository: any ExpenseRepository) {
        self.repository = repository
    }

    @discardableResult
    func execute(
        title: String,
        amount: Decimal,
        category: Category?,
        date: Date = .now,
        note: String = ""
    ) throws -> Expense {
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !title.isEmpty else {
            throw AppError.validation("Title is required.")
        }

        guard amount > 0 else {
            throw AppError.validation("Amount must be greater than zero.")
        }

        guard let category else {
            throw AppError.validation("Category is required.")
        }

        // Expense has no title field; merchant carries the display title until the model changes.
        let expense = Expense(
            amount: amount,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            merchant: title,
            expenseDate: date,
            category: category
        )
        try repository.createExpense(expense)
        return expense
    }
}
