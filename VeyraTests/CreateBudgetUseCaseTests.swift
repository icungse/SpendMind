//
//  CreateBudgetUseCaseTests.swift
//  VeyraTests
//
//  Created by Icung on 14/07/26.
//

import XCTest
@testable import Veyra

final class CreateBudgetUseCaseTests: XCTestCase {
    func testExecuteCreatesAndSavesBudget() async throws {
        let repository = CreateBudgetMockRepository()
        let useCase = DefaultCreateBudgetUseCase(repository: repository, calendar: calendar)
        let categoryID = UUID()

        let budget = try await useCase.execute(
            CreateBudgetInput(
                categoryID: categoryID,
                name: " Food ",
                amount: 500,
                month: date(year: 2026, month: 7, day: 14),
                alertThreshold: 0.8
            )
        )

        XCTAssertEqual(repository.createdBudgets, [budget])
        XCTAssertEqual(budget.categoryID, categoryID)
        XCTAssertEqual(budget.name, "Food")
        XCTAssertEqual(budget.amount, 500)
        XCTAssertEqual(budget.period, .monthly)
        XCTAssertTrue(budget.isActive)
        XCTAssertEqual(budget.alertThreshold, 0.8)
    }

    func testExecuteRejectsEmptyName() async {
        await assertThrowsValidation("Budget name is required.") {
            try await DefaultCreateBudgetUseCase(repository: CreateBudgetMockRepository(), calendar: calendar)
                .execute(input(name: "  "))
        }
    }

    func testExecuteRejectsZeroOrNegativeAmount() async {
        let useCase = DefaultCreateBudgetUseCase(repository: CreateBudgetMockRepository(), calendar: calendar)

        await assertThrowsValidation("Budget amount must be greater than zero.") {
            try await useCase.execute(input(amount: 0))
        }

        await assertThrowsValidation("Budget amount must be greater than zero.") {
            try await useCase.execute(input(amount: -1))
        }
    }

    func testExecuteRejectsDuplicateCategoryBudget() async throws {
        let categoryID = UUID()
        let existingBudget = try existingBudget(categoryID: categoryID)
        let repository = CreateBudgetMockRepository(activeBudgets: [existingBudget])
        let useCase = DefaultCreateBudgetUseCase(repository: repository, calendar: calendar)

        await assertThrowsValidation("An active budget already exists for this category and period.") {
            try await useCase.execute(input(categoryID: categoryID))
        }

        XCTAssertTrue(repository.createdBudgets.isEmpty)
    }

    func testExecuteRejectsDuplicateTotalBudget() async throws {
        let repository = CreateBudgetMockRepository(activeBudgets: [try existingBudget(categoryID: nil)])
        let useCase = DefaultCreateBudgetUseCase(repository: repository, calendar: calendar)

        await assertThrowsValidation("An active budget already exists for this category and period.") {
            try await useCase.execute(input(categoryID: nil))
        }
    }

    func testExecuteCalculatesMonthStartAndEndDates() async throws {
        let repository = CreateBudgetMockRepository()
        let useCase = DefaultCreateBudgetUseCase(repository: repository, calendar: calendar)

        let budget = try await useCase.execute(input(month: date(year: 2026, month: 2, day: 14)))

        XCTAssertEqual(budget.startDate, date(year: 2026, month: 2, day: 1))
        XCTAssertEqual(budget.endDate, date(year: 2026, month: 2, day: 28))
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }

    private func input(
        categoryID: UUID? = UUID(),
        name: String = "Food",
        amount: Decimal = 100,
        month: Date? = nil
    ) -> CreateBudgetInput {
        CreateBudgetInput(
            categoryID: categoryID,
            name: name,
            amount: amount,
            month: month ?? date(year: 2026, month: 7, day: 14),
            alertThreshold: 0.8
        )
    }

    private func existingBudget(categoryID: UUID?) throws -> Budget {
        try Budget(
            categoryID: categoryID,
            name: "Existing",
            amount: 100,
            period: .monthly,
            startDate: date(year: 2026, month: 7, day: 1),
            endDate: date(year: 2026, month: 7, day: 31),
            alertThreshold: 0.8,
            calendar: calendar
        )
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        DateComponents(calendar: calendar, year: year, month: month, day: day).date ?? Date()
    }

    private func assertThrowsValidation(
        _ message: String,
        operation: () async throws -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            try await operation()
            XCTFail("Expected validation error.", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? AppError, .validation(message), file: file, line: line)
        }
    }
}

private final class CreateBudgetMockRepository: BudgetRepository {
    private let activeBudgetResults: [Budget]
    private(set) var createdBudgets: [Budget] = []

    init(activeBudgets: [Budget] = []) {
        self.activeBudgetResults = activeBudgets
    }

    func create(_ budget: Budget) async throws {
        createdBudgets.append(budget)
    }

    func update(_ budget: Budget) async throws { }

    func delete(id: UUID) async throws { }

    func budget(id: UUID) async throws -> Budget? {
        createdBudgets.first { $0.id == id }
    }

    func activeBudgets(for date: Date) async throws -> [Budget] {
        activeBudgetResults
    }

    func budgets(from startDate: Date, to endDate: Date) async throws -> [Budget] {
        createdBudgets
    }
}
