//
//  CategoryRepositoryTests.swift
//  VeyraTests
//
//  Created by Icung on 09/07/26.
//

import XCTest
@testable import Veyra

@MainActor
final class CategoryRepositoryTests: XCTestCase {
    func testCategoryRepositoryCanBeMocked() throws {
        let category = Veyra.Category(name: "Food", icon: "tag", colorHex: "#5B7FFF", isSystem: true)
        let mock = MockCategoryRepository(categories: [category])
        let repository: any CategoryRepository = mock

        XCTAssertEqual(try repository.getDefaultCategories().map(\.name), ["Food"])
    }
}

private final class MockCategoryRepository: CategoryRepository {
    private var categories: [Veyra.Category]

    init(categories: [Veyra.Category] = []) {
        self.categories = categories
    }

    func getCategories() throws -> [Veyra.Category] {
        categories
    }

    func getDefaultCategories() throws -> [Veyra.Category] {
        categories.filter(\.isSystem)
    }

    func seedDefaultCategoriesIfNeeded() throws {
        guard categories.isEmpty else {
            return
        }

        categories.append(Veyra.Category(name: "Food", icon: "tag", colorHex: "#5B7FFF", isSystem: true))
    }
}
