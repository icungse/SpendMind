//
//  Category.swift
//  SpendMind
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
    var createdAt: Date
    @Relationship(inverse: \Expense.category) var expenses: [Expense]

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String,
        isSystem: Bool = false,
        createdAt: Date = .now,
        expenses: [Expense] = []
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.isSystem = isSystem
        self.createdAt = createdAt
        self.expenses = expenses
    }
}
