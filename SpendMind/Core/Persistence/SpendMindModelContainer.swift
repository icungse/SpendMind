//
//  SpendMindModelContainer.swift
//  SpendMind
//
//  Created by Icung on 04/07/26.
//

import SwiftData
import Foundation

enum SpendMindModelContainer {
    static let app: ModelContainer = makeContainer(isStoredInMemoryOnly: false)

    static let preview: ModelContainer = makeContainer(isStoredInMemoryOnly: true)

    static func test() throws -> ModelContainer {
        try createContainer(isStoredInMemoryOnly: true)
    }

    private static func makeContainer(isStoredInMemoryOnly: Bool) -> ModelContainer {
        do {
            return try createContainer(isStoredInMemoryOnly: isStoredInMemoryOnly)
        } catch {
            preconditionFailure("Failed to create SwiftData container: \(error)")
        }
    }

    private static func createContainer(isStoredInMemoryOnly: Bool) throws -> ModelContainer {
        let schema = Schema([Category.self, Expense.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isStoredInMemoryOnly)

        if !isStoredInMemoryOnly {
            if let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                try FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true, attributes: nil)
            }
        }

        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func seedDefaultCategoriesIfNeeded(in context: ModelContext) throws {
        let descriptor = FetchDescriptor<Category>(predicate: #Predicate { $0.isSystem })
        let existingCategories = try context.fetch(descriptor)

        if !existingCategories.isEmpty {
            // repair old seeded icons by name; real migrations can wait until category editing ships.
            for category in existingCategories {
                guard let defaults = defaultCategoriesByName[category.name] else { continue }
                category.icon = defaults.icon
                category.colorHex = defaults.colorHex
            }
            try context.save()
            return
        }

        for category in defaultCategories {
            context.insert(Category(
                name: category.name,
                icon: category.icon,
                colorHex: category.colorHex,
                isSystem: true
            ))
        }

        try context.save()
    }

    private static let defaultCategories: [(name: String, icon: String, colorHex: String)] = [
        ("Food", "fork.knife", "#FF7444"),
        ("Transportation", "car.fill", "#576A8F"),
        ("Shopping", "bag.fill", "#B7BDF7"),
        ("Entertainment", "popcorn.fill", "#FF9500"),
        ("Bills", "doc.text.fill", "#8E8E93"),
        ("Health", "cross.case.fill", "#2E7D32"),
        ("Education", "book.fill", "#2563EB"),
        ("Travel", "airplane", "#00A7A7"),
        ("Salary", "banknote.fill", "#34C759"),
        ("Investment", "chart.line.uptrend.xyaxis", "#AF52DE"),
        ("Miscellaneous", "tag.fill", "#5B7FFF")
    ]

    private static var defaultCategoriesByName: [String: (icon: String, colorHex: String)] {
        Dictionary(uniqueKeysWithValues: defaultCategories.map { ($0.name, ($0.icon, $0.colorHex)) })
    }
}
