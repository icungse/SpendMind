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
    var searchText = "" {
        didSet {
            applySearch()
        }
    }

    private let fetchExpensesUseCase: FetchExpensesUseCase
    private let deleteExpenseUseCase: DeleteExpenseUseCase
    private let calendar: Calendar
    private let currentDate: Date
    private var expenses: [Expense] = []

    init(
        fetchExpensesUseCase: FetchExpensesUseCase,
        deleteExpenseUseCase: DeleteExpenseUseCase,
        calendar: Calendar = .current,
        currentDate: Date = .now
    ) {
        self.fetchExpensesUseCase = fetchExpensesUseCase
        self.deleteExpenseUseCase = deleteExpenseUseCase
        self.calendar = calendar
        self.currentDate = currentDate
    }

    func load() {
        isLoading = true
        defer {
            isLoading = false
        }

        do {
            expenses = try fetchExpensesUseCase.execute(month: currentDate)
            applySearch()
            errorMessage = nil
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
        }
    }

    func delete(_ expense: Expense) {
        do {
            try deleteExpenseUseCase.execute(id: expense.id, isConfirmed: true)
            load()
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
        }
    }

    private func applySearch() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            sections = groupedByDay(expenses)
            return
        }

        // in-memory month search; move to repository only when full-history search or scale requires it.
        sections = groupedByDay(expenses.filter { expense in
            let title = expense.merchant ?? expense.note
            return title.localizedCaseInsensitiveContains(query)
                || expense.note.localizedCaseInsensitiveContains(query)
        })
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
