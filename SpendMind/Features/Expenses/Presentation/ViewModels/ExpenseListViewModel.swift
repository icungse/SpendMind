//
//  ExpenseListViewModel.swift
//  SpendMind
//
//  Created by Icung on 10/07/26.
//

import Foundation
import Observation

struct ExpenseDateSection: Identifiable {
    let date: Date
    let expenses: [Expense]

    var id: Date { date }
}

@Observable
@MainActor
final class ExpenseListViewModel {
    private(set) var sections: [ExpenseDateSection] = []
    private(set) var errorMessage: String?
    private(set) var isLoading = false

    private let fetchExpensesUseCase: FetchExpensesUseCase
    private let calendar: Calendar
    private let currentDate: Date

    init(
        fetchExpensesUseCase: FetchExpensesUseCase,
        calendar: Calendar = .current,
        currentDate: Date = .now
    ) {
        self.fetchExpensesUseCase = fetchExpensesUseCase
        self.calendar = calendar
        self.currentDate = currentDate
    }

    func load() {
        isLoading = true
        defer {
            isLoading = false
        }

        do {
            let expenses = try fetchExpensesUseCase.execute(month: currentDate)
            sections = groupedByDay(expenses)
            errorMessage = nil
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
        }
    }

    private func groupedByDay(_ expenses: [Expense]) -> [ExpenseDateSection] {
        let grouped = Dictionary(grouping: expenses) { expense in
            calendar.startOfDay(for: expense.expenseDate)
        }

        // grouping stays in-memory; move to repository only if month lists become slow.
        return grouped.keys.sorted(by: >).map { date in
            ExpenseDateSection(date: date, expenses: grouped[date] ?? [])
        }
    }
}
