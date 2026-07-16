//
//  BudgetAlertEvaluator.swift
//  SpendMind
//
//  Created by Icung on 16/07/26.
//

struct BudgetAlertEvaluation: Equatable, Sendable {
    let event: BudgetAlertEvent?
    let state: BudgetAlertState
}

struct BudgetAlertEvaluator: Sendable {
    func evaluate(progress: BudgetProgress, previousState: BudgetAlertState?) -> BudgetAlertEvaluation {
        let currentStatus = progress.status
        let previousStatus = previousState?.status ?? .safe
        let event: BudgetAlertEvent? = switch (previousStatus, currentStatus) {
        case (.safe, .warning):
            .thresholdReached
        case (.safe, .exceeded), (.warning, .exceeded):
            .budgetExceeded
        default:
            nil
        }

        return BudgetAlertEvaluation(
            event: event,
            state: BudgetAlertState(budgetID: progress.budget.id, status: currentStatus)
        )
    }
}
