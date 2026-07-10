//
//  FetchExpensesUseCase.swift
//  SpendMind
//
//  Created by Icung on 09/07/26.
//

import Foundation

struct FetchExpensesUseCase {
    private let repository: any ExpenseRepository

    init(repository: any ExpenseRepository) {
        self.repository = repository
    }

    func execute() throws -> [Expense] {
        try visibleNewestFirst(repository.getExpenses())
    }

    func execute(month: Date) throws -> [Expense] {
        try visibleNewestFirst(repository.getExpensesByMonth(month))
    }

    func execute(from startDate: Date, to endDate: Date) throws -> [Expense] {
        try visibleNewestFirst(repository.getExpenses(from: startDate, to: endDate))
    }

    private func visibleNewestFirst(_ expenses: [Expense]) -> [Expense] {
        // repository fetches; use case owns display ordering until query performance matters.
        expenses
            .filter { !$0.isDeleted }
            .sorted { $0.expenseDate > $1.expenseDate }
    }
}
