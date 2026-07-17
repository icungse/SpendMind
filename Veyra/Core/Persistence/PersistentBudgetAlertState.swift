//
//  PersistentBudgetAlertState.swift
//  Veyra
//
//  Created by Icung on 16/07/26.
//

import Foundation
import SwiftData

@Model
final class PersistentBudgetAlertState {
    @Attribute(.unique) var budgetID: UUID
    var status: BudgetStatus

    init(budgetID: UUID, status: BudgetStatus) {
        self.budgetID = budgetID
        self.status = status
    }
}
