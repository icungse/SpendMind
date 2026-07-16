//
//  BudgetFormViewModel.swift
//  SpendMind
//
//  Created by Icung on 15/07/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class BudgetFormViewModel {
    enum BudgetType: String, CaseIterable, Identifiable {
        case total
        case category

        var id: Self { self }

        var title: String {
            switch self {
            case .total: "Total Monthly Budget"
            case .category: "Category Budget"
            }
        }
    }

    var name = "Monthly Budget"
    var budgetType = BudgetType.total
    var selectedCategoryID: UUID?
    var amountText = ""
    var month = Date()
    var alertThresholdText = "0.8"
    private(set) var categories: [Category] = []
    private(set) var errorMessage: String?
    private(set) var isSaving = false

    nonisolated(unsafe) private let createBudgetUseCase: any CreateBudgetUseCase
    nonisolated(unsafe) private let updateBudgetUseCase: any UpdateBudgetUseCase
    private let categoryRepository: (any CategoryRepository)?
    private let budgetID: UUID?
    private let isActive: Bool
    private let locale: Locale

    init(
        createBudgetUseCase: any CreateBudgetUseCase,
        updateBudgetUseCase: any UpdateBudgetUseCase,
        categoryRepository: (any CategoryRepository)? = nil,
        budget: Budget? = nil,
        locale: Locale = .current
    ) {
        self.createBudgetUseCase = createBudgetUseCase
        self.updateBudgetUseCase = updateBudgetUseCase
        self.categoryRepository = categoryRepository
        self.budgetID = budget?.id
        self.isActive = budget?.isActive ?? true
        self.locale = locale

        if let budget {
            name = budget.name
            budgetType = budget.categoryID == nil ? .total : .category
            selectedCategoryID = budget.categoryID
            amountText = Self.formattedDecimal(budget.amount, locale: locale)
            month = budget.startDate
            alertThresholdText = Self.formattedDecimal(budget.alertThreshold, locale: locale)
        }
    }

    var isEditing: Bool {
        budgetID != nil
    }

    var canSave: Bool {
        nameError == nil && amountError == nil && categoryError == nil && alertThresholdError == nil && !isSaving
    }

    var formMessage: String? {
        errorMessage
    }

    var nameError: String? {
        name.trimmed.isEmpty ? "Budget name is required." : nil
    }

    var amountError: String? {
        guard !amountText.trimmed.isEmpty else { return "Amount is required." }
        guard let amount else { return "Amount must be a valid number." }
        guard amount > 0 else { return "Amount must be greater than zero." }
        return nil
    }

    var categoryError: String? {
        budgetType == .category && selectedCategoryID == nil ? "Category is required." : nil
    }

    var alertThresholdError: String? {
        guard !alertThresholdText.trimmed.isEmpty else { return "Alert threshold is required." }
        guard let alertThreshold else { return "Alert threshold must be a valid number." }
        guard alertThreshold >= 0, alertThreshold <= 1 else {
            return "Alert threshold must be between 0 and 1."
        }
        return nil
    }

    func updateAmountText(_ value: String) {
        amountText = sanitizedDecimalText(value)
    }

    func updateAlertThresholdText(_ value: String) {
        alertThresholdText = sanitizedDecimalText(value)
    }

    func loadCategories() {
        guard categories.isEmpty, let categoryRepository else { return }

        do {
            categories = try categoryRepository.getCategories()
            if budgetType == .category {
                selectedCategoryID = selectedCategoryID ?? categories.first?.id
            }
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
        }
    }

    func save() async -> Bool {
        guard canSave, let amount, let alertThreshold else {
            errorMessage = firstValidationMessage
            return false
        }

        isSaving = true
        defer { isSaving = false }

        do {
            let categoryID = budgetType == .category ? selectedCategoryID : nil

            // one form handles create/edit; split only when the flows actually diverge.
            if let budgetID {
                _ = try await updateBudgetUseCase.execute(
                    UpdateBudgetInput(
                        id: budgetID,
                        categoryID: categoryID,
                        name: name,
                        amount: amount,
                        month: month,
                        alertThreshold: alertThreshold,
                        isActive: isActive
                    )
                )
            } else {
                _ = try await createBudgetUseCase.execute(
                    CreateBudgetInput(
                        categoryID: categoryID,
                        name: name,
                        amount: amount,
                        month: month,
                        alertThreshold: alertThreshold
                    )
                )
            }

            errorMessage = nil
            return true
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
            return false
        }
    }

    private var amount: Decimal? {
        decimal(from: amountText)
    }

    private var alertThreshold: Decimal? {
        decimal(from: alertThresholdText)
    }

    private var firstValidationMessage: String? {
        nameError ?? amountError ?? categoryError ?? alertThresholdError
    }

    private func decimal(from text: String) -> Decimal? {
        let text = text.trimmed
        guard !text.isEmpty else { return nil }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        formatter.generatesDecimalNumbers = true

        if let number = formatter.number(from: text) {
            return number.decimalValue
        }

        let typedSeparators = text.filter { $0 == "." || $0 == "," }
        if typedSeparators.count == 1 {
            return Decimal(string: text.replacingOccurrences(of: ",", with: "."))
        }

        var normalized = text
        if let groupingSeparator = locale.groupingSeparator {
            normalized = normalized.replacingOccurrences(of: groupingSeparator, with: "")
        }
        if let decimalSeparator = locale.decimalSeparator {
            normalized = normalized.replacingOccurrences(of: decimalSeparator, with: ".")
        }

        return Decimal(string: normalized)
    }

    private func sanitizedDecimalText(_ value: String) -> String {
        let decimalSeparator = locale.decimalSeparator ?? "."
        let groupingSeparator = locale.groupingSeparator ?? ","
        let allowedSeparators = Set([decimalSeparator, groupingSeparator, ".", ","])

        return value.filter { character in
            character.isNumber || allowedSeparators.contains(String(character))
        }
    }

    private static func formattedDecimal(_ value: Decimal, locale: Locale) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = locale
        formatter.maximumFractionDigits = 6

        return formatter.string(from: value as NSDecimalNumber) ?? NSDecimalNumber(decimal: value).stringValue
    }
}
