//
//  DeleteBudgetUseCase.swift
//  SpendMind
//
//  Created by Icung on 14/07/26.
//

import Foundation

protocol DeleteBudgetUseCase {
    func execute(id: UUID, isConfirmed: Bool) async throws
}

struct DefaultDeleteBudgetUseCase: DeleteBudgetUseCase {
    private let repository: any BudgetRepository

    init(repository: any BudgetRepository) {
        self.repository = repository
    }

    func execute(id: UUID, isConfirmed: Bool) async throws {
        // UI owns the alert; the use case only enforces the confirmed result.
        guard isConfirmed else {
            throw AppError.validation("Confirm delete before continuing.")
        }

        guard try await repository.budget(id: id) != nil else {
            throw AppError.persistence("Budget not found.")
        }

        try await repository.delete(id: id)
    }
}
