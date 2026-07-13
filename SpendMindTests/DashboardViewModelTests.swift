//
//  DashboardViewModelTests.swift
//  SpendMindTests
//
//  Created by Icung on 05/07/26.
//

import XCTest
@testable import SpendMind

@MainActor
final class DashboardViewModelTests: XCTestCase {

    func testDashboardViewModelInitialState() {
        let viewModel = DashboardViewModel()

        XCTAssertEqual(viewModel.todaySpending, 0)
        XCTAssertEqual(viewModel.weeklySpending, 0)
        XCTAssertEqual(viewModel.monthlySpending, 0)
        XCTAssertEqual(viewModel.totalIncome, 0)
        XCTAssertEqual(viewModel.totalExpense, 0)
        XCTAssertEqual(viewModel.balance, 0)
        XCTAssertEqual(viewModel.budgetLimit, 0)
        XCTAssertEqual(viewModel.budgetSpent, 0)
        XCTAssertTrue(viewModel.recentTransactions.isEmpty)
        XCTAssertTrue(viewModel.financialSuggestions.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testDashboardViewModelLoadsUSDDataCorrectly() async {
        let viewModel = DashboardViewModel()

        await viewModel.loadDashboardData(currency: .USD)

        XCTAssertEqual(viewModel.currencyCode, "USD")
        XCTAssertEqual(viewModel.todaySpending, 22.50)
        XCTAssertEqual(viewModel.weeklySpending, 145.80)
        XCTAssertEqual(viewModel.monthlySpending, 680.50)
        XCTAssertEqual(viewModel.totalIncome, 4500.00)
        XCTAssertEqual(viewModel.totalExpense, 1250.00)
        XCTAssertEqual(viewModel.balance, 3250.00)
        XCTAssertEqual(viewModel.budgetLimit, 1500.00)
        XCTAssertEqual(viewModel.budgetSpent, 680.50)

        XCTAssertEqual(viewModel.recentTransactions.count, 3)
        XCTAssertEqual(viewModel.recentTransactions[0].merchant, "Starbucks")
        XCTAssertEqual(viewModel.recentTransactions[0].amount, 6.50)

        XCTAssertEqual(viewModel.financialSuggestions.count, 4)
        XCTAssertTrue(viewModel.financialSuggestions.contains("Reduce dining expenses."))
    }

    func testDashboardViewModelLoadsIDRDataCorrectly() async {
        let viewModel = DashboardViewModel()

        await viewModel.loadDashboardData(currency: .IDR)

        XCTAssertEqual(viewModel.currencyCode, "IDR")
        XCTAssertEqual(viewModel.todaySpending, 125000)
        XCTAssertEqual(viewModel.weeklySpending, 850000)
        XCTAssertEqual(viewModel.monthlySpending, 3500000)
        XCTAssertEqual(viewModel.totalIncome, 15000000)
        XCTAssertEqual(viewModel.totalExpense, 4500000)
        XCTAssertEqual(viewModel.balance, 10500000)
        XCTAssertEqual(viewModel.budgetLimit, 8000000)
        XCTAssertEqual(viewModel.budgetSpent, 3500000)

        XCTAssertEqual(viewModel.recentTransactions.count, 3)
        XCTAssertEqual(viewModel.recentTransactions[0].merchant, "Starbucks")
        XCTAssertEqual(viewModel.recentTransactions[0].amount, 65000)
    }

    func testDashboardViewModelCalculatesCurrentMonthExpenseTotal() async {
        let food = Category(name: "Food", icon: "fork.knife", colorHex: "#FF7444")
        let transport = Category(name: "Transport", icon: "car.fill", colorHex: "#576A8F")
        let currentMonthExpense = Expense(amount: 100, expenseDate: date(year: 2026, month: 7, day: 10), category: food)
        let anotherCurrentMonthExpense = Expense(amount: 50, expenseDate: date(year: 2026, month: 7, day: 1), category: food)
        let transportExpense = Expense(amount: 200, expenseDate: date(year: 2026, month: 7, day: 3), category: transport)
        let deletedExpense = Expense(amount: 25, expenseDate: date(year: 2026, month: 7, day: 2), isDeleted: true)
        let previousMonthExpense = Expense(amount: 500, expenseDate: date(year: 2026, month: 6, day: 30))
        let repository = DashboardExpenseRepository(
            expenses: [currentMonthExpense, anotherCurrentMonthExpense, transportExpense, deletedExpense, previousMonthExpense]
        )
        let viewModel = DashboardViewModel(
            fetchExpensesUseCase: FetchExpensesUseCase(repository: repository),
            calendar: Calendar(identifier: .gregorian),
            currentDate: date(year: 2026, month: 7, day: 13)
        )

        await viewModel.loadDashboardData(currency: .IDR)

        XCTAssertEqual(viewModel.monthlySpending, 350)
        XCTAssertEqual(viewModel.totalExpense, 350)
        XCTAssertEqual(viewModel.budgetSpent, 350)
        XCTAssertEqual(viewModel.categorySpendings.map(\.name), ["Transport", "Food"])
        XCTAssertEqual(viewModel.categorySpendings.map(\.amount), [200, 150])
        XCTAssertNil(viewModel.errorMessage)
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        DateComponents(
            calendar: Calendar(identifier: .gregorian),
            year: year,
            month: month,
            day: day
        ).date ?? Date()
    }
}

private final class DashboardExpenseRepository: ExpenseRepository {
    var expenses: [Expense]

    init(expenses: [Expense]) {
        self.expenses = expenses
    }

    func createExpense(_ expense: Expense) throws { expenses.append(expense) }
    func updateExpense(_ expense: Expense) throws { }
    func deleteExpense(id: UUID) throws { expenses.removeAll { $0.id == id } }
    func getExpense(id: UUID) throws -> Expense? { expenses.first { $0.id == id } }
    func getExpenses() throws -> [Expense] { expenses }
    func getExpensesByMonth(_ month: Date) throws -> [Expense] { expenses }

    func getExpenses(from startDate: Date, to endDate: Date) throws -> [Expense] {
        expenses.filter { $0.expenseDate >= startDate && $0.expenseDate < endDate }
    }
}
