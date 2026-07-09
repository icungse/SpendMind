//
//  SwiftDataCategoryRepositoryTests.swift
//  SpendMindTests
//
//  Created by Icung on 09/07/26.
//

import SwiftData
import XCTest
@testable import SpendMind

@MainActor
final class SwiftDataCategoryRepositoryTests: XCTestCase {
    func testGetCategoriesReturnsEmptyArrayWhenStoreIsEmpty() throws {
        let store = try makeStore()

        XCTAssertTrue(try store.repository.getCategories().isEmpty)
    }

    func testSeedDefaultCategoriesIfNeededSeedsOnce() throws {
        let store = try makeStore()

        try store.repository.seedDefaultCategoriesIfNeeded()
        try store.repository.seedDefaultCategoriesIfNeeded()

        XCTAssertEqual(try store.repository.getCategories().count, 11)
    }

    func testGetDefaultCategoriesFetchesOnlySystemCategories() throws {
        let store = try makeStore()
        let customCategory = SpendMind.Category(name: "Books", icon: "book", colorHex: "#000000")

        try store.repository.seedDefaultCategoriesIfNeeded()
        store.container.mainContext.insert(customCategory)
        try store.container.mainContext.save()

        let categories = try store.repository.getDefaultCategories()

        XCTAssertEqual(categories.count, 11)
        XCTAssertFalse(categories.contains { $0.name == "Books" })
        XCTAssertTrue(categories.allSatisfy(\.isSystem))
    }

    private func makeStore() throws -> TestStore {
        let container = try ModelContainer(
            for: SpendMind.Category.self, Expense.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )

        return TestStore(
            container: container,
            repository: SwiftDataCategoryRepository(context: container.mainContext)
        )
    }
}

private struct TestStore {
    let container: ModelContainer
    let repository: SwiftDataCategoryRepository
}
