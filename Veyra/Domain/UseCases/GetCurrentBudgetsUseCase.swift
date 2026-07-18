//
//  GetCurrentBudgetsUseCase.swift
//  Veyra
//
//  Created by Icung on 14/07/26.
//

import Foundation

protocol GetCurrentBudgetsUseCase {
    func execute(referenceDate: Date) async throws -> [BudgetProgress]
}

struct DefaultGetCurrentBudgetsUseCase: GetCurrentBudgetsUseCase {
    private let budgetRepository: any BudgetRepository
    private let expenseRepository: any ExpenseRepository
    private let calculateBudgetProgressUseCase: any CalculateBudgetProgressUseCase
    private let calendar: Calendar

    init(
        budgetRepository: any BudgetRepository,
        expenseRepository: any ExpenseRepository,
        calculateBudgetProgressUseCase: (any CalculateBudgetProgressUseCase)? = nil,
        calendar: Calendar = .current
    ) {
        self.budgetRepository = budgetRepository
        self.expenseRepository = expenseRepository
        self.calculateBudgetProgressUseCase = calculateBudgetProgressUseCase ?? DefaultCalculateBudgetProgressUseCase(calendar: calendar)
        self.calendar = calendar
    }

    func execute(referenceDate: Date) async throws -> [BudgetProgress] {
        guard let month = calendar.dateInterval(of: .month, for: referenceDate) else {
            throw AppError.validation("Invalid budget month.")
        }

        let budgets = try await budgetRepository.activeBudgets(for: referenceDate)
        let expenses = try expenseRepository.getExpenses(from: month.start, to: month.end).filter { !$0.isDeleted }

        return try budgets
            .map { budget in
                try calculateBudgetProgressUseCase.execute(budget: budget, expenses: expenses)
            }
            .sorted { lhs, rhs in
                if lhs.status != rhs.status {
                    return lhs.status.sortRank < rhs.status.sortRank
                }

                return lhs.budget.isTotalBudget && rhs.budget.isCategoryBudget
            }
    }
}

private extension BudgetStatus {
    var sortRank: Int {
        switch self {
        case .exceeded: 0
        case .warning: 1
        case .safe: 2
        }
    }
}
