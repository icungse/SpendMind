//
//  AddExpenseViewModelTests.swift
//  SpendMindTests
//
//  Created by Icung on 10/07/26.
//

import XCTest
@testable import SpendMind

@MainActor
final class AddExpenseViewModelTests: XCTestCase {
    func testSaveIsDisabledWhenInvalidAndShowsValidationMessage() {
        let viewModel = makeViewModel()
        viewModel.title = "Lunch"
        viewModel.amountText = "0"
        viewModel.loadCategories()

        XCTAssertFalse(viewModel.canSave)
        XCTAssertEqual(viewModel.formMessage, "Amount must be greater than zero.")
        XCTAssertFalse(viewModel.save())
        XCTAssertEqual(viewModel.formMessage, "Amount must be greater than zero.")
    }

    func testSaveValidExpense() {
        let expenseRepository = ViewModelExpenseRepository()
        let category = SpendMind.Category(name: "Food", icon: "fork.knife", colorHex: "#5B7FFF")
        let viewModel = makeViewModel(expenseRepository: expenseRepository, categories: [category], currency: .USD)

        viewModel.title = "Lunch"
        viewModel.amountText = "25"
        viewModel.note = "Team meal"
        viewModel.loadCategories()

        XCTAssertTrue(viewModel.canSave)
        XCTAssertTrue(viewModel.save())
        XCTAssertEqual(expenseRepository.expenses.count, 1)
        XCTAssertEqual(expenseRepository.expenses.first?.merchant, "Lunch")
        XCTAssertEqual(expenseRepository.expenses.first?.note, "Team meal")
        XCTAssertEqual(expenseRepository.expenses.first?.currency, .USD)
    }

    func testAmountInputRejectsNegativeValue() {
        let viewModel = makeViewModel()

        viewModel.updateAmountText("-25")

        XCTAssertEqual(viewModel.amountText, "25")
    }

    func testAmountFormatsSupportedCurrencies() {
        for currency in [CurrencyCode.IDR, .USD, .SGD, .MYR, .EUR, .GBP] {
            let expenseRepository = ViewModelExpenseRepository()
            let viewModel = makeViewModel(expenseRepository: expenseRepository, currency: currency)

            viewModel.title = "Lunch"
            viewModel.loadCategories()
            viewModel.updateAmountText("1234.56")
            viewModel.formatAmount()

            XCTAssertFalse(viewModel.amountText.isEmpty)
            XCTAssertNotEqual(viewModel.amountText, "1234.56")
            XCTAssertTrue(viewModel.save(), "Expected \(currency.rawValue) amount to save")
            XCTAssertEqual(expenseRepository.expenses.first?.amount, Decimal(string: "1234.56"))
            XCTAssertEqual(expenseRepository.expenses.first?.currency, currency)
        }
    }

    private func makeViewModel(
        expenseRepository: ViewModelExpenseRepository = ViewModelExpenseRepository(),
        categories: [SpendMind.Category] = [
            SpendMind.Category(name: "Food", icon: "fork.knife", colorHex: "#5B7FFF")
        ],
        currency: CurrencyCode = .IDR
    ) -> AddExpenseViewModel {
        AddExpenseViewModel(
            addExpenseUseCase: AddExpenseUseCase(repository: expenseRepository),
            categoryRepository: ViewModelCategoryRepository(categories: categories),
            currency: currency
        )
    }
}

private final class ViewModelExpenseRepository: ExpenseRepository {
    private(set) var expenses: [Expense] = []

    func createExpense(_ expense: Expense) throws {
        expenses.append(expense)
    }

    func updateExpense(_ expense: Expense) throws { }
    func deleteExpense(id: UUID) throws { }
    func getExpense(id: UUID) throws -> Expense? { expenses.first { $0.id == id } }
    func getExpenses() throws -> [Expense] { expenses }
    func getExpensesByMonth(_ month: Date) throws -> [Expense] { expenses }
    func getExpenses(from startDate: Date, to endDate: Date) throws -> [Expense] { expenses }
}

private final class ViewModelCategoryRepository: CategoryRepository {
    private let categories: [SpendMind.Category]

    init(categories: [SpendMind.Category]) {
        self.categories = categories
    }

    func getCategories() throws -> [SpendMind.Category] { categories }
    func getDefaultCategories() throws -> [SpendMind.Category] { categories.filter(\.isSystem) }
    func seedDefaultCategoriesIfNeeded() throws { }
}
