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
    private let currency: CurrencyCode
    private let locale: Locale
    private let currentDate: Date

    init(
        getCurrentBudgetsUseCase: any GetCurrentBudgetsUseCase,
        currency: CurrencyCode,
        locale: Locale = .current,
        currentDate: Date = .now
    ) {
        self.getCurrentBudgetsUseCase = getCurrentBudgetsUseCase
        self.currency = currency
        self.locale = locale
        self.currentDate = currentDate
    }

    func load() async {
        state = .loading

        do {
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

    var formattedTotalLimit: String {
        formattedAmount(currentBudgets.reduce(0) { $0 + $1.budget.amount })
    }

    var formattedTotalSpent: String {
        formattedAmount(currentBudgets.reduce(0) { $0 + $1.spentAmount })
    }

    var formattedTotalRemaining: String {
        formattedAmount(currentBudgets.reduce(0) { $0 + $1.remainingAmount })
    }

    private var currentBudgets: [BudgetProgress] {
        if case .loaded(let budgets) = state {
            return budgets
        }

        return []
    }
}
