//
//  Decimal+Extensions.swift
//  SpendMind
//
//  Created by Icung on 05/07/26.
//

import Foundation

extension Decimal {
    func formattedCurrency(code: String, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.locale = locale

        return formatter.string(from: self as NSDecimalNumber) ?? "\(self)"
    }
}
