//
//  AddExpenseView.swift
//  Veyra
//
//  Created by Icung on 10/07/26.
//

import SwiftUI

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    @State private var viewModel: AddExpenseViewModel
    let onSaved: () -> Void

    private enum Field {
        case title
        case amount
        case note
    }

    init(viewModel: AddExpenseViewModel, onSaved: @escaping () -> Void = {}) {
        self._viewModel = State(initialValue: viewModel)
        self.onSaved = onSaved
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Form {
                Section("Expense") {
                    TextField("Title", text: $viewModel.title)
                        .textInputAutocapitalization(.words)
                        .focused($focusedField, equals: .title)
                        .accessibilityLabel("Expense Title")

                    TextField("Amount", text: Binding(
                        get: { viewModel.amountText },
                        set: { viewModel.updateAmountText($0) }
                    ))
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .amount)
                        .accessibilityLabel("Expense Amount in \(viewModel.currency.rawValue)")

                    if let budgetImpactMessage = viewModel.budgetImpactMessage {
                        if let status = viewModel.budgetImpactStatus, status != .safe {
                            BudgetWarningBanner(status: status, message: budgetImpactMessage)
                        } else {
                            Text(LocalizedStringKey(budgetImpactMessage))
                                .appFont(.footnote)
                                .foregroundStyle(AppColor.textSecondary)
                                .accessibilityLabel("Budget Impact: \(budgetImpactMessage)")
                        }
                    }
                }

                Section("Details") {
                    Picker("Category", selection: $viewModel.selectedCategoryID) {
                        Text("Select Category").tag(UUID?.none)

                        ForEach(viewModel.categories) { category in
                            categoryButton(category)
                                .tag(Optional(category.id))
                        }
                    }
                    .accessibilityLabel("Expense Category")

                    DatePicker("Date", selection: $viewModel.date, displayedComponents: .date)
                        .accessibilityLabel("Expense Date")

                    TextField("Note", text: $viewModel.note, axis: .vertical)
                        .lineLimit(3...5)
                        .focused($focusedField, equals: .note)
                        .accessibilityLabel("Expense Note")
                }

                if let message = viewModel.formMessage {
                    Text(message)
                        .appFont(.footnote)
                        .foregroundStyle(AppColor.error)
                        .accessibilityLabel("Validation Error: \(message)")
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(.hidden)
            .background(AppColor.background)
            .onChange(of: focusedField) { oldValue, newValue in
                if oldValue == .amount {
                    viewModel.formatAmount()
                }

                if newValue == .amount {
                    viewModel.unformatAmount()
                }
            }
            .navigationTitle(viewModel.isEditing ? "Edit Expense" : "Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityLabel(viewModel.isEditing ? "Cancel Edit Expense" : "Cancel Add Expense")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard viewModel.save() else { return }
                        onSaved()
                        dismiss()
                    }
                    .disabled(!viewModel.canSave)
                    .accessibilityLabel(viewModel.isEditing ? "Save Expense Changes" : "Save Expense")
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                    .accessibilityLabel("Dismiss Keyboard")
                }
            }
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(
                    title: viewModel.isEditing ? "Save Changes" : "Save Expense",
                    isLoading: viewModel.isSaving,
                    isDisabled: !viewModel.canSave
                ) {
                    guard viewModel.save() else { return }
                    onSaved()
                    dismiss()
                }
                .padding(AppSpacing.md)
                .background(AppColor.background)
            }
            .task {
                viewModel.loadCategories()
            }
        }
    }

    private func categoryButton(_ category: Category) -> some View {
        let isSelected = viewModel.selectedCategoryID == category.id

        return Button {
            viewModel.selectedCategoryID = category.id
        } label: {
            CategoryPickerRow(category: category, isSelected: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Category \(category.name)")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    AddExpenseView(
        viewModel: AddExpenseViewModel(
            addExpenseUseCase: AddExpenseUseCase(repository: AddExpensePreviewExpenseRepository()),
            categoryRepository: AddExpensePreviewCategoryRepository()
        )
    )
}

private final class AddExpensePreviewExpenseRepository: ExpenseRepository {
    func createExpense(_ expense: Expense) throws { }
    func updateExpense(_ expense: Expense) throws { }
    func deleteExpense(id: UUID) throws { }
    func getExpense(id: UUID) throws -> Expense? { nil }
    func getExpenses() throws -> [Expense] { [] }
    func getExpensesByMonth(_ month: Date) throws -> [Expense] { [] }
    func getExpenses(from startDate: Date, to endDate: Date) throws -> [Expense] { [] }
}

private final class AddExpensePreviewCategoryRepository: CategoryRepository {
    func getCategories() throws -> [Category] {
        [Category(name: "Food", icon: "fork.knife", colorHex: "#5B7FFF", isSystem: true)]
    }

    func getDefaultCategories() throws -> [Category] { try getCategories() }
    func seedDefaultCategoriesIfNeeded() throws { }
}
