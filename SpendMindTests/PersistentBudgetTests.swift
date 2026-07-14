//
//  PersistentBudgetTests.swift
//  SpendMindTests
//
//  Created by Icung on 14/07/26.
//

import SwiftData
import XCTest
@testable import SpendMind

@MainActor
final class PersistentBudgetTests: XCTestCase {
    func testBudgetPersistsMoneyAndCategoryRelationship() throws {
        let container = try SpendMindModelContainer.test()
        let repository = SwiftDataRepository<PersistentBudget>(context: container.mainContext)
        let category = SpendMind.Category(name: "Food", icon: "fork.knife", colorHex: "#FF7444")
        let amount = try XCTUnwrap(Decimal(string: "12500.75"))
        let threshold = try XCTUnwrap(Decimal(string: "0.8"))
        let startDate = try XCTUnwrap(DateComponents(calendar: .current, year: 2026, month: 7, day: 1).date)
        let endDate = try XCTUnwrap(DateComponents(calendar: .current, year: 2026, month: 7, day: 31).date)
        let budget = PersistentBudget(
            category: category,
            name: "Food Budget",
            amount: amount,
            period: .monthly,
            startDate: startDate,
            endDate: endDate,
            alertThreshold: threshold
        )

        container.mainContext.insert(category)
        try repository.insert(budget)

        let savedBudget = try XCTUnwrap(repository.fetchAll().first)
        XCTAssertEqual(savedBudget.amount, amount)
        XCTAssertEqual(savedBudget.alertThreshold, threshold)
        XCTAssertEqual(savedBudget.category?.id, category.id)
        XCTAssertTrue(savedBudget.isActive)
    }

    func testDeletedCategoryDoesNotBreakBudgetLoading() throws {
        let container = try SpendMindModelContainer.test()
        let repository = SwiftDataRepository<PersistentBudget>(context: container.mainContext)
        let category = SpendMind.Category(name: "Food", icon: "fork.knife", colorHex: "#FF7444")
        let budget = PersistentBudget(
            category: category,
            name: "Food Budget",
            amount: 100,
            period: .monthly,
            startDate: Date(),
            endDate: Date(),
            alertThreshold: Decimal(string: "0.8") ?? 0.8
        )

        container.mainContext.insert(category)
        try repository.insert(budget)
        container.mainContext.delete(category)
        try container.mainContext.save()

        let savedBudget = try XCTUnwrap(repository.fetchAll().first)
        XCTAssertNil(savedBudget.category)
        XCTAssertEqual(savedBudget.name, "Food Budget")
    }
}
