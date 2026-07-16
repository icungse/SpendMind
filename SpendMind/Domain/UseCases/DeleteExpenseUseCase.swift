//
//  DeleteExpenseUseCase.swift
//  SpendMind
//
//  Created by Icung on 09/07/26.
//

import Foundation

struct DeleteExpenseUseCase {
    private let repository: any ExpenseRepository

    init(repository: any ExpenseRepository) {
        self.repository = repository
    }

    func execute(id: UUID, isConfirmed: Bool) throws {
        guard isConfirmed else {
            throw AppError.validation("Confirm delete before continuing.")
        }

        guard let expense = try repository.getExpense(id: id) else {
            throw AppError.persistence("Expense not found.")
        }

        // soft delete matches DataModel.md; hard cleanup can exist when restore/cleanup exists.
        expense.isDeleted = true
        try repository.updateExpense(expense)
        NotificationCenter.default.post(
            name: AppConstants.Notifications.expensesDidChange,
            object: nil,
            userInfo: [
                AppConstants.Notifications.expenseDatesKey: [expense.expenseDate],
                AppConstants.Notifications.expenseCategoryIDsKey: [expense.category?.id].compactMap { $0 }
            ]
        )
    }
}
