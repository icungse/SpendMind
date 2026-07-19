//
//  BudgetFormViewModel.swift
//  Veyra
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
            case .total: String(localized: "budget.total_monthly")
            case .category: String(localized: "budget.category")
            }
        }
    }

    var name = String(localized: "budget.monthly")
    var budgetType = BudgetType.total
    var selectedCategoryID: UUID?
    var amountText = ""
    var month: Date
    var alertThresholdPercent = 80
    private(set) var categories: [Category] = []
    private(set) var budgetedCategoryIDs: Set<UUID> = []
    private(set) var errorMessage: String?
    private(set) var isSaving = false

    nonisolated(unsafe) private let createBudgetUseCase: any CreateBudgetUseCase
    nonisolated(unsafe) private let updateBudgetUseCase: any UpdateBudgetUseCase
    nonisolated(unsafe) private let deleteBudgetUseCase: any DeleteBudgetUseCase
    nonisolated(unsafe) private let budgetRepository: any BudgetRepository
    private let categoryRepository: (any CategoryRepository)?
    private let budgetID: UUID?
    private let isActive: Bool
    let calendar: Calendar
    private let locale: Locale
    private let originalMonth: Date?
    let alertThresholdOptions = [50, 75, 80, 90]

    init(
        createBudgetUseCase: any CreateBudgetUseCase,
        updateBudgetUseCase: any UpdateBudgetUseCase,
        deleteBudgetUseCase: any DeleteBudgetUseCase,
        budgetRepository: any BudgetRepository,
        categoryRepository: (any CategoryRepository)? = nil,
        budget: Budget? = nil,
        calendar: Calendar = .current,
        locale: Locale = .current
    ) {
        self.createBudgetUseCase = createBudgetUseCase
        self.updateBudgetUseCase = updateBudgetUseCase
        self.deleteBudgetUseCase = deleteBudgetUseCase
        self.budgetRepository = budgetRepository
        self.categoryRepository = categoryRepository
        self.budgetID = budget?.id
        self.isActive = budget?.isActive ?? true
        self.calendar = calendar
        self.locale = locale
        self.originalMonth = budget?.startDate
        self.month = Self.startOfMonth(for: budget?.startDate ?? .now, calendar: calendar)

        if let budget {
            name = budget.name
            budgetType = budget.categoryID == nil ? .total : .category
            selectedCategoryID = budget.categoryID
            amountText = Self.formattedDecimal(budget.amount, locale: locale)
            alertThresholdPercent = Self.percent(from: budget.alertThreshold)
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

    var monthPickerSelectedDate: Date? {
        isEditing ? originalMonth : nil
    }

    var monthPickerLocale: Locale {
        locale
    }

    var nameError: String? {
        guard name.trimmed.isEmpty else { return nil }
        return String(localized: "budget.validation.name_required")
    }

    var amountError: String? {
        guard !amountText.trimmed.isEmpty else {
            return String(localized: "budget.validation.amount_required")
        }
        guard let amount else {
            return String(localized: "budget.validation.amount_valid_number")
        }
        guard amount > 0 else {
            return String(localized: "budget.validation.amount_greater_than_zero_short")
        }
        return nil
    }

    var categoryError: String? {
        guard budgetType == .category else { return nil }
        guard let selectedCategoryID else {
            return String(localized: "budget.validation.category_required")
        }
        guard !isCategoryDisabled(selectedCategoryID) else {
            return String(localized: "budget.validation.category_active_duplicate")
        }

        return nil
    }

    var alertThresholdError: String? {
        guard !alertThresholdOptions.contains(alertThresholdPercent) else { return nil }
        return String(localized: "budget.validation.alert_threshold_valid")
    }

    func updateAmountText(_ value: String) {
        amountText = sanitizedDecimalText(value)
    }

    func alertThresholdLabel(_ percent: Int) -> String {
        String.localizedStringWithFormat(String(localized: "budget.alert_threshold.label"), percent)
    }

    func loadCategories() async {
        guard let categoryRepository else { return }

        do {
            let allCategories = try categoryRepository.getCategories()
            categories = allCategories.filter { $0.isArchived != true || $0.id == selectedCategoryID }
            budgetedCategoryIDs = Set(try await budgetRepository.activeBudgets(for: month).compactMap { budget in
                guard budget.id != budgetID else { return nil }
                return budget.categoryID
            })

            if budgetType == .category {
                selectedCategoryID = selectedCategoryID ?? categories.first { !isCategoryDisabled($0.id) }?.id
            }
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
        }
    }

    func isCategoryDisabled(_ categoryID: UUID) -> Bool {
        budgetedCategoryIDs.contains(categoryID)
    }

    func categorySubtitle(for category: Category) -> String? {
        if isCategoryDisabled(category.id) { return String(localized: "budget.already_budgeted") }
        if category.isArchived == true { return "Archived" }
        return nil
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

    func delete(isConfirmed: Bool) async -> Bool {
        guard let budgetID else {
            errorMessage = String(localized: "budget.validation.not_found")
            return false
        }

        isSaving = true
        defer { isSaving = false }

        do {
            try await deleteBudgetUseCase.execute(id: budgetID, isConfirmed: isConfirmed)
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
        Decimal(alertThresholdPercent) / 100
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

    private static func percent(from threshold: Decimal) -> Int {
        let percent = NSDecimalNumber(decimal: threshold * 100).intValue
        return [50, 75, 80, 90].contains(percent) ? percent : 80
    }

    private static func startOfMonth(for date: Date, calendar: Calendar) -> Date {
        calendar.dateInterval(of: .month, for: date)?.start ?? calendar.startOfDay(for: date)
    }
}
