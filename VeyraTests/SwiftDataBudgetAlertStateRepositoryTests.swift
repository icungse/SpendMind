//
//  SwiftDataBudgetAlertStateRepositoryTests.swift
//  VeyraTests
//
//  Created by Icung on 16/07/26.
//

import XCTest
@testable import Veyra

@MainActor
final class SwiftDataBudgetAlertStateRepositoryTests: XCTestCase {
    func testSavesUpdatesAndDeletesAlertState() async throws {
        let container = try VeyraModelContainer.test()
        let repository = SwiftDataBudgetAlertStateRepository(modelContainer: container)
        let budgetID = UUID()

        try await repository.save(BudgetAlertState(budgetID: budgetID, status: .warning))
        let warningState = try await repository.state(for: budgetID)
        XCTAssertEqual(warningState?.status, .warning)

        try await repository.save(BudgetAlertState(budgetID: budgetID, status: .exceeded))
        let exceededState = try await repository.state(for: budgetID)
        XCTAssertEqual(exceededState?.status, .exceeded)

        try await repository.delete(budgetID: budgetID)
        let deletedState = try await repository.state(for: budgetID)
        XCTAssertNil(deletedState)
    }
}
