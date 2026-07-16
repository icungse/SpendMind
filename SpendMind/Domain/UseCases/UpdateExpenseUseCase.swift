//
//  UpdateExpenseUseCase.swift
//  SpendMind
//
//  Created by Icung on 09/07/26.
//

import Foundation

struct UpdateExpenseUseCase {
    private let repository: any ExpenseRepository

    init(repository: any ExpenseRepository) {
        self.repository = repository
    }

    @discardableResult
    func execute(
        id: UUID,
        title: String,
        amount: Decimal,
        category: Category?,
        note: String,
        date: Date
    ) throws -> Expense {
        guard let expense = try repository.getExpense(id: id) else {
            throw AppError.persistence("Expense not found.")
        }

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
        let oldDate = expense.expenseDate
        let oldCategoryID = expense.category?.id
        expense.merchant = title
        expense.amount = amount
        expense.category = category
        expense.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        expense.expenseDate = date

        try repository.updateExpense(expense)
        NotificationCenter.default.post(
            name: AppConstants.Notifications.expensesDidChange,
            object: nil,
            userInfo: [
                AppConstants.Notifications.expenseDatesKey: [oldDate, expense.expenseDate],
                AppConstants.Notifications.expenseCategoryIDsKey: [oldCategoryID, category.id].compactMap { $0 }
            ]
        )
        return expense
    }
}
