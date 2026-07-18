//
//  CalculateBudgetProgressUseCase.swift
//  Veyra
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
            throw AppError.validation(String(localized: "budget.validation.invalid_end_date"))
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

protocol PreviewBudgetImpactUseCase: Sendable {
    func execute(amount: Decimal, categoryID: UUID, date: Date, editingExpenseID: UUID?) async throws -> BudgetProgress?
}

struct DefaultPreviewBudgetImpactUseCase: PreviewBudgetImpactUseCase, @unchecked Sendable {
    private let budgetRepository: any BudgetRepository
    private let expenseRepository: any ExpenseRepository
    private let calendar: Calendar

    init(
        budgetRepository: any BudgetRepository,
        expenseRepository: any ExpenseRepository,
        calendar: Calendar = .current
    ) {
        self.budgetRepository = budgetRepository
        self.expenseRepository = expenseRepository
        self.calendar = calendar
    }

    func execute(amount: Decimal, categoryID: UUID, date: Date, editingExpenseID: UUID?) async throws -> BudgetProgress? {
        guard amount > 0, let month = calendar.dateInterval(of: .month, for: date) else {
            return nil
        }

        let budgets = try await budgetRepository.activeBudgets(for: date)
        guard let budget = budgets.first(where: { $0.categoryID == categoryID }) ?? budgets.first(where: { $0.isTotalBudget }) else {
            return nil
        }

        let expenses = try expenseRepository.getExpenses(from: month.start, to: month.end)
            .filter { !$0.isDeleted && $0.id != editingExpenseID }

        guard let endDate = calendar.date(byAdding: .day, value: 1, to: budget.endDate) else {
            throw AppError.validation(String(localized: "budget.validation.invalid_end_date"))
        }

        // inline draft sum avoids creating fake SwiftData models just to preview one amount.
        let spentAmount = expenses
            .filter { expense in
                expense.expenseDate >= budget.startDate
                    && expense.expenseDate < endDate
                    && (budget.categoryID == nil || expense.category?.id == budget.categoryID)
            }
            .reduce(amount) { $0 + $1.amount }

        return BudgetProgress(budget: budget, spentAmount: spentAmount)
    }
}
