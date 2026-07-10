//
//  ExpenseListViewModelTests.swift
//  SpendMindTests
//
//  Created by Icung on 10/07/26.
//

import XCTest
@testable import SpendMind

@MainActor
final class ExpenseListViewModelTests: XCTestCase {
    func testLoadShowsCurrentMonthExpensesGroupedByDateNewestFirst() throws {
        let julyOne = Expense(amount: 10, expenseDate: date(year: 2026, month: 7, day: 1))
        let julyTwoMorning = Expense(amount: 20, expenseDate: date(year: 2026, month: 7, day: 2, hour: 8))
        let julyTwoEvening = Expense(amount: 30, expenseDate: date(year: 2026, month: 7, day: 2, hour: 20))
        let deleted = Expense(amount: 40, expenseDate: date(year: 2026, month: 7, day: 3), isDeleted: true)
        let august = Expense(amount: 50, expenseDate: date(year: 2026, month: 8, day: 1))
        let repository = ExpenseListMockRepository(expenses: [julyOne, julyTwoMorning, julyTwoEvening, deleted, august])
        let viewModel = makeViewModel(repository: repository)

        viewModel.load()

        XCTAssertEqual(repository.monthFetchCount, 1)
        XCTAssertEqual(viewModel.sections.map(\.date), [date(year: 2026, month: 7, day: 2), date(year: 2026, month: 7, day: 1)])
        XCTAssertEqual(viewModel.sections[0].expenses.map(\.id), [julyTwoEvening.id, julyTwoMorning.id])
        XCTAssertEqual(viewModel.sections[1].expenses.map(\.id), [julyOne.id])
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadRefreshesExpenses() throws {
        let first = Expense(amount: 10, expenseDate: date(year: 2026, month: 7, day: 1))
        let second = Expense(amount: 20, expenseDate: date(year: 2026, month: 7, day: 2))
        let repository = ExpenseListMockRepository(expenses: [first])
        let viewModel = makeViewModel(repository: repository)

        viewModel.load()
        repository.expenses = [first, second]
        viewModel.load()

        XCTAssertEqual(repository.monthFetchCount, 2)
        XCTAssertEqual(viewModel.sections.flatMap(\.expenses).map(\.id), [second.id, first.id])
    }

    private func makeViewModel(repository: ExpenseListMockRepository) -> ExpenseListViewModel {
        ExpenseListViewModel(
            fetchExpensesUseCase: FetchExpensesUseCase(repository: repository),
            calendar: Calendar(identifier: .gregorian),
            currentDate: date(year: 2026, month: 7, day: 10)
        )
    }

    private func date(year: Int, month: Int, day: Int, hour: Int = 0) -> Date {
        DateComponents(
            calendar: Calendar(identifier: .gregorian),
            year: year,
            month: month,
            day: day,
            hour: hour
        ).date ?? Date()
    }
}

private final class ExpenseListMockRepository: ExpenseRepository {
    var expenses: [Expense]
    private(set) var monthFetchCount = 0

    init(expenses: [Expense]) {
        self.expenses = expenses
    }

    func createExpense(_ expense: Expense) throws { expenses.append(expense) }
    func updateExpense(_ expense: Expense) throws { }
    func deleteExpense(id: UUID) throws { expenses.removeAll { $0.id == id } }
    func getExpense(id: UUID) throws -> Expense? { expenses.first { $0.id == id } }
    func getExpenses() throws -> [Expense] { expenses }

    func getExpensesByMonth(_ month: Date) throws -> [Expense] {
        monthFetchCount += 1
        return expenses.filter {
            Calendar(identifier: .gregorian).isDate($0.expenseDate, equalTo: month, toGranularity: .month)
            && Calendar(identifier: .gregorian).isDate($0.expenseDate, equalTo: month, toGranularity: .year)
        }
    }

    func getExpenses(from startDate: Date, to endDate: Date) throws -> [Expense] {
        expenses.filter { $0.expenseDate >= startDate && $0.expenseDate < endDate }
    }
}
