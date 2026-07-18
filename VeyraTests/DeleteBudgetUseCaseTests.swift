//
//  DeleteBudgetUseCaseTests.swift
//  VeyraTests
//
//  Created by Icung on 14/07/26.
//

import XCTest
@testable import Veyra

final class DeleteBudgetUseCaseTests: XCTestCase {
    func testExecuteDeletesConfirmedBudget() async throws {
        let budget = try makeBudget()
        let repository = DeleteBudgetMockRepository(budgets: [budget])

        try await DefaultDeleteBudgetUseCase(repository: repository).execute(id: budget.id, isConfirmed: true)

        let deletedBudget = try await repository.budget(id: budget.id)
        XCTAssertNil(deletedBudget)
        XCTAssertEqual(repository.deletedBudgetIDs, [budget.id])
    }

    func testExecuteRejectsUnconfirmedDelete() async throws {
        let budget = try makeBudget()
        let repository = DeleteBudgetMockRepository(budgets: [budget])

        await assertThrows(.validation("Confirm delete before continuing.")) {
            try await DefaultDeleteBudgetUseCase(repository: repository).execute(id: budget.id, isConfirmed: false)
        }

        let existingBudget = try await repository.budget(id: budget.id)
        XCTAssertNotNil(existingBudget)
        XCTAssertTrue(repository.deletedBudgetIDs.isEmpty)
    }

    func testExecuteRejectsMissingBudget() async {
        await assertThrows(.persistence("Budget not found.")) {
            try await DefaultDeleteBudgetUseCase(repository: DeleteBudgetMockRepository())
                .execute(id: UUID(), isConfirmed: true)
        }
    }

    func testExecuteDoesNotDeleteExpenses() async throws {
        let budget = try makeBudget()
        let expense = Expense(amount: 25, note: "Coffee")
        let repository = DeleteBudgetMockRepository(budgets: [budget], expenses: [expense])

        try await DefaultDeleteBudgetUseCase(repository: repository).execute(id: budget.id, isConfirmed: true)

        XCTAssertEqual(repository.expenses.map(\.id), [expense.id])
    }

    private func makeBudget() throws -> Budget {
        try Budget(
            name: "Monthly Budget",
            amount: 100,
            period: .monthly,
            startDate: .now,
            endDate: .now,
            alertThreshold: 0.8
        )
    }

    private func assertThrows(
        _ expectedError: AppError,
        operation: () async throws -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            try await operation()
            XCTFail("Expected error.", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? AppError, expectedError, file: file, line: line)
        }
    }
}

private final class DeleteBudgetMockRepository: BudgetRepository {
    private var budgetsByID: [UUID: Budget]
    private(set) var deletedBudgetIDs: [UUID] = []
    private(set) var expenses: [Expense]

    init(budgets: [Budget] = [], expenses: [Expense] = []) {
        self.budgetsByID = Dictionary(uniqueKeysWithValues: budgets.map { ($0.id, $0) })
        self.expenses = expenses
    }

    func create(_ budget: Budget) async throws {
        budgetsByID[budget.id] = budget
    }

    func update(_ budget: Budget) async throws {
        budgetsByID[budget.id] = budget
    }

    func delete(id: UUID) async throws {
        budgetsByID.removeValue(forKey: id)
        deletedBudgetIDs.append(id)
    }

    func budget(id: UUID) async throws -> Budget? {
        budgetsByID[id]
    }

    func activeBudgets(for date: Date) async throws -> [Budget] {
        budgetsByID.values.filter(\.isActive)
    }

    func budgets(from startDate: Date, to endDate: Date) async throws -> [Budget] {
        Array(budgetsByID.values)
    }
}
