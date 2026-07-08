//
//  PaymentMethod.swift
//  SpendMind
//
//  Created by Icung on 08/07/26.
//

enum PaymentMethod: String, Codable {
    case cash
    case debitCard
    case creditCard
    case eWallet
    case bankTransfer
    case crypto
    case other
}
