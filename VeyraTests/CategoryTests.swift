//
//  CategoryTests.swift
//  VeyraTests
//
//  Created by Icung on 08/07/26.
//

import SwiftData
import XCTest
@testable import Veyra

@MainActor
final class CategoryTests: XCTestCase {
    func testDefaultCategoriesSeedOnce() throws {
        let container = try VeyraModelContainer.test()

        try VeyraModelContainer.seedDefaultCategoriesIfNeeded(in: container.mainContext)
        try VeyraModelContainer.seedDefaultCategoriesIfNeeded(in: container.mainContext)

        let categories = try container.mainContext.fetch(FetchDescriptor<Veyra.Category>())
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
        XCTAssertEqual(categories.first { $0.name == "Food" }?.icon, "fork.knife")
        XCTAssertEqual(categories.first { $0.name == "Transportation" }?.icon, "car.fill")
        XCTAssertFalse(categories.allSatisfy { $0.icon == "tag" })
    }

    func testDefaultCategoriesRepairOldSeededIcons() throws {
        let container = try VeyraModelContainer.test()
        container.mainContext.insert(Veyra.Category(name: "Food", icon: "tag", colorHex: "#5B7FFF", isSystem: true))
        try container.mainContext.save()

        try VeyraModelContainer.seedDefaultCategoriesIfNeeded(in: container.mainContext)

        let category = try XCTUnwrap(container.mainContext.fetch(FetchDescriptor<Veyra.Category>()).first)
        XCTAssertEqual(category.icon, "fork.knife")
        XCTAssertEqual(category.colorHex, "#FF7444")
    }

    func testExpenseCanUseSelectedCategory() throws {
        let container = try VeyraModelContainer.test()
        let category = Veyra.Category(name: "Food", icon: "fork.knife", colorHex: "#5B7FFF", isSystem: true)
        let expense = Expense(amount: 25, note: "Lunch", category: category)

        container.mainContext.insert(category)
        container.mainContext.insert(expense)
        try container.mainContext.save()

        let savedExpense = try XCTUnwrap(container.mainContext.fetch(FetchDescriptor<Expense>()).first)
        XCTAssertEqual(savedExpense.category?.name, "Food")
    }
}
