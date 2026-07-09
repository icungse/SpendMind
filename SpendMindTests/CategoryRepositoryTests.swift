//
//  CategoryRepositoryTests.swift
//  SpendMindTests
//
//  Created by Icung on 09/07/26.
//

import XCTest
@testable import SpendMind

@MainActor
final class CategoryRepositoryTests: XCTestCase {
    func testCategoryRepositoryCanBeMocked() throws {
        let category = SpendMind.Category(name: "Food", icon: "tag", colorHex: "#5B7FFF", isSystem: true)
        let mock = MockCategoryRepository(categories: [category])
        let repository: any CategoryRepository = mock

        XCTAssertEqual(try repository.getDefaultCategories().map(\.name), ["Food"])
    }
}

private final class MockCategoryRepository: CategoryRepository {
    private var categories: [SpendMind.Category]

    init(categories: [SpendMind.Category] = []) {
        self.categories = categories
    }

    func getCategories() throws -> [SpendMind.Category] {
        categories
    }

    func getDefaultCategories() throws -> [SpendMind.Category] {
        categories.filter(\.isSystem)
    }

    func seedDefaultCategoriesIfNeeded() throws {
        guard categories.isEmpty else {
            return
        }

        categories.append(SpendMind.Category(name: "Food", icon: "tag", colorHex: "#5B7FFF", isSystem: true))
    }
}
