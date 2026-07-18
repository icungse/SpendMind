//
//  DashboardViewModel.swift
//  Veyra
//
//  Created by Icung on 05/07/26.
//

import Foundation
import Observation

struct DashboardTransaction: Identifiable, Hashable {
    let id: UUID
    let merchant: String
    let amount: Decimal
    let categoryName: String
    let categoryIcon: String
    let isExpense: Bool
    let date: Date
}

struct DashboardCategorySpending: Identifiable, Hashable {
    let id: UUID
    let name: String
    let icon: String
    let colorHex: String
    let amount: Decimal
}

@Observable
@MainActor
final class DashboardViewModel {
    private(set) var todaySpending: Decimal = 0
    private(set) var weeklySpending: Decimal = 0
    private(set) var monthlySpending: Decimal = 0
    private(set) var totalIncome: Decimal = 0
    private(set) var totalExpense: Decimal = 0
    private(set) var balance: Decimal = 0
    private(set) var budgetLimit: Decimal = 0
    private(set) var budgetSpent: Decimal = 0
    private(set) var budgetWarningCount: Int = 0
    private(set) var budgetExceededCount: Int = 0
    private(set) var hasBudgets: Bool = false
    private(set) var budgetInsights: [BudgetInsight] = []
    private(set) var recentTransactions: [DashboardTransaction] = []
    private(set) var categorySpendings: [DashboardCategorySpending] = []
    private(set) var financialSuggestions: [String] = []
    private(set) var currencyCode: String = "IDR"
    private(set) var isLoading: Bool = false
    private(set) var errorMessage: String?

    private let dateService: any DateServiceProtocol
    private let fetchExpensesUseCase: FetchExpensesUseCase?
    nonisolated(unsafe) private let getCurrentBudgetsUseCase: any GetCurrentBudgetsUseCase
    private let generateBudgetInsightsUseCase: DefaultGenerateBudgetInsightsUseCase
    private let hasBudgetUseCase: Bool
    private let calendar: Calendar
    private let currentDate: Date

    init(
        dateService: any DateServiceProtocol = DateService(),
        fetchExpensesUseCase: FetchExpensesUseCase? = nil,
        getCurrentBudgetsUseCase: (any GetCurrentBudgetsUseCase)? = nil,
        generateBudgetInsightsUseCase: DefaultGenerateBudgetInsightsUseCase = DefaultGenerateBudgetInsightsUseCase(),
        calendar: Calendar = .current,
        currentDate: Date = .now
    ) {
        self.dateService = dateService
        self.fetchExpensesUseCase = fetchExpensesUseCase
        self.getCurrentBudgetsUseCase = getCurrentBudgetsUseCase ?? EmptyDashboardBudgetsUseCase()
        self.generateBudgetInsightsUseCase = generateBudgetInsightsUseCase
        self.hasBudgetUseCase = getCurrentBudgetsUseCase != nil
        self.calendar = calendar
        self.currentDate = currentDate
    }

    func loadDashboardData(currency: CurrencyCode) async {
        isLoading = true
        // temporary delay to simulate on-device database load
        try? await Task.sleep(nanoseconds: 200_000_000)

        self.currencyCode = currency.rawValue

        if currency == .USD {
            todaySpending = 22.50
            weeklySpending = 145.80
            monthlySpending = 680.50
            totalIncome = 4500.00
            totalExpense = 1250.00
            balance = 3250.00
            budgetLimit = 1500.00
            budgetSpent = 680.50
        } else {
            todaySpending = 125000
            weeklySpending = 850000
            monthlySpending = 3500000
            totalIncome = 15000000
            totalExpense = 4500000
            balance = 10500000
            budgetLimit = 8000000
            budgetSpent = 3500000
        }

        loadMonthlyExpenseTotal()
        await loadBudgetSummary()

        let now = Date()
        recentTransactions = [
            DashboardTransaction(
                id: UUID(),
                merchant: "Starbucks",
                amount: currency == .USD ? 6.50 : 65000,
                categoryName: "Food",
                categoryIcon: "cup.and.saucer.fill",
                isExpense: true,
                date: now
            ),
            DashboardTransaction(
                id: UUID(),
                merchant: "Monthly Salary",
                amount: currency == .USD ? 4500.00 : 15000000,
                categoryName: "Salary",
                categoryIcon: "banknote.fill",
                isExpense: false,
                date: dateService.startOfDay(for: now).addingTimeInterval(-86400)
            ),
            DashboardTransaction(
                id: UUID(),
                merchant: "Uber Ride",
                amount: currency == .USD ? 22.00 : 150000,
                categoryName: "Transportation",
                categoryIcon: "car.fill",
                isExpense: true,
                date: dateService.startOfDay(for: now).addingTimeInterval(-172800)
            )
        ]

        financialSuggestions = [
            "Reduce dining expenses.",
            "Coffee purchases have increased.",
            "Shopping remains within healthy limits.",
            "Bills account for 42% of monthly income."
        ]

        isLoading = false
    }

