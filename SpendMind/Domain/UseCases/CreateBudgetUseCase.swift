//
//  CreateBudgetUseCase.swift
//  SpendMind
//
//  Created by Icung on 14/07/26.
//

import Foundation

struct CreateBudgetInput {
    let categoryID: UUID?
    let name: String
    let amount: Decimal
    let month: Date
    let alertThreshold: Decimal
}

protocol CreateBudgetUseCase {
    func execute(_ input: CreateBudgetInput) async throws -> Budget
}

struct DefaultCreateBudgetUseCase: CreateBudgetUseCase {
    private let repository: any BudgetRepository
    private let calendar: Calendar

    init(repository: any BudgetRepository, calendar: Calendar = .current) {
        self.repository = repository
        self.calendar = calendar
    }

    @discardableResult
    func execute(_ input: CreateBudgetInput) async throws -> Budget {
        let name = input.name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !name.isEmpty else {
            throw AppError.validation("Budget name is required.")
        }

        guard input.amount > 0 else {
            throw AppError.validation("Budget amount must be greater than zero.")
        }

        guard let month = calendar.dateInterval(of: .month, for: input.month),
              let endDate = calendar.date(byAdding: .day, value: -1, to: month.end) else {
            throw AppError.validation("Invalid budget month.")
        }

        // active budgets are tiny; add a repository query only if this list grows enough to matter.
        let activeBudgets = try await repository.activeBudgets(for: input.month)
        let duplicate = activeBudgets.contains {
            $0.categoryID == input.categoryID && $0.period == .monthly
        }

        guard !duplicate else {
            throw AppError.validation("An active budget already exists for this category and period.")
        }

        let budget = try Budget(
            categoryID: input.categoryID,
            name: name,
            amount: input.amount,
            period: .monthly,
            startDate: month.start,
            endDate: endDate,
            alertThreshold: input.alertThreshold,
            calendar: calendar
        )

        try await repository.create(budget)
        return budget
    }
}
