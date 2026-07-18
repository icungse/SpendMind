//
//  ExpenseListViewModelTests.swift
//  VeyraTests
//
//  Created by Icung on 10/07/26.
//

import XCTest
@testable import Veyra

@MainActor
final class ExpenseListViewModelTests: XCTestCase {
    func testLoadShowsCurrentMonthToCurrentDateGroupedByDateNewestFirst() throws {
        let julyOne = Expense(amount: 10, expenseDate: date(year: 2026, month: 7, day: 1))
        let julyTwoMorning = Expense(amount: 20, expenseDate: date(year: 2026, month: 7, day: 2, hour: 8))
        let julyTwoEvening = Expense(amount: 30, expenseDate: date(year: 2026, month: 7, day: 2, hour: 20))
        let deleted = Expense(amount: 40, expenseDate: date(year: 2026, month: 7, day: 10), isDeleted: true)
        let august = Expense(amount: 50, expenseDate: date(year: 2026, month: 8, day: 1))
        let today = Expense(amount: 60, expenseDate: date(year: 2026, month: 7, day: 10, hour: 12))
        let repository = ExpenseListMockRepository(expenses: [julyOne, julyTwoMorning, julyTwoEvening, deleted, august, today])
        let viewModel = makeViewModel(repository: repository)

        viewModel.load()

        XCTAssertEqual(repository.rangeFetchCount, 1)
        XCTAssertEqual(viewModel.sections.map(\.date), [date(year: 2026, month: 7, day: 10), date(year: 2026, month: 7, day: 2), date(year: 2026, month: 7, day: 1)])
        XCTAssertEqual(viewModel.sections[0].expenses.map(\.id), [today.id])
        XCTAssertEqual(viewModel.sections[1].expenses.map(\.id), [julyTwoEvening.id, julyTwoMorning.id])
        XCTAssertEqual(viewModel.sections[2].expenses.map(\.id), [julyOne.id])
        XCTAssertNil(viewModel.errorMessage)
    }

    func testCurrentMonthToCurrentDateIsDefault() throws {
        let yesterday = Expense(amount: 10, expenseDate: date(year: 2026, month: 7, day: 9))
        let today = Expense(amount: 20, expenseDate: date(year: 2026, month: 7, day: 10))
        let repository = ExpenseListMockRepository(expenses: [yesterday, today])
        let viewModel = makeViewModel(repository: repository)

        viewModel.load()

        XCTAssertEqual(repository.fetchedRanges.map(\.start), [date(year: 2026, month: 7, day: 1)])
        XCTAssertEqual(repository.fetchedRanges.map(\.end), [date(year: 2026, month: 7, day: 11)])
        XCTAssertEqual(viewModel.sections.flatMap(\.expenses).map(\.id), [today.id, yesterday.id])
    }

    func testPreviousMonthIsSelectable() throws {
        let june = Expense(amount: 10, expenseDate: date(year: 2026, month: 6, day: 9))
        let july = Expense(amount: 20, expenseDate: date(year: 2026, month: 7, day: 10))
        let repository = ExpenseListMockRepository(expenses: [june, july])
        let viewModel = makeViewModel(repository: repository)

        viewModel.load()
        viewModel.selectMonth(date(year: 2026, month: 6, day: 15))

        XCTAssertEqual(repository.rangeFetchCount, 2)
        XCTAssertEqual(repository.fetchedRanges.map(\.start), [date(year: 2026, month: 7, day: 1), date(year: 2026, month: 6, day: 1)])
        XCTAssertEqual(repository.fetchedRanges.map(\.end), [date(year: 2026, month: 7, day: 11), date(year: 2026, month: 7, day: 1)])
        XCTAssertEqual(viewModel.sections.flatMap(\.expenses).map(\.id), [june.id])
    }

    func testDateRangeIsSelectable() throws {
        let first = Expense(amount: 10, expenseDate: date(year: 2026, month: 7, day: 1))
        let second = Expense(amount: 20, expenseDate: date(year: 2026, month: 7, day: 5))
        let third = Expense(amount: 30, expenseDate: date(year: 2026, month: 7, day: 10))
        let repository = ExpenseListMockRepository(expenses: [first, second, third])
        let viewModel = makeViewModel(repository: repository)

        viewModel.load()
        viewModel.setStartDate(date(year: 2026, month: 7, day: 5))
        viewModel.setEndDate(date(year: 2026, month: 7, day: 5))

        XCTAssertEqual(repository.rangeFetchCount, 3)
        XCTAssertEqual(repository.fetchedRanges.last?.start, date(year: 2026, month: 7, day: 5))
        XCTAssertEqual(repository.fetchedRanges.last?.end, date(year: 2026, month: 7, day: 6))
        XCTAssertEqual(viewModel.sections.flatMap(\.expenses).map(\.id), [second.id])
    }