    var budgetStatus: BudgetStatus {
        guard budgetLimit > 0 else { return .safe }
        if budgetSpent > budgetLimit { return .exceeded }
        if budgetSpent / budgetLimit >= 0.8 { return .warning }
        return .safe
    }

    var budgetRemaining: Decimal {
        budgetLimit - budgetSpent
    }

    var budgetProgress: Decimal {
        budgetLimit > 0 ? budgetSpent / budgetLimit : 0
    }

    var budgetProgressPercentText: String {
        let percent = NSDecimalNumber(decimal: budgetProgress * 100).doubleValue.rounded()
        return "\(Int(percent))%"
    }

    var budgetWarningMessage: String? {
        switch budgetStatus {
        case .safe:
            return nil
        case .warning:
            return String(
                localized: "Monthly budget is near its limit. \(budgetRemaining.formattedCurrency(code: currencyCode)) remains."
            )
        case .exceeded:
            return String(localized: "Monthly budget is exceeded by \((-budgetRemaining).formattedCurrency(code: currencyCode)).")
        }
    }

    func shouldRefreshForExpenseChange(_ userInfo: [AnyHashable: Any]?) -> Bool {
        guard let dates = userInfo?[AppConstants.Notifications.expenseDatesKey] as? [Date] else {
            return true
        }

        // budgets are monthly only, so month-level invalidation is enough.
        return dates.contains { calendar.isDate($0, equalTo: currentDate, toGranularity: .month) }
    }

    private func loadMonthlyExpenseTotal() {
        guard let fetchExpensesUseCase else { return }
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentDate) else {
            errorMessage = "Invalid dashboard month."
            return
        }

        do {
            let expenses = try fetchExpensesUseCase.execute(from: monthInterval.start, to: monthInterval.end)
            let total = expenses.reduce(Decimal(0)) { $0 + $1.amount }
            monthlySpending = total
            totalExpense = total
            budgetSpent = total
            loadCategorySpendings(from: expenses)
            errorMessage = nil
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
        }
    }

    private func loadBudgetSummary() async {
        guard hasBudgetUseCase else {
            hasBudgets = budgetLimit > 0
            budgetWarningCount = budgetStatus == .warning ? 1 : 0
            budgetExceededCount = budgetStatus == .exceeded ? 1 : 0
            budgetInsights = []
            return
        }

        do {
            let budgets = try await getCurrentBudgetsUseCase.execute(referenceDate: currentDate)
            budgetLimit = budgets.reduce(0) { $0 + $1.budget.amount }
            budgetSpent = budgets.reduce(0) { $0 + $1.spentAmount }
            budgetWarningCount = budgets.filter { $0.status == .warning }.count
            budgetExceededCount = budgets.filter { $0.status == .exceeded }.count
            hasBudgets = !budgets.isEmpty
            budgetInsights = generateBudgetInsightsUseCase.execute(progress: budgets, referenceDate: currentDate)
            errorMessage = nil
        } catch {
            budgetInsights = []
            errorMessage = AppError.wrap(error).errorDescription
        }
    }

    private func loadCategorySpendings(from expenses: [Expense]) {
        var totals: [UUID: DashboardCategorySpending] = [:]

        // one loaded month is small enough; add a repository aggregate only after this is slow.
        for expense in expenses {
            let id = expense.category?.id ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000") ?? UUID()
            let current = totals[id]?.amount ?? 0
            totals[id] = DashboardCategorySpending(
                id: id,
                name: expense.category?.name ?? "Uncategorized",
                icon: expense.category?.icon ?? "creditcard.fill",
                colorHex: expense.category?.colorHex ?? "#576A8F",
                amount: current + expense.amount
            )
        }

        categorySpendings = totals.values.sorted { $0.amount > $1.amount }
    }
}

private struct EmptyDashboardBudgetsUseCase: GetCurrentBudgetsUseCase {
    func execute(referenceDate: Date) async throws -> [BudgetProgress] {
        []
    }
}
