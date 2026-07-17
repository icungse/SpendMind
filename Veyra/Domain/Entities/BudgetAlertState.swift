//
//  BudgetAlertState.swift
//  Veyra
//
//  Created by Icung on 16/07/26.
//

import Foundation

struct BudgetAlertState: Equatable, Sendable {
    let budgetID: UUID
    var status: BudgetStatus
}
