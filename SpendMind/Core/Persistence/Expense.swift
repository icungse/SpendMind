//
//  Expense.swift
//  SpendMind
//
//  Created by Icung on 08/07/26.
//

import Foundation
import SwiftData

@Model
final class Expense {
    @Attribute(.unique) var id: UUID
    var amount: Decimal
    var note: String
    var merchant: String?
    var createdAt: Date
    var updatedAt: Date
    var expenseDate: Date
    var paymentMethod: PaymentMethod
    var currency: CurrencyCode
    var locationName: String?
    var latitude: Double?
    var longitude: Double?
    var isDeleted: Bool
    
    init(
        id: UUID = UUID(),
        amount: Decimal,
        note: String = "",
        merchant: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        expenseDate: Date = .now,
        paymentMethod: PaymentMethod = .other,
        currency: CurrencyCode = .IDR,
        locationName: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        isDeleted: Bool = false
    ) {
        self.id = id
        self.amount = amount
        self.note = note
        self.merchant = merchant
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.expenseDate = expenseDate
        self.paymentMethod = paymentMethod
        self.currency = currency
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.isDeleted = isDeleted
    }
}
