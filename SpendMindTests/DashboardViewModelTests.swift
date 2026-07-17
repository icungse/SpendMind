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
        XCTAssertEqual(viewModel.budgetWarningCount, 0)
        XCTAssertEqual(viewModel.budgetExceededCount, 0)
        XCTAssertFalse(viewModel.hasBudgets)
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

    func testDashboardBudgetWarningAndExceededCopy() async {
        let warningRepository = DashboardExpenseRepository(expenses: [Expense(amount: 1_300)])
        let warningViewModel = DashboardViewModel(fetchExpensesUseCase: FetchExpensesUseCase(repository: warningRepository))

        await warningViewModel.loadDashboardData(currency: .USD)

        XCTAssertEqual(warningViewModel.budgetStatus, .warning)
        XCTAssertTrue(warningViewModel.budgetWarningMessage?.contains("Monthly budget is near its limit.") == true)
        XCTAssertTrue(warningViewModel.budgetWarningMessage?.contains("remains.") == true)

        let exceededRepository = DashboardExpenseRepository(expenses: [Expense(amount: 1_700)])
        let exceededViewModel = DashboardViewModel(fetchExpensesUseCase: FetchExpensesUseCase(repository: exceededRepository))

        await exceededViewModel.loadDashboardData(currency: .USD)

        XCTAssertEqual(exceededViewModel.budgetStatus, .exceeded)
        XCTAssertTrue(exceededViewModel.budgetWarningMessage?.contains("Monthly budget is exceeded by") == true)
    }

    func testDashboardLoadsBudgetSummaryFromCurrentBudgets() async throws {
        let budgets = [
            BudgetProgress(budget: try budget(amount: 100), spentAmount: 40),
            BudgetProgress(budget: try budget(amount: 50), spentAmount: 60),
            BudgetProgress(budget: try budget(amount: 200), spentAmount: 160)
        ]
        let viewModel = DashboardViewModel(getCurrentBudgetsUseCase: DashboardBudgetUseCase(budgets: budgets))

        await viewModel.loadDashboardData(currency: .USD)

        XCTAssertTrue(viewModel.hasBudgets)
        XCTAssertEqual(viewModel.budgetLimit, 350)
        XCTAssertEqual(viewModel.budgetSpent, 260)
        XCTAssertEqual(viewModel.budgetRemaining, 90)
        XCTAssertEqual(viewModel.budgetWarningCount, 1)
        XCTAssertEqual(viewModel.budgetExceededCount, 1)
        XCTAssertEqual(viewModel.budgetProgressPercentText, "74%")
    }

    func testDashboardBudgetSummaryHandlesNoBudgets() async {
        let viewModel = DashboardViewModel(getCurrentBudgetsUseCase: DashboardBudgetUseCase(budgets: []))

        await viewModel.loadDashboardData(currency: .USD)

        XCTAssertFalse(viewModel.hasBudgets)
        XCTAssertEqual(viewModel.budgetLimit, 0)
        XCTAssertEqual(viewModel.budgetSpent, 0)
        XCTAssertEqual(viewModel.budgetRemaining, 0)
        XCTAssertEqual(viewModel.budgetProgressPercentText, "0%")
        XCTAssertEqual(viewModel.budgetWarningCount, 0)
        XCTAssertEqual(viewModel.budgetExceededCount, 0)
    }

    func testDashboardBudgetRefreshesOnlyForCurrentMonthExpenseChanges() {
        let viewModel = DashboardViewModel(currentDate: date(year: 2026, month: 7, day: 13))

        XCTAssertTrue(viewModel.shouldRefreshForExpenseChange([
            AppConstants.Notifications.expenseDatesKey: [date(year: 2026, month: 7, day: 1)]
        ]))
        XCTAssertFalse(viewModel.shouldRefreshForExpenseChange([
            AppConstants.Notifications.expenseDatesKey: [date(year: 2026, month: 8, day: 1)]
        ]))
        XCTAssertTrue(viewModel.shouldRefreshForExpenseChange(nil))
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        DateComponents(
            calendar: Calendar(identifier: .gregorian),
            year: year,
            month: month,
            day: day
        ).date ?? Date()
    }

    private func budget(amount: Decimal) throws -> Budget {
        try Budget(
            name: "Monthly",
            amount: amount,
            period: .monthly,
            startDate: date(year: 2026, month: 7, day: 1),
            endDate: date(year: 2026, month: 7, day: 31),
            alertThreshold: 0.8,
            calendar: Calendar(identifier: .gregorian)
        )
    }
}

private final class DashboardBudgetUseCase: GetCurrentBudgetsUseCase {
    let budgets: [BudgetProgress]

    init(budgets: [BudgetProgress]) {
        self.budgets = budgets
    }

    func execute(referenceDate: Date) async throws -> [BudgetProgress] {
        budgets
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
