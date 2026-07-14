//
//  UpdateBudgetUseCaseTests.swift
//  SpendMindTests
//
//  Created by Icung on 14/07/26.
//

import XCTest
@testable import SpendMind

final class UpdateBudgetUseCaseTests: XCTestCase {
    func testExecuteUpdatesEditableFields() async throws {
        let existingBudget = try budget(name: "Old", amount: 100)
        let repository = UpdateBudgetMockRepository(budgets: [existingBudget])
        let useCase = DefaultUpdateBudgetUseCase(repository: repository, calendar: calendar)
        let categoryID = UUID()

        let updatedBudget = try await useCase.execute(
            UpdateBudgetInput(
                id: existingBudget.id,
                categoryID: categoryID,
                name: " Food ",
                amount: 500,
                month: date(year: 2026, month: 8, day: 14),
                alertThreshold: 0.7,
                isActive: false
            )
        )

        XCTAssertEqual(repository.updatedBudgets, [updatedBudget])
        XCTAssertEqual(updatedBudget.id, existingBudget.id)
        XCTAssertEqual(updatedBudget.categoryID, categoryID)
        XCTAssertEqual(updatedBudget.name, "Food")
        XCTAssertEqual(updatedBudget.amount, 500)
        XCTAssertEqual(updatedBudget.alertThreshold, 0.7)
        XCTAssertFalse(updatedBudget.isActive)
        XCTAssertEqual(updatedBudget.createdAt, existingBudget.createdAt)
        XCTAssertGreaterThan(updatedBudget.updatedAt, existingBudget.updatedAt)
    }

    func testExecuteRejectsMissingBudget() async {
        await assertThrows(.persistence("Budget not found.")) {
            try await DefaultUpdateBudgetUseCase(repository: UpdateBudgetMockRepository(), calendar: calendar)
                .execute(input(id: UUID()))
        }
    }

    func testExecuteRejectsEmptyName() async throws {
        let existingBudget = try budget()
        let useCase = DefaultUpdateBudgetUseCase(
            repository: UpdateBudgetMockRepository(budgets: [existingBudget]),
            calendar: calendar
        )

        await assertThrows(.validation("Budget name is required.")) {
            try await useCase.execute(input(id: existingBudget.id, name: "  "))
        }
    }

    func testExecuteRejectsZeroOrNegativeAmount() async throws {
        let existingBudget = try budget()
        let useCase = DefaultUpdateBudgetUseCase(
            repository: UpdateBudgetMockRepository(budgets: [existingBudget]),
            calendar: calendar
        )

        await assertThrows(.validation("Budget amount must be greater than zero.")) {
            try await useCase.execute(input(id: existingBudget.id, amount: 0))
        }

        await assertThrows(.validation("Budget amount must be greater than zero.")) {
            try await useCase.execute(input(id: existingBudget.id, amount: -1))
        }
    }

    func testExecuteRejectsConflictingActiveCategoryBudget() async throws {
        let categoryID = UUID()
        let existingBudget = try budget(categoryID: nil)
        let conflictingBudget = try budget(categoryID: categoryID)
        let repository = UpdateBudgetMockRepository(
            budgets: [existingBudget],
            activeBudgets: [conflictingBudget]
        )
        let useCase = DefaultUpdateBudgetUseCase(repository: repository, calendar: calendar)

        await assertThrows(.validation("An active budget already exists for this category and period.")) {
            try await useCase.execute(input(id: existingBudget.id, categoryID: categoryID, isActive: true))
        }

        XCTAssertTrue(repository.updatedBudgets.isEmpty)
    }

    func testExecuteAllowsSelfConflict() async throws {
        let existingBudget = try budget()
        let repository = UpdateBudgetMockRepository(
            budgets: [existingBudget],
            activeBudgets: [existingBudget]
        )
        let useCase = DefaultUpdateBudgetUseCase(repository: repository, calendar: calendar)

        let updatedBudget = try await useCase.execute(input(id: existingBudget.id, name: "Same Budget"))

        XCTAssertEqual(repository.updatedBudgets, [updatedBudget])
    }

