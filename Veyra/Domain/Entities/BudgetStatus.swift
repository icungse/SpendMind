//
//  BudgetStatus.swift
//  Veyra
//
//  Created by Icung on 13/07/26.
//

enum BudgetStatus: String, Codable, Equatable, Sendable {
    case safe
    case warning
    case exceeded
}
