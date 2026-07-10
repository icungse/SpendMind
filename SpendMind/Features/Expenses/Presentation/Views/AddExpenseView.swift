//
//  AddExpenseView.swift
//  SpendMind
//
//  Created by Icung on 10/07/26.
//

import SwiftUI

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFieldFocused: Bool
    @State private var viewModel: AddExpenseViewModel
    let onSaved: () -> Void

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
                        .focused($isFieldFocused)
                        .accessibilityLabel("Expense Title")

                    TextField("Amount", text: $viewModel.amountText)
                        .keyboardType(.decimalPad)
                        .focused($isFieldFocused)
                        .accessibilityLabel("Expense Amount")
                }

                Section("Details") {
                    Picker("Category", selection: $viewModel.selectedCategoryID) {
                        Text("Select Category").tag(UUID?.none)

                        ForEach(viewModel.categories) { category in
                            Text(category.name).tag(Optional(category.id))
                        }
                    }
                    .accessibilityLabel("Expense Category")

                    DatePicker("Date", selection: $viewModel.date, displayedComponents: .date)
                        .accessibilityLabel("Expense Date")

                    TextField("Note", text: $viewModel.note, axis: .vertical)
                        .lineLimit(3...5)
                        .focused($isFieldFocused)
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
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityLabel("Cancel Add Expense")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard viewModel.save() else { return }
                        onSaved()
                        dismiss()
                    }
                    .disabled(!viewModel.canSave)
                    .accessibilityLabel("Save Expense")
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isFieldFocused = false
                    }
                    .accessibilityLabel("Dismiss Keyboard")
                }
            }
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(
                    title: "Save Expense",
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
