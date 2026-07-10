//
//  AddExpenseViewModel.swift
//  SpendMind
//
//  Created by Icung on 10/07/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class AddExpenseViewModel {
    var title = ""
    var amountText = ""
    var selectedCategoryID: UUID?
    var date = Date()
    var note = ""
    private(set) var categories: [Category] = []
    private(set) var errorMessage: String?
    private(set) var isSaving = false

    let currency: CurrencyCode
    private let addExpenseUseCase: AddExpenseUseCase
    private let categoryRepository: any CategoryRepository

    init(
        addExpenseUseCase: AddExpenseUseCase,
        categoryRepository: any CategoryRepository,
        currency: CurrencyCode = .IDR
    ) {
        self.addExpenseUseCase = addExpenseUseCase
        self.categoryRepository = categoryRepository
        self.currency = currency
    }

    var canSave: Bool {
        validationMessage == nil && !isSaving
    }

    var formMessage: String? {
        errorMessage ?? (hasInput ? validationMessage : nil)
    }

    func loadCategories() {
        guard categories.isEmpty else { return }

        do {
            categories = try categoryRepository.getCategories()
            selectedCategoryID = selectedCategoryID ?? categories.first?.id
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
        }
    }

    func save() -> Bool {
        guard validationMessage == nil, let amount, let category else {
            errorMessage = validationMessage
            return false
        }

        isSaving = true
        defer { isSaving = false }

        do {
            try addExpenseUseCase.execute(
                title: title,
                amount: amount,
                category: category,
                date: date,
                note: note,
                currency: currency
            )
            errorMessage = nil
            return true
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
            return false
        }
    }

    func updateAmountText(_ value: String) {
        amountText = sanitizedAmountText(from: value)
    }

    func formatAmount() {
        guard let amount else { return }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.rawValue
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        amountText = formatter.string(from: amount as NSDecimalNumber) ?? amount.formattedCurrency(code: currency.rawValue)
    }

    func unformatAmount() {
        guard let amount else {
            updateAmountText(amountText)
            return
        }

        amountText = NSDecimalNumber(decimal: amount).stringValue
    }

    private var amount: Decimal? {
        Decimal(string: normalizedAmountText(from: amountText))
    }

    private var category: Category? {
        categories.first { $0.id == selectedCategoryID }
    }

    private var validationMessage: String? {
        guard !title.trimmed.isEmpty else { return "Title is required." }
        guard title.trimmed.count <= 100 else { return "Title must be 100 characters or less." }
        guard !amountText.trimmed.isEmpty else { return "Amount is required." }
        guard let amount else { return "Amount must be a valid number." }
        guard amount > 0 else { return "Amount must be greater than zero." }
        guard amount <= 999_999_999 else { return "Amount must be 999,999,999 or less." }
        guard category != nil else { return "Category is required." }
        guard note.trimmed.count <= 500 else { return "Note must be 500 characters or less." }
        return nil
    }

    private var hasInput: Bool {
        !title.trimmed.isEmpty || !amountText.trimmed.isEmpty || !note.trimmed.isEmpty
    }

    private func sanitizedAmountText(from value: String) -> String {
        var result = ""
        var hasDecimalSeparator = false

        for character in value where character.isNumber || character == "." || character == "," {
            if character == "." || character == "," {
                guard !hasDecimalSeparator else { continue }
                hasDecimalSeparator = true
                result.append(".")
            } else {
                result.append(character)
            }
        }

        return result
    }

    private func normalizedAmountText(from value: String) -> String {
        let value = value.trimmed.filter { $0.isNumber || $0 == "." || $0 == "," }

        if value.contains(".") {
            return value.replacingOccurrences(of: ",", with: "")
        }

        return value.replacingOccurrences(of: ",", with: ".")
    }
}
