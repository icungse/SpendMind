//
//  BudgetAlertStateRepository.swift
//  Veyra
//
//  Created by Icung on 16/07/26.
//

import Foundation

protocol BudgetAlertStateRepository: Sendable {
    func state(for budgetID: UUID) async throws -> BudgetAlertState?
    func save(_ state: BudgetAlertState) async throws
    func delete(budgetID: UUID) async throws
}
