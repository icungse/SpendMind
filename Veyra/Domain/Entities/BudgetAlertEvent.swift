//
//  BudgetAlertEvent.swift
//  Veyra
//
//  Created by Icung on 16/07/26.
//

enum BudgetAlertEvent: Equatable, Sendable {
    case thresholdReached
    case budgetExceeded
}
