//
//  PersistentBudget.swift
//  Veyra
//
//  Created by Icung on 14/07/26.
//

import Foundation
import SwiftData

@Model
final class PersistentBudget {
    @Attribute(.unique) var id: UUID
    // optional relationship keeps budgets loadable after category deletion; add mappers when Budget CRUD ships.
    @Relationship(deleteRule: .nullify, inverse: \Category.budgets) var category: Category?
    var name: String
    var amount: Decimal
    var period: BudgetPeriod
    var startDate: Date
    var endDate: Date
    var alertThreshold: Decimal
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        category: Category? = nil,
        name: String,
        amount: Decimal,
        period: BudgetPeriod,
        startDate: Date,
        endDate: Date,
        alertThreshold: Decimal,
        isActive: Bool = true,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.category = category
        self.name = name
        self.amount = amount
        self.period = period
        self.startDate = startDate
        self.endDate = endDate
        self.alertThreshold = alertThreshold
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
