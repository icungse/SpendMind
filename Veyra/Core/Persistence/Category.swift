//
//  Category.swift
//  Veyra
//
//  Created by Icung on 08/07/26.
//

import Foundation
import SwiftData

@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var isSystem: Bool
    var isArchived: Bool?
    var createdAt: Date
    @Relationship(inverse: \Expense.category) var expenses: [Expense]
    @Relationship var budgets: [PersistentBudget]

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String,
        isSystem: Bool = false,
        isArchived: Bool = false,
        createdAt: Date = .now,
        expenses: [Expense] = [],
        budgets: [PersistentBudget] = []
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.isSystem = isSystem
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.expenses = expenses
        self.budgets = budgets
    }
}