    func testDateFilterModeSwitchesBetweenMonthAndDayRange() throws {
        let repository = ExpenseListMockRepository(expenses: [])
        let viewModel = makeViewModel(repository: repository)

        viewModel.setStartDate(date(year: 2026, month: 7, day: 5))
        XCTAssertEqual(viewModel.dateFilterMode, .dayRange)

        viewModel.selectDateFilterMode(.month)

        XCTAssertEqual(viewModel.dateFilterMode, .month)
        XCTAssertEqual(repository.fetchedRanges.last?.start, date(year: 2026, month: 7, day: 1))
        XCTAssertEqual(repository.fetchedRanges.last?.end, date(year: 2026, month: 7, day: 11))

        viewModel.selectMonth(date(year: 2026, month: 6, day: 15))
        viewModel.setStartDate(date(year: 2026, month: 6, day: 9))
        viewModel.clearDateFilter()

        XCTAssertEqual(viewModel.dateFilterMode, .month)
        XCTAssertEqual(viewModel.selectedMonth, date(year: 2026, month: 7, day: 1))
        XCTAssertEqual(repository.fetchedRanges.last?.start, date(year: 2026, month: 7, day: 1))
        XCTAssertEqual(repository.fetchedRanges.last?.end, date(year: 2026, month: 7, day: 11))
    }

    func testFutureEndDateClampsToCurrentDate() throws {
        let today = Expense(amount: 20, expenseDate: date(year: 2026, month: 7, day: 10))
        let tomorrow = Expense(amount: 30, expenseDate: date(year: 2026, month: 7, day: 11))
        let repository = ExpenseListMockRepository(expenses: [today, tomorrow])
        let viewModel = makeViewModel(repository: repository)

        viewModel.load()
        viewModel.setEndDate(date(year: 2026, month: 7, day: 11))

        XCTAssertEqual(repository.rangeFetchCount, 2)
        XCTAssertEqual(repository.fetchedRanges.last?.end, date(year: 2026, month: 7, day: 11))
        XCTAssertEqual(viewModel.sections.flatMap(\.expenses).map(\.id), [today.id])
    }

    func testLoadRefreshesExpenses() throws {
        let first = Expense(amount: 10, expenseDate: date(year: 2026, month: 7, day: 10, hour: 8))
        let second = Expense(amount: 20, expenseDate: date(year: 2026, month: 7, day: 10, hour: 20))
        let repository = ExpenseListMockRepository(expenses: [first])
        let viewModel = makeViewModel(repository: repository)

        viewModel.load()
        repository.expenses = [first, second]
        viewModel.load()

        XCTAssertEqual(repository.rangeFetchCount, 2)
        XCTAssertEqual(viewModel.sections.flatMap(\.expenses).map(\.id), [second.id, first.id])
    }

    func testDeleteRemovesExpenseFromList() throws {
        let first = Expense(amount: 10, expenseDate: date(year: 2026, month: 7, day: 10, hour: 8))
        let second = Expense(amount: 20, expenseDate: date(year: 2026, month: 7, day: 10, hour: 20))
        let repository = ExpenseListMockRepository(expenses: [first, second])
        let viewModel = makeViewModel(repository: repository)

        viewModel.load()
        viewModel.delete(second)

        XCTAssertTrue(second.isDeleted)
        XCTAssertEqual(viewModel.sections.flatMap(\.expenses).map(\.id), [first.id])
        XCTAssertNil(viewModel.errorMessage)
    }

    func testSearchFiltersByTitle() throws {
        let coffee = Expense(amount: 10, note: "Morning drink", merchant: "Starbucks", expenseDate: date(year: 2026, month: 7, day: 10, hour: 8))
        let lunch = Expense(amount: 20, note: "Lunch", merchant: "Warung", expenseDate: date(year: 2026, month: 7, day: 10, hour: 20))
        let viewModel = makeViewModel(repository: ExpenseListMockRepository(expenses: [coffee, lunch]))

        viewModel.load()
        viewModel.searchText = "star"

        XCTAssertEqual(viewModel.sections.flatMap(\.expenses).map(\.id), [coffee.id])
    }

    func testSearchFiltersByNote() throws {
        let taxi = Expense(amount: 10, note: "Airport ride", merchant: "Grab", expenseDate: date(year: 2026, month: 7, day: 10, hour: 8))
        let groceries = Expense(amount: 20, note: "Groceries", merchant: "Market", expenseDate: date(year: 2026, month: 7, day: 10, hour: 20))
        let viewModel = makeViewModel(repository: ExpenseListMockRepository(expenses: [taxi, groceries]))

        viewModel.load()
        viewModel.searchText = "ride"

        XCTAssertEqual(viewModel.sections.flatMap(\.expenses).map(\.id), [taxi.id])
    }

