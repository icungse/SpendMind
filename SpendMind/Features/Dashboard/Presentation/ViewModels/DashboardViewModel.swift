//
//  DashboardViewModel.swift
//  SpendMind
//
//  Created by Icung on 05/07/26.
//

import Foundation
import Observation

struct DashboardTransaction: Identifiable, Hashable {
    let id: UUID
    let merchant: String
    let amount: Decimal
    let categoryName: String
    let categoryIcon: String
    let isExpense: Bool
    let date: Date
}

@Observable
@MainActor
final class DashboardViewModel {
    private(set) var todaySpending: Decimal = 0
    private(set) var weeklySpending: Decimal = 0
    private(set) var monthlySpending: Decimal = 0
    private(set) var totalIncome: Decimal = 0
    private(set) var totalExpense: Decimal = 0
    private(set) var balance: Decimal = 0
    private(set) var budgetLimit: Decimal = 0
    private(set) var budgetSpent: Decimal = 0
    private(set) var recentTransactions: [DashboardTransaction] = []
    private(set) var financialSuggestions: [String] = []
    private(set) var currencyCode: String = "IDR"
    private(set) var isLoading: Bool = false

    private let dateService: any DateServiceProtocol

    init(dateService: any DateServiceProtocol = DateService()) {
        self.dateService = dateService
    }

    func loadDashboardData(currency: CurrencyCode) async {
        isLoading = true
        // temporary delay to simulate on-device database load
        try? await Task.sleep(nanoseconds: 200_000_000)

        self.currencyCode = currency.rawValue

        if currency == .USD {
            todaySpending = 22.50
            weeklySpending = 145.80
            monthlySpending = 680.50
            totalIncome = 4500.00
            totalExpense = 1250.00
            balance = 3250.00
            budgetLimit = 1500.00
            budgetSpent = 680.50
        } else {
            todaySpending = 125000
            weeklySpending = 850000
            monthlySpending = 3500000
            totalIncome = 15000000
            totalExpense = 4500000
            balance = 10500000
            budgetLimit = 8000000
            budgetSpent = 3500000
        }

        let now = Date()
        recentTransactions = [
            DashboardTransaction(
                id: UUID(),
                merchant: "Starbucks",
                amount: currency == .USD ? 6.50 : 65000,
                categoryName: "Food",
                categoryIcon: "cup.and.saucer.fill",
                isExpense: true,
                date: now
            ),
            DashboardTransaction(
                id: UUID(),
                merchant: "Monthly Salary",
                amount: currency == .USD ? 4500.00 : 15000000,
                categoryName: "Salary",
                categoryIcon: "banknote.fill",
                isExpense: false,
                date: dateService.startOfDay(for: now).addingTimeInterval(-86400)
            ),
            DashboardTransaction(
                id: UUID(),
                merchant: "Uber Ride",
                amount: currency == .USD ? 22.00 : 150000,
                categoryName: "Transportation",
                categoryIcon: "car.fill",
                isExpense: true,
                date: dateService.startOfDay(for: now).addingTimeInterval(-172800)
            )
        ]

        financialSuggestions = [
            "Reduce dining expenses.",
            "Coffee purchases have increased.",
            "Shopping remains within healthy limits.",
            "Bills account for 42% of monthly income."
        ]

        isLoading = false
    }
}
