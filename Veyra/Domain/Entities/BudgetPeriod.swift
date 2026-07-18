//
//  BudgetPeriod.swift
//  Veyra
//
//  Created by Icung on 13/07/26.
//

import Foundation

enum BudgetPeriod: String, Codable, CaseIterable, Equatable, Sendable {
    case monthly

    var localizedTitle: LocalizedStringResource {
        // v0.3.0 only supports monthly; add cases here when product actually supports them.
        "budget.period.monthly"
    }
}
