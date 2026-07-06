//
//  DashboardViewModelTests.swift
//  SpendMindTests
//
//  Created by Icung on 05/07/26.
//

import XCTest
@testable import SpendMind

@MainActor
final class DashboardViewModelTests: XCTestCase {
    
    func testDashboardViewModelInitialState() {
        let viewModel = DashboardViewModel()
        
        XCTAssertEqual(viewModel.todaySpending, 0)
        XCTAssertEqual(viewModel.weeklySpending, 0)
        XCTAssertEqual(viewModel.monthlySpending, 0)
        XCTAssertEqual(viewModel.totalIncome, 0)
        XCTAssertEqual(viewModel.totalExpense, 0)
        XCTAssertEqual(viewModel.balance, 0)
        XCTAssertEqual(viewModel.budgetLimit, 0)
        XCTAssertEqual(viewModel.budgetSpent, 0)
        XCTAssertTrue(viewModel.recentTransactions.isEmpty)
        XCTAssertTrue(viewModel.financialSuggestions.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testDashboardViewModelLoadsUSDDataCorrectly() async {
        let viewModel = DashboardViewModel()
        
        await viewModel.loadDashboardData(currency: .USD)
        
        XCTAssertEqual(viewModel.currencyCode, "USD")
        XCTAssertEqual(viewModel.todaySpending, 22.50)
        XCTAssertEqual(viewModel.weeklySpending, 145.80)
        XCTAssertEqual(viewModel.monthlySpending, 680.50)
        XCTAssertEqual(viewModel.totalIncome, 4500.00)
        XCTAssertEqual(viewModel.totalExpense, 1250.00)
        XCTAssertEqual(viewModel.balance, 3250.00)
        XCTAssertEqual(viewModel.budgetLimit, 1500.00)
        XCTAssertEqual(viewModel.budgetSpent, 680.50)
        
        XCTAssertEqual(viewModel.recentTransactions.count, 3)
        XCTAssertEqual(viewModel.recentTransactions[0].merchant, "Starbucks")
        XCTAssertEqual(viewModel.recentTransactions[0].amount, 6.50)
        
        XCTAssertEqual(viewModel.financialSuggestions.count, 4)
        XCTAssertTrue(viewModel.financialSuggestions.contains("Reduce dining expenses."))
    }
    
    func testDashboardViewModelLoadsIDRDataCorrectly() async {
        let viewModel = DashboardViewModel()
        
        await viewModel.loadDashboardData(currency: .IDR)
        
        XCTAssertEqual(viewModel.currencyCode, "IDR")
        XCTAssertEqual(viewModel.todaySpending, 125000)
        XCTAssertEqual(viewModel.weeklySpending, 850000)
        XCTAssertEqual(viewModel.monthlySpending, 3500000)
        XCTAssertEqual(viewModel.totalIncome, 15000000)
        XCTAssertEqual(viewModel.totalExpense, 4500000)
        XCTAssertEqual(viewModel.balance, 10500000)
        XCTAssertEqual(viewModel.budgetLimit, 8000000)
        XCTAssertEqual(viewModel.budgetSpent, 3500000)
        
        XCTAssertEqual(viewModel.recentTransactions.count, 3)
        XCTAssertEqual(viewModel.recentTransactions[0].merchant, "Starbucks")
        XCTAssertEqual(viewModel.recentTransactions[0].amount, 65000)
    }
}
