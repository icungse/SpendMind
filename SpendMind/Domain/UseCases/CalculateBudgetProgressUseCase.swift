//
//  CalculateBudgetProgressUseCase.swift
//  SpendMind
//
//  Created by Icung on 14/07/26.
//

import Foundation

protocol CalculateBudgetProgressUseCase {
    func execute(budget: Budget, expenses: [Expense]) throws -> BudgetProgress
}

struct DefaultCalculateBudgetProgressUseCase: CalculateBudgetProgressUseCase {
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func execute(budget: Budget, expenses: [Expense]) throws -> BudgetProgress {
        guard let endDate = calendar.date(byAdding: .day, value: 1, to: budget.endDate) else {
            throw AppError.validation("Invalid budget end date.")
        }

        // budgets have no currency yet; sum stored amounts as-is until conversion exists.
        let spentAmount = expenses
            .filter { expense in
                !expense.isDeleted
                    && expense.expenseDate >= budget.startDate
                    && expense.expenseDate < endDate
                    && (budget.categoryID == nil || expense.category?.id == budget.categoryID)
            }
            .reduce(Decimal.zero) { $0 + $1.amount }

        return BudgetProgress(budget: budget, spentAmount: spentAmount)
    }
}
