//
//  ExpenseTests.swift
//  SpendMindTests
//
//  Created by Icung on 08/07/26.
//

import SwiftData
import XCTest
@testable import SpendMind

@MainActor
final class ExpenseTests: XCTestCase {
    func testExpenseCreateReadUpdateDelete() throws {
        let container = try ModelContainer(
            for: SpendMind.Category.self, Expense.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let repository = SwiftDataRepository<Expense>(context: container.mainContext)
        let originalAmount = try XCTUnwrap(Decimal(string: "12500.75"))
        let updatedAmount = try XCTUnwrap(Decimal(string: "15000.25"))
        let expense = Expense(amount: originalAmount, note: "Coffee")

        try repository.insert(expense)
        XCTAssertEqual(try repository.fetchAll().map(\.amount), [originalAmount])

        expense.amount = updatedAmount
        expense.note = "Coffee and snack"
        try repository.save()

        let updatedExpense = try XCTUnwrap(repository.fetchAll().first)
        XCTAssertEqual(updatedExpense.amount, updatedAmount)
        XCTAssertEqual(updatedExpense.note, "Coffee and snack")

        try repository.delete(expense)
        XCTAssertTrue(try repository.fetchAll().isEmpty)
    }
}