    func testSearchIsCaseInsensitive() throws {
        let expense = Expense(amount: 10, note: "Daily Coffee", merchant: nil, expenseDate: date(year: 2026, month: 7, day: 10))
        let viewModel = makeViewModel(repository: ExpenseListMockRepository(expenses: [expense]))

        viewModel.load()
        viewModel.searchText = "coffee"

        XCTAssertEqual(viewModel.sections.flatMap(\.expenses).map(\.id), [expense.id])
    }

    func testCategoryFilterShowsSelectedCategory() throws {
        let food = Category(name: "Food", icon: "fork.knife", colorHex: "#FF7444")
        let transport = Category(name: "Transport", icon: "car.fill", colorHex: "#576A8F")
        let coffee = Expense(amount: 10, expenseDate: date(year: 2026, month: 7, day: 10, hour: 8), category: food)
        let taxi = Expense(amount: 20, expenseDate: date(year: 2026, month: 7, day: 10, hour: 20), category: transport)
        let viewModel = makeViewModel(repository: ExpenseListMockRepository(expenses: [coffee, taxi]))

        viewModel.load()
        viewModel.toggleCategory(food)

        XCTAssertEqual(viewModel.sections.flatMap(\.expenses).map(\.id), [coffee.id])
    }

    func testCategoryFilterAllowsMultipleCategories() throws {
        let food = Category(name: "Food", icon: "fork.knife", colorHex: "#FF7444")
        let travel = Category(name: "Travel", icon: "airplane", colorHex: "#5B7FFF")
        let bills = Category(name: "Bills", icon: "doc.text", colorHex: "#888888")
        let coffee = Expense(amount: 10, expenseDate: date(year: 2026, month: 7, day: 10, hour: 8), category: food)
        let flight = Expense(amount: 20, expenseDate: date(year: 2026, month: 7, day: 10, hour: 20), category: travel)
        let bill = Expense(amount: 30, expenseDate: date(year: 2026, month: 7, day: 10, hour: 22), category: bills)
        let viewModel = makeViewModel(repository: ExpenseListMockRepository(expenses: [coffee, flight, bill]))

        viewModel.load()
        viewModel.toggleCategory(food)
        viewModel.toggleCategory(travel)

        XCTAssertEqual(viewModel.sections.flatMap(\.expenses).map(\.id), [flight.id, coffee.id])
    }

    func testClearCategoryFilterShowsAllExpenses() throws {
        let food = Category(name: "Food", icon: "fork.knife", colorHex: "#FF7444")
        let transport = Category(name: "Transport", icon: "car.fill", colorHex: "#576A8F")
        let coffee = Expense(amount: 10, expenseDate: date(year: 2026, month: 7, day: 10, hour: 8), category: food)
        let taxi = Expense(amount: 20, expenseDate: date(year: 2026, month: 7, day: 10, hour: 20), category: transport)
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
        let coffee = Expense(amount: 10, note: "Coffee", merchant: "Cafe", expenseDate: date(year: 2026, month: 7, day: 10, hour: 8), category: food)
        let taxi = Expense(amount: 20, note: "Coffee run", merchant: "Grab", expenseDate: date(year: 2026, month: 7, day: 10, hour: 20), category: transport)
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
    private(set) var rangeFetchCount = 0
    private(set) var fetchedRanges: [DateInterval] = []

    init(expenses: [Expense]) {
        self.expenses = expenses
    }

    func createExpense(_ expense: Expense) throws { expenses.append(expense) }
    func updateExpense(_ expense: Expense) throws { }
    func deleteExpense(id: UUID) throws { expenses.removeAll { $0.id == id } }
    func getExpense(id: UUID) throws -> Expense? { expenses.first { $0.id == id } }
    func getExpenses() throws -> [Expense] { expenses }

    func getExpensesByMonth(_ month: Date) throws -> [Expense] {
        return expenses.filter {
            Calendar(identifier: .gregorian).isDate($0.expenseDate, equalTo: month, toGranularity: .month)
            && Calendar(identifier: .gregorian).isDate($0.expenseDate, equalTo: month, toGranularity: .year)
        }
    }

    func getExpenses(from startDate: Date, to endDate: Date) throws -> [Expense] {
        rangeFetchCount += 1
        fetchedRanges.append(DateInterval(start: startDate, end: endDate))
        return expenses.filter { $0.expenseDate >= startDate && $0.expenseDate < endDate }
    }
}
