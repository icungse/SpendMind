//
//  CreateBudgetViewModel.swift
//  SpendMind
//
//  Created by Icung on 15/07/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class CreateBudgetViewModel {
    var name = "Monthly Budget"
    var amountText = ""
    var month = Date()
    private(set) var errorMessage: String?
    private(set) var isSaving = false

    nonisolated(unsafe) private let createBudgetUseCase: any CreateBudgetUseCase

    init(createBudgetUseCase: any CreateBudgetUseCase) {
        self.createBudgetUseCase = createBudgetUseCase
    }

    var canSave: Bool {
        validationMessage == nil && !isSaving
    }

    var formMessage: String? {
        errorMessage ?? (hasInput ? validationMessage : nil)
    }

    func updateAmountText(_ value: String) {
        amountText = value.filter { $0.isNumber || $0 == "." || $0 == "," }
    }

    func save() async -> Bool {
        guard validationMessage == nil, let amount else {
            errorMessage = validationMessage
            return false
        }

        isSaving = true
        defer { isSaving = false }

        do {
            _ = try await createBudgetUseCase.execute(
                CreateBudgetInput(
                    categoryID: nil,
                    name: name,
                    amount: amount,
                    month: month,
                    // ponytail: first budget flow creates total monthly budgets; expose category/threshold when product asks.
                    alertThreshold: 0.8
                )
            )
            errorMessage = nil
            return true
        } catch {
            errorMessage = AppError.wrap(error).errorDescription
            return false
        }
    }

    private var amount: Decimal? {
        Decimal(string: amountText.replacingOccurrences(of: ",", with: "."))
    }

    private var validationMessage: String? {
        guard !name.trimmed.isEmpty else { return "Budget name is required." }
        guard !amountText.trimmed.isEmpty else { return "Amount is required." }
        guard let amount else { return "Amount must be a valid number." }
        guard amount > 0 else { return "Amount must be greater than zero." }
        return nil
    }

    private var hasInput: Bool {
        !name.trimmed.isEmpty || !amountText.trimmed.isEmpty
    }
}
