//
//  SwiftDataBudgetAlertStateRepository.swift
//  Veyra
//
//  Created by Icung on 16/07/26.
//

import Foundation
import SwiftData

@ModelActor
actor SwiftDataBudgetAlertStateRepository: BudgetAlertStateRepository {
    func state(for budgetID: UUID) async throws -> BudgetAlertState? {
        try persistentState(for: budgetID).map {
            BudgetAlertState(budgetID: $0.budgetID, status: $0.status)
        }
    }

    func save(_ state: BudgetAlertState) async throws {
        if let persistentState = try persistentState(for: state.budgetID) {
            persistentState.status = state.status
        } else {
            modelContext.insert(PersistentBudgetAlertState(budgetID: state.budgetID, status: state.status))
        }

        try save("save")
    }

    func delete(budgetID: UUID) async throws {
        guard let persistentState = try persistentState(for: budgetID) else { return }

        modelContext.delete(persistentState)
        try save("delete")
    }

    private func persistentState(for budgetID: UUID) throws -> PersistentBudgetAlertState? {
        var descriptor = FetchDescriptor<PersistentBudgetAlertState>(predicate: #Predicate { $0.budgetID == budgetID })
        descriptor.fetchLimit = 1

        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            throw AppError.persistence("Failed to fetch budget alert state: \(error.localizedDescription)")
        }
    }

    private func save(_ action: String) throws {
        do {
            try modelContext.save()
        } catch {
            throw AppError.persistence("Failed to \(action) budget alert state: \(error.localizedDescription)")
        }
    }
}
