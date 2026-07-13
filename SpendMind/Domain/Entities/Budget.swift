//
//  Budget.swift
//  SpendMind
//
//  Created by Icung on 13/07/26.
//

import Foundation

struct Budget: Equatable, Sendable {
    let id: UUID
    var categoryID: UUID?
    var name: String
    var amount: Decimal
    var period: BudgetPeriod
    var startDate: Date
    var endDate: Date
    var alertThreshold: Decimal
    var isActive: Bool
    let createdAt: Date
    var updatedAt: Date

    var isTotalBudget: Bool {
        categoryID == nil
    }

    var isCategoryBudget: Bool {
        categoryID != nil
    }

    init(
        id: UUID = UUID(),
        categoryID: UUID? = nil,
        name: String,
        amount: Decimal,
        period: BudgetPeriod,
        startDate: Date,
        endDate: Date,
        alertThreshold: Decimal,
        isActive: Bool = true,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        calendar: Calendar = .current
    ) throws {
        guard amount > 0 else {
            throw AppError.validation("Budget amount must be greater than zero.")
        }

        guard alertThreshold >= 0, alertThreshold <= 1 else {
            throw AppError.validation("Budget alert threshold must be between 0 and 1.")
        }

        self.id = id
        self.categoryID = categoryID
        self.name = name
        self.amount = amount
        self.period = period
        self.startDate = calendar.startOfDay(for: startDate)
        self.endDate = calendar.startOfDay(for: endDate)
        self.alertThreshold = alertThreshold
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    func conflictsWith(_ budget: Budget) -> Bool {
        // persistence should call this before saving once BudgetRepository exists.
        isActive && budget.isActive && categoryID == budget.categoryID && period == budget.period && id != budget.id
    }
}
