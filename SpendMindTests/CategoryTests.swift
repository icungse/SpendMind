//
//  CategoryTests.swift
//  SpendMindTests
//
//  Created by Icung on 08/07/26.
//

import SwiftData
import XCTest
@testable import SpendMind

@MainActor
final class CategoryTests: XCTestCase {
    func testDefaultCategoriesSeedOnce() throws {
        let container = try SpendMindModelContainer.test()

        try SpendMindModelContainer.seedDefaultCategoriesIfNeeded(in: container.mainContext)
        try SpendMindModelContainer.seedDefaultCategoriesIfNeeded(in: container.mainContext)

        let categories = try container.mainContext.fetch(FetchDescriptor<SpendMind.Category>())
        XCTAssertEqual(categories.count, 11)
        XCTAssertEqual(Set(categories.map { $0.name }), [
            "Food",
            "Transportation",
            "Shopping",
            "Entertainment",
            "Bills",
            "Health",
            "Education",
            "Travel",
            "Salary",
            "Investment",
            "Miscellaneous"
        ])
        XCTAssertTrue(categories.allSatisfy { $0.isSystem })
    }

    func testExpenseCanUseSelectedCategory() throws {
        let container = try SpendMindModelContainer.test()
        let category = SpendMind.Category(name: "Food", icon: "fork.knife", colorHex: "#5B7FFF", isSystem: true)
        let expense = Expense(amount: 25, note: "Lunch", category: category)

        container.mainContext.insert(category)
        container.mainContext.insert(expense)
        try container.mainContext.save()

        let savedExpense = try XCTUnwrap(container.mainContext.fetch(FetchDescriptor<Expense>()).first)
        XCTAssertEqual(savedExpense.category?.name, "Food")
    }
}
