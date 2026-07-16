//
//  BudgetListViewModel.swift
//  SpendMind
//
//  Created by Icung on 15/07/26.
//

import Foundation
import Observation

typealias BudgetError = AppError

enum BudgetListState: Equatable {
    case idle
    case loading
    case loaded([BudgetProgress])
    case empty
    case failed(BudgetError)
}

@Observable
@MainActor
final class BudgetListViewModel {
    private(set) var state: BudgetListState = .idle

    // keep Sendable out of SwiftData repositories until this dependency is actually shared across actors.
    nonisolated(unsafe) private let getCurrentBudgetsUseCase: any GetCurrentBudgetsUseCase
    private let categoryRepository: (any CategoryRepository)?
    private let currency: CurrencyCode
    private let locale: Locale
    private let currentDate: Date
    private let calendar: Calendar
    private var categoriesByID: [UUID: Category] = [:]

    init(
        getCurrentBudgetsUseCase: any GetCurrentBudgetsUseCase,
        categoryRepository: (any CategoryRepository)? = nil,
        currency: CurrencyCode,
        locale: Locale = .current,
        currentDate: Date = .now,
        calendar: Calendar = .current
    ) {
        self.getCurrentBudgetsUseCase = getCurrentBudgetsUseCase
        self.categoryRepository = categoryRepository
        self.currency = currency
        self.locale = locale
        self.currentDate = currentDate
        self.calendar = calendar
    }

    func load() async {
        state = .loading

        do {
            loadCategories()
            let budgets = try await getCurrentBudgetsUseCase.execute(referenceDate: currentDate)
            state = budgets.isEmpty ? .empty : .loaded(budgets)
        } catch {
            state = .failed(AppError.wrap(error))
        }
    }

    func refresh() async {
        await load()
    }

    func retry() async {
        await load()
    }

    func formattedAmount(_ amount: Decimal) -> String {
        amount.formattedCurrency(code: currency.rawValue, locale: locale)
    }

    var currentMonthLabel: String {
        currentDate.formatted(.dateTime.month(.wide).year().locale(locale))
    }

    func shouldRefreshForExpenseChange(_ userInfo: [AnyHashable: Any]?) -> Bool {
        guard let dates = userInfo?[AppConstants.Notifications.expenseDatesKey] as? [Date] else {
            return true
        }

        // month-level invalidation is enough while budgets are monthly only.
        guard dates.contains(where: { calendar.isDate($0, equalTo: currentDate, toGranularity: .month) }) else {
            return false
        }

        guard let categoryIDs = userInfo?[AppConstants.Notifications.expenseCategoryIDsKey] as? [UUID] else {
            return true
        }

        let budgets = currentBudgets
        guard !budgets.isEmpty, !budgets.contains(where: { $0.budget.isTotalBudget }) else {
            return true
        }

        let budgetCategoryIDs = Set(budgets.compactMap(\.budget.categoryID))
        return categoryIDs.contains { budgetCategoryIDs.contains($0) }
    }

    var totalBudget: BudgetProgress? {
        currentBudgets.first { $0.budget.isTotalBudget }
    }

    var categoryBudgets: [BudgetProgress] {
        currentBudgets.filter { $0.budget.isCategoryBudget }
    }

    var formattedTotalLimit: String {
        formattedAmount(totalLimitAmount)
    }

    var formattedTotalSpent: String {
        formattedAmount(totalSpentAmount)
    }

    var formattedTotalRemaining: String {
        formattedAmount(totalRemainingAmount)
    }

    var totalLimitAmount: Decimal {
        currentBudgets.reduce(0) { $0 + $1.budget.amount }
    }

    var totalSpentAmount: Decimal {
        currentBudgets.reduce(0) { $0 + $1.spentAmount }
    }

    var totalRemainingAmount: Decimal {
        currentBudgets.reduce(0) { $0 + $1.remainingAmount }
    }

    var totalProgress: Decimal {
        totalLimitAmount > 0 ? totalSpentAmount / totalLimitAmount : 0
    }

    func categoryIcon(for progress: BudgetProgress) -> String {
        guard let categoryID = progress.budget.categoryID else {
            return "wallet.pass.fill"
        }

        return categoriesByID[categoryID]?.icon ?? "tag.fill"
    }

    func categoryColorHex(for progress: BudgetProgress) -> String {
        guard let categoryID = progress.budget.categoryID else {
            return "#576A8F"
        }

        return categoriesByID[categoryID]?.colorHex ?? "#FF7444"
    }

    func typeLabel(for progress: BudgetProgress) -> String {
        progress.budget.isTotalBudget ? "Total Budget" : "Category Budget"
    }

    func statusLabel(for status: BudgetStatus) -> String {
        switch status {
        case .safe: "Safe"
        case .warning: "Warning"
        case .exceeded: "Exceeded"
        }
    }

    func percentageUsed(for progress: BudgetProgress) -> String {
        let percent = NSDecimalNumber(decimal: progress.progress * 100).doubleValue.rounded()
        return "\(Int(percent))%"
    }

    private var currentBudgets: [BudgetProgress] {
        if case .loaded(let budgets) = state {
            return budgets
        }

        return []
    }

    private func loadCategories() {
        guard categoriesByID.isEmpty, let categoryRepository else { return }

        // category metadata is cosmetic; fallback icons beat failing the whole budget list.
        let categories = (try? categoryRepository.getCategories()) ?? []
        categoriesByID = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0) })
    }
}
