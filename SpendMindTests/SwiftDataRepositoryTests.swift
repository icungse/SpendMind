//
//  SwiftDataRepositoryTests.swift
//  SpendMindTests
//
//  Created by Icung on 04/07/26.
//

import SwiftData
import XCTest
@testable import SpendMind

@Model
private final class RepositoryTestItem {
    var name: String

    init(name: String) {
        self.name = name
    }
}

@MainActor
final class SwiftDataRepositoryTests: XCTestCase {
    func testRepositoryInsertsFetchesAndDeletesModel() throws {
        let container = try ModelContainer(
            for: RepositoryTestItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let repository = SwiftDataRepository<RepositoryTestItem>(context: container.mainContext)
        let item = RepositoryTestItem(name: "Coffee")

        try repository.insert(item)
        XCTAssertEqual(try repository.fetchAll().map(\.name), ["Coffee"])

        try repository.delete(item)
        XCTAssertTrue(try repository.fetchAll().isEmpty)
    }
}
