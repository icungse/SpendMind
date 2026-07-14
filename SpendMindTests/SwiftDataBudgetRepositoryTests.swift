//
//  SwiftDataBudgetRepositoryTests.swift
//  SpendMindTests
//
//  Created by Icung on 14/07/26.
//

import SwiftData
import XCTest
@testable import SpendMind

@MainActor
final class SwiftDataBudgetRepositoryTests: XCTestCase {
    func testCreatesFetchesUpdatesAndDeletesBudget() async throws {
        let store = try makeStore()
        let category = SpendMind.Category(name: "Food", icon: "fork.knife", colorHex: "#FF7444")
        store.container.mainContext.insert(category)
        try store.container.mainContext.save()
        let amount = try XCTUnwrap(Decimal(string: "12500.75"))
        let budget = try makeBudget(categoryID: category.id, amount: amount)

        try await store.repository.create(budget)
        let fetchedBudget = try await store.repository.budget(id: budget.id)
        let savedBudget = try XCTUnwrap(fetchedBudget)
        XCTAssertEqual(savedBudget.categoryID, category.id)
        XCTAssertEqual(savedBudget.amount, amount)

        let updatedBudget = try makeBudget(id: budget.id, name: "Groceries", amount: 150, isActive: false)
        try await store.repository.update(updatedBudget)
        let fetchedUpdatedBudget = try await store.repository.budget(id: budget.id)
        XCTAssertEqual(fetchedUpdatedBudget?.name, "Groceries")
        XCTAssertEqual(fetchedUpdatedBudget?.isActive, false)

        try await store.repository.delete(id: budget.id)
        let deletedBudget = try await store.repository.budget(id: budget.id)
        XCTAssertNil(deletedBudget)
    }

    func testBudgetsFromDateRangeReturnsOverlappingBudgets() async throws {
        let store = try makeStore()
        let juneBudget = try makeBudget(name: "June", startDate: date(year: 2026, month: 6, day: 1), endDate: date(year: 2026, month: 6, day: 30))
        let julyBudget = try makeBudget(name: "July", startDate: date(year: 2026, month: 7, day: 1), endDate: date(year: 2026, month: 7, day: 31))
        let augustBudget = try makeBudget(name: "August", startDate: date(year: 2026, month: 8, day: 1), endDate: date(year: 2026, month: 8, day: 31))

        try await store.repository.create(juneBudget)
        try await store.repository.create(julyBudget)
        try await store.repository.create(augustBudget)

        let budgets = try await store.repository.budgets(
            from: date(year: 2026, month: 6, day: 15),
            to: date(year: 2026, month: 7, day: 15)
        )

        XCTAssertEqual(Set(budgets.map(\.name)), ["June", "July"])
    }

    func testActiveBudgetsForDateReturnsActiveBudgetsForMonth() async throws {
        let store = try makeStore()
        let activeJulyBudget = try makeBudget(name: "Active July", startDate: date(year: 2026, month: 7, day: 1), endDate: date(year: 2026, month: 7, day: 31))
        let inactiveJulyBudget = try makeBudget(name: "Inactive July", startDate: date(year: 2026, month: 7, day: 1), endDate: date(year: 2026, month: 7, day: 31), isActive: false)
        let augustBudget = try makeBudget(name: "August", startDate: date(year: 2026, month: 8, day: 1), endDate: date(year: 2026, month: 8, day: 31))

        try await store.repository.create(activeJulyBudget)
        try await store.repository.create(inactiveJulyBudget)
        try await store.repository.create(augustBudget)

        let budgets = try await store.repository.activeBudgets(for: date(year: 2026, month: 7, day: 14))

        XCTAssertEqual(budgets.map(\.name), ["Active July"])
    }

    func testDeletedCategoryDoesNotCrashBudgetLoading() async throws {
        let store = try makeStore()
        let category = SpendMind.Category(name: "Food", icon: "fork.knife", colorHex: "#FF7444")
        store.container.mainContext.insert(category)
        try store.container.mainContext.save()
        let budget = try makeBudget(categoryID: category.id)

        try await store.repository.create(budget)
        store.container.mainContext.delete(category)
        try store.container.mainContext.save()

        let fetchedBudget = try await store.repository.budget(id: budget.id)
        let savedBudget = try XCTUnwrap(fetchedBudget)
        XCTAssertNil(savedBudget.categoryID)
        XCTAssertEqual(savedBudget.name, budget.name)
    }

    func testCreateRejectsMissingCategory() async throws {
        let store = try makeStore()
        let budget = try makeBudget(categoryID: UUID())

        do {
            try await store.repository.create(budget)
            XCTFail("Expected missing category to throw.")
        } catch {
            XCTAssertEqual(error as? AppError, .persistence("Category not found."))
        }
    }

    private func makeStore() throws -> TestStore {
        let container = try SpendMindModelContainer.test()

        return TestStore(
            container: container,
            repository: SwiftDataBudgetRepository(context: container.mainContext)
        )
    }

    private func makeBudget(
        id: UUID = UUID(),
        categoryID: UUID? = nil,
        name: String = "Monthly Budget",
        amount: Decimal = 100,
        startDate: Date? = nil,
        endDate: Date? = nil,
        isActive: Bool = true
    ) throws -> Budget {
        try Budget(
            id: id,
            categoryID: categoryID,
            name: name,
            amount: amount,
            period: .monthly,
            startDate: startDate ?? date(year: 2026, month: 7, day: 1),
            endDate: endDate ?? date(year: 2026, month: 7, day: 31),
            alertThreshold: Decimal(string: "0.8") ?? 0.8,
            isActive: isActive
        )
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        DateComponents(calendar: .current, year: year, month: month, day: day).date ?? Date()
    }
}

private struct TestStore {
    let container: ModelContainer
    let repository: SwiftDataBudgetRepository
}
