//
//  BudgetProgress.swift
//  Veyra
//
//  Created by Icung on 13/07/26.
//

import Foundation

struct BudgetProgress: Equatable, Sendable {
    let budget: Budget
    let spentAmount: Decimal
    let remainingAmount: Decimal
    let progress: Decimal
    let status: BudgetStatus

    init(budget: Budget, spentAmount: Decimal) {
        let progress = spentAmount / budget.amount

        self.budget = budget
        self.spentAmount = spentAmount
        self.remainingAmount = budget.amount - spentAmount
        self.progress = progress
        self.status = if spentAmount > budget.amount {
            .exceeded
        } else if progress >= budget.alertThreshold {
            .warning
        } else {
            .safe
        }
    }
}