    func testExecuteCalculatesMonthStartAndEndDates() async throws {
        let existingBudget = try budget()
        let useCase = DefaultUpdateBudgetUseCase(
            repository: UpdateBudgetMockRepository(budgets: [existingBudget]),
            calendar: calendar
        )

        let updatedBudget = try await useCase.execute(
            input(id: existingBudget.id, month: date(year: 2028, month: 2, day: 14))
        )

        XCTAssertEqual(updatedBudget.startDate, date(year: 2028, month: 2, day: 1))
        XCTAssertEqual(updatedBudget.endDate, date(year: 2028, month: 2, day: 29))
    }

    func testExecuteKeepsSpendingAssociationFieldsConsistentAfterUpdate() async throws {
        let existingBudget = try budget(categoryID: UUID())
        let repository = UpdateBudgetMockRepository(budgets: [existingBudget])
        let useCase = DefaultUpdateBudgetUseCase(repository: repository, calendar: calendar)

        let updatedBudget = try await useCase.execute(
            input(id: existingBudget.id, categoryID: nil, month: date(year: 2026, month: 9, day: 10))
        )

        XCTAssertNil(updatedBudget.categoryID)
        XCTAssertEqual(updatedBudget.startDate, date(year: 2026, month: 9, day: 1))
        XCTAssertEqual(updatedBudget.endDate, date(year: 2026, month: 9, day: 30))
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }

    private func input(
        id: UUID,
        categoryID: UUID? = UUID(),
        name: String = "Food",
        amount: Decimal = 100,
        month: Date? = nil,
        alertThreshold: Decimal = 0.8,
        isActive: Bool = true
    ) -> UpdateBudgetInput {
        UpdateBudgetInput(
            id: id,
            categoryID: categoryID,
            name: name,
            amount: amount,
            month: month ?? date(year: 2026, month: 7, day: 14),
            alertThreshold: alertThreshold,
            isActive: isActive
        )
    }

    private func budget(
        id: UUID = UUID(),
        categoryID: UUID? = UUID(),
        name: String = "Monthly Budget",
        amount: Decimal = 100,
        createdAt: Date = Date(timeIntervalSince1970: 100),
        updatedAt: Date = Date(timeIntervalSince1970: 100)
    ) throws -> Budget {
        try Budget(
            id: id,
            categoryID: categoryID,
            name: name,
            amount: amount,
            period: .monthly,
            startDate: date(year: 2026, month: 7, day: 1),
            endDate: date(year: 2026, month: 7, day: 31),
            alertThreshold: 0.8,
            createdAt: createdAt,
            updatedAt: updatedAt,
            calendar: calendar
        )
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        DateComponents(calendar: calendar, year: year, month: month, day: day).date ?? Date()
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

private final class UpdateBudgetMockRepository: BudgetRepository {
    private var budgetsByID: [UUID: Budget]
    private let activeBudgetResults: [Budget]
    private(set) var updatedBudgets: [Budget] = []

    init(budgets: [Budget] = [], activeBudgets: [Budget] = []) {
        self.budgetsByID = Dictionary(uniqueKeysWithValues: budgets.map { ($0.id, $0) })
        self.activeBudgetResults = activeBudgets
    }

    func create(_ budget: Budget) async throws { }

    func update(_ budget: Budget) async throws {
        budgetsByID[budget.id] = budget
        updatedBudgets.append(budget)
    }

    func delete(id: UUID) async throws { }

    func budget(id: UUID) async throws -> Budget? {
        budgetsByID[id]
    }

    func activeBudgets(for date: Date) async throws -> [Budget] {
        activeBudgetResults
    }

    func budgets(from startDate: Date, to endDate: Date) async throws -> [Budget] {
        Array(budgetsByID.values)
    }
}
