//
//  BudgetRepository.swift
//  SpendMind
//
//  Created by Icung on 14/07/26.
//

import Foundation

@MainActor
protocol BudgetRepository {
    func create(_ budget: Budget) async throws
    func update(_ budget: Budget) async throws
    func delete(id: UUID) async throws
    func budget(id: UUID) async throws -> Budget?
    func activeBudgets(for date: Date) async throws -> [Budget]
    func budgets(from startDate: Date, to endDate: Date) async throws -> [Budget]
}
