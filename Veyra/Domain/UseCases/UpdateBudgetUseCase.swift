//
//  UpdateBudgetUseCase.swift
//  Veyra
//
//  Created by Icung on 14/07/26.
//

import Foundation

struct UpdateBudgetInput {
    let id: UUID
    let categoryID: UUID?
    let name: String
    let amount: Decimal
    let month: Date
    let alertThreshold: Decimal
    let isActive: Bool
}

protocol UpdateBudgetUseCase {
    func execute(_ input: UpdateBudgetInput) async throws -> Budget
}

struct DefaultUpdateBudgetUseCase: UpdateBudgetUseCase {
    private let repository: any BudgetRepository
    private let calendar: Calendar

    init(repository: any BudgetRepository, calendar: Calendar = .current) {
        self.repository = repository
        self.calendar = calendar
    }

    @discardableResult
    func execute(_ input: UpdateBudgetInput) async throws -> Budget {
        guard let existingBudget = try await repository.budget(id: input.id) else {
            throw AppError.persistence("Budget not found.")
        }

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

        if input.isActive {
            // active budgets are tiny; add a repository query only if this list grows enough to matter.
            let duplicate = try await repository.activeBudgets(for: input.month).contains {
                $0.categoryID == input.categoryID && $0.period == .monthly && $0.id != input.id
            }

            guard !duplicate else {
                throw AppError.validation("An active budget already exists for this category and period.")
            }
        }

        let budget = try Budget(
            id: existingBudget.id,
            categoryID: input.categoryID,
            name: name,
            amount: input.amount,
            period: .monthly,
            startDate: month.start,
            endDate: endDate,
            alertThreshold: input.alertThreshold,
            isActive: input.isActive,
            createdAt: existingBudget.createdAt,
            updatedAt: .now,
            calendar: calendar
        )

        try await repository.update(budget)
        return budget
    }
}
