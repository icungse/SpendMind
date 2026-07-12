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

    func testCurrentMonthIsDefault() throws {
        let june = Expense(amount: 10, expenseDate: date(year: 2026, month: 6, day: 1))
        let july = Expense(amount: 20, expenseDate: date(year: 2026, month: 7, day: 1))
        let repository = ExpenseListMockRepository(expenses: [june, july])
        let viewModel = makeViewModel(repository: repository)

        viewModel.load()

        XCTAssertEqual(repository.fetchedMonths, [date(year: 2026, month: 7, day: 10)])
        XCTAssertEqual(viewModel.sections.flatMap(\.expenses).map(\.id), [july.id])
    }

    func testPreviousMonthIsSelectable() throws {
        let june = Expense(amount: 10, expenseDate: date(year: 2026, month: 6, day: 1))
        let july = Expense(amount: 20, expenseDate: date(year: 2026, month: 7, day: 1))
        let repository = ExpenseListMockRepository(expenses: [june, july])
        let viewModel = makeViewModel(repository: repository)

        viewModel.load()
        viewModel.selectMonth(viewModel.previousMonth)

        XCTAssertEqual(repository.monthFetchCount, 2)
        XCTAssertEqual(repository.fetchedMonths.map { Calendar(identifier: .gregorian).component(.month, from: $0) }, [7, 6])
        XCTAssertEqual(viewModel.sections.flatMap(\.expenses).map(\.id), [june.id])
    }

    func testFutureMonthIsDisabled() throws {
        let july = Expense(amount: 20, expenseDate: date(year: 2026, month: 7, day: 1))
        let august = Expense(amount: 30, expenseDate: date(year: 2026, month: 8, day: 1))
        let repository = ExpenseListMockRepository(expenses: [july, august])
        let viewModel = makeViewModel(repository: repository)

        viewModel.load()
        viewModel.selectMonth(viewModel.futureMonth)

        XCTAssertEqual(repository.monthFetchCount, 1)
        XCTAssertEqual(viewModel.sections.flatMap(\.expenses).map(\.id), [july.id])
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

    func testDeleteRemovesExpenseFromList() throws {
        let first = Expense(amount: 10, expenseDate: date(year: 2026, month: 7, day: 1))
        let second = Expense(amount: 20, expenseDate: date(year: 2026, month: 7, day: 2))
        let repository = ExpenseListMockRepository(expenses: [first, second])
        let viewModel = makeViewModel(repository: repository)

        viewModel.load()
        viewModel.delete(second)

        XCTAssertTrue(second.isDeleted)
        XCTAssertEqual(viewModel.sections.flatMap(\.expenses).map(\.id), [first.id])
        XCTAssertNil(viewModel.errorMessage)
    }

    func testSearchFiltersByTitle() throws {
        let coffee = Expense(amount: 10, note: "Morning drink", merchant: "Starbucks", expenseDate: date(year: 2026, month: 7, day: 1))
        let lunch = Expense(amount: 20, note: "Lunch", merchant: "Warung", expenseDate: date(year: 2026, month: 7, day: 2))
        let viewModel = makeViewModel(repository: ExpenseListMockRepository(expenses: [coffee, lunch]))

        viewModel.load()
        viewModel.searchText = "star"

        XCTAssertEqual(viewModel.sections.flatMap(\.expenses).map(\.id), [coffee.id])
    }

    func testSearchFiltersByNote() throws {
        let taxi = Expense(amount: 10, note: "Airport ride", merchant: "Grab", expenseDate: date(year: 2026, month: 7, day: 1))
        let groceries = Expense(amount: 20, note: "Groceries", merchant: "Market", expenseDate: date(year: 2026, month: 7, day: 2))
        let viewModel = makeViewModel(repository: ExpenseListMockRepository(expenses: [taxi, groceries]))

        viewModel.load()
        viewModel.searchText = "ride"

        XCTAssertEqual(viewModel.sections.flatMap(\.expenses).map(\.id), [taxi.id])
    }

    func testSearchIsCaseInsensitive() throws {
        let expense = Expense(amount: 10, note: "Monthly Coffee", merchant: nil, expenseDate: date(year: 2026, month: 7, day: 1))
        let viewModel = makeViewModel(repository: ExpenseListMockRepository(expenses: [expense]))

        viewModel.load()
        viewModel.searchText = "coffee"

        XCTAssertEqual(viewModel.sections.flatMap(\.expenses).map(\.id), [expense.id])
    }

    func testCategoryFilterShowsSelectedCategory() throws {
        let food = Category(name: "Food", icon: "fork.knife", colorHex: "#FF7444")
        let transport = Category(name: "Transport", icon: "car.fill", colorHex: "#576A8F")
        let coffee = Expense(amount: 10, expenseDate: date(year: 2026, month: 7, day: 1), category: food)
        let taxi = Expense(amount: 20, expenseDate: date(year: 2026, month: 7, day: 2), category: transport)
        let viewModel = makeViewModel(repository: ExpenseListMockRepository(expenses: [coffee, taxi]))

        viewModel.load()
        viewModel.toggleCategory(food)

        XCTAssertEqual(viewModel.sections.flatMap(\.expenses).map(\.id), [coffee.id])
    }

    func testCategoryFilterAllowsMultipleCategories() throws {
        let food = Category(name: "Food", icon: "fork.knife", colorHex: "#FF7444")
        let travel = Category(name: "Travel", icon: "airplane", colorHex: "#5B7FFF")
        let bills = Category(name: "Bills", icon: "doc.text", colorHex: "#888888")
        let coffee = Expense(amount: 10, expenseDate: date(year: 2026, month: 7, day: 1), category: food)
        let flight = Expense(amount: 20, expenseDate: date(year: 2026, month: 7, day: 2), category: travel)
        let bill = Expense(amount: 30, expenseDate: date(year: 2026, month: 7, day: 3), category: bills)
        let viewModel = makeViewModel(repository: ExpenseListMockRepository(expenses: [coffee, flight, bill]))

        viewModel.load()
        viewModel.toggleCategory(food)
        viewModel.toggleCategory(travel)

        XCTAssertEqual(viewModel.sections.flatMap(\.expenses).map(\.id), [flight.id, coffee.id])
    }

    func testClearCategoryFilterShowsAllExpenses() throws {
        let food = Category(name: "Food", icon: "fork.knife", colorHex: "#FF7444")
        let transport = Category(name: "Transport", icon: "car.fill", colorHex: "#576A8F")
        let coffee = Expense(amount: 10, expenseDate: date(year: 2026, month: 7, day: 1), category: food)
        let taxi = Expense(amount: 20, expenseDate: date(year: 2026, month: 7, day: 2), category: transport)
        let viewModel = makeViewModel(repository: ExpenseListMockRepository(expenses: [coffee, taxi]))

        viewModel.load()
        viewModel.toggleCategory(food)
        viewModel.clearCategoryFilter()

        XCTAssertTrue(viewModel.selectedCategoryIDs.isEmpty)
        XCTAssertEqual(viewModel.sections.flatMap(\.expenses).map(\.id), [taxi.id, coffee.id])
    }

    func testSearchAndCategoryFilterApplyTogether() throws {
        let food = Category(name: "Food", icon: "fork.knife", colorHex: "#FF7444")
        let transport = Category(name: "Transport", icon: "car.fill", colorHex: "#576A8F")
        let coffee = Expense(amount: 10, note: "Coffee", merchant: "Cafe", expenseDate: date(year: 2026, month: 7, day: 1), category: food)
        let taxi = Expense(amount: 20, note: "Coffee run", merchant: "Grab", expenseDate: date(year: 2026, month: 7, day: 2), category: transport)
        let viewModel = makeViewModel(repository: ExpenseListMockRepository(expenses: [coffee, taxi]))

        viewModel.load()
        viewModel.searchText = "coffee"
        viewModel.toggleCategory(food)

        XCTAssertEqual(viewModel.sections.flatMap(\.expenses).map(\.id), [coffee.id])
    }

    private func makeViewModel(repository: ExpenseListMockRepository) -> ExpenseListViewModel {
        ExpenseListViewModel(
            fetchExpensesUseCase: FetchExpensesUseCase(repository: repository),
            deleteExpenseUseCase: DeleteExpenseUseCase(repository: repository),
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
    private(set) var fetchedMonths: [Date] = []

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
        fetchedMonths.append(month)
        return expenses.filter {
            Calendar(identifier: .gregorian).isDate($0.expenseDate, equalTo: month, toGranularity: .month)
            && Calendar(identifier: .gregorian).isDate($0.expenseDate, equalTo: month, toGranularity: .year)
        }
    }

    func getExpenses(from startDate: Date, to endDate: Date) throws -> [Expense] {
        expenses.filter { $0.expenseDate >= startDate && $0.expenseDate < endDate }
    }
}
