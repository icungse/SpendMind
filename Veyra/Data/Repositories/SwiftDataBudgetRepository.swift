//
//  SwiftDataBudgetRepository.swift
//  Veyra
//
//  Created by Icung on 14/07/26.
//

import Foundation
import SwiftData

@ModelActor
actor SwiftDataBudgetRepository: BudgetRepository {
    func create(_ budget: Budget) async throws {
        let category = try category(id: budget.categoryID)
        try enforceUniqueActiveBudget(budget)
        modelContext.insert(PersistentBudget(budget: budget, category: category))
        try save("create")
    }

    func update(_ budget: Budget) async throws {
        guard let persistentBudget = try persistentBudget(id: budget.id) else {
            throw AppError.persistence("Budget not found.")
        }

        let category = try category(id: budget.categoryID)
        try enforceUniqueActiveBudget(budget)
        persistentBudget.category = category
        persistentBudget.name = budget.name
        persistentBudget.amount = budget.amount
        persistentBudget.period = budget.period
        persistentBudget.startDate = budget.startDate
        persistentBudget.endDate = budget.endDate
        persistentBudget.alertThreshold = budget.alertThreshold
        persistentBudget.isActive = budget.isActive
        persistentBudget.updatedAt = budget.updatedAt
        try save("update")
    }

    func delete(id: UUID) async throws {
        guard let budget = try persistentBudget(id: id) else {
            throw AppError.persistence("Budget not found.")
        }

        modelContext.delete(budget)
        try save("delete")
    }

    func budget(id: UUID) async throws -> Budget? {
        try persistentBudget(id: id)?.domainBudget()
    }

    func activeBudgets(for date: Date) async throws -> [Budget] {
        guard let month = Calendar.current.dateInterval(of: .month, for: date) else {
            throw AppError.persistence("Invalid budget month.")
        }

        let descriptor = FetchDescriptor<PersistentBudget>(predicate: #Predicate {
            $0.isActive && $0.startDate < month.end && $0.endDate >= month.start
        })

        return try fetch(descriptor, action: "fetch active budgets")
    }

    func budgets(from startDate: Date, to endDate: Date) async throws -> [Budget] {
        guard startDate < endDate else {
            throw AppError.persistence("Invalid budget date range.")
        }

        let descriptor = FetchDescriptor<PersistentBudget>(predicate: #Predicate {
            $0.startDate < endDate && $0.endDate >= startDate
        })

        return try fetch(descriptor, action: "fetch budgets by date range")
    }

    private func persistentBudget(id: UUID) throws -> PersistentBudget? {
        var descriptor = FetchDescriptor<PersistentBudget>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1

        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            throw AppError.persistence("Failed to fetch budget: \(error.localizedDescription)")
        }
    }

    private func category(id: UUID?) throws -> Category? {
        guard let id else { return nil }

        var descriptor = FetchDescriptor<Category>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1

        do {
            guard let category = try modelContext.fetch(descriptor).first else {
                throw AppError.persistence("Category not found.")
            }

            return category
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.persistence("Failed to fetch budget category: \(error.localizedDescription)")
        }
    }

    private func enforceUniqueActiveBudget(_ budget: Budget) throws {
        guard budget.isActive else { return }

        let descriptor = FetchDescriptor<PersistentBudget>(predicate: #Predicate { $0.isActive })

        do {
            // active budgets are tiny; fetch active rows and compare in Swift instead of owning fragile predicates.
            let duplicate = try modelContext.fetch(descriptor).contains {
                guard let existing = try? $0.domainBudget() else { return false }
                return existing.conflictsWith(budget)
            }

            if duplicate {
                throw AppError.validation("An active budget already exists for this category and period.")
            }
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.persistence("Failed to validate budget uniqueness: \(error.localizedDescription)")
        }
    }

    private func fetch(_ descriptor: FetchDescriptor<PersistentBudget>, action: String) throws -> [Budget] {
        do {
            return try modelContext.fetch(descriptor).map { try $0.domainBudget() }
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.persistence("Failed to \(action): \(error.localizedDescription)")
        }
    }

    private func save(_ action: String) throws {
        do {
            try modelContext.save()
        } catch {
            throw AppError.persistence("Failed to \(action) budget: \(error.localizedDescription)")
        }
    }
}

private extension PersistentBudget {
    convenience init(budget: Budget, category: Category?) {
        self.init(
            id: budget.id,
            category: category,
            name: budget.name,
            amount: budget.amount,
            period: budget.period,
            startDate: budget.startDate,
            endDate: budget.endDate,
            alertThreshold: budget.alertThreshold,
            isActive: budget.isActive,
            createdAt: budget.createdAt,
            updatedAt: budget.updatedAt
        )
    }

    func domainBudget() throws -> Budget {
        // deleted category becomes a total budget on load; persist categoryID separately if restore-by-ID matters.
        do {
            return try Budget(
                id: id,
                categoryID: category?.id,
                name: name,
                amount: amount,
                period: period,
                startDate: startDate,
                endDate: endDate,
                alertThreshold: alertThreshold,
                isActive: isActive,
                createdAt: createdAt,
                updatedAt: updatedAt
            )
        } catch {
            throw AppError.persistence("Failed to load budget: \(error.localizedDescription)")
        }
    }
}
