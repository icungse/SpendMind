//
//  ExpenseDetailView.swift
//  SpendMind
//
//  Created by Icung on 11/07/26.
//

import SwiftUI

struct ExpenseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showingEditExpense = false

    let expense: Expense
    let currency: CurrencyCode
    let onSaved: () -> Void

    init(expense: Expense, currency: CurrencyCode, onSaved: @escaping () -> Void = {}) {
        self.expense = expense
        self.currency = currency
        self.onSaved = onSaved
    }

    var body: some View {
        Form {
            Section("Expense") {
                detailRow("Title", expense.merchant ?? expense.note)
                detailRow("Amount", expense.amount.formattedCurrency(code: currency.rawValue))
                detailRow("Category", expense.category?.name ?? "Uncategorized")
                detailRow("Date", expense.expenseDate.formatted(date: .abbreviated, time: .omitted))
            }

            Section("Note") {
                Text(expense.note.isEmpty ? "No note" : expense.note)
                    .foregroundStyle(expense.note.isEmpty ? AppColor.textSecondary : AppColor.textPrimary)
            }

            Section("Metadata") {
                detailRow("Created date", expense.createdAt.formatted(date: .abbreviated, time: .shortened))
                detailRow("Updated date", expense.updatedAt.formatted(date: .abbreviated, time: .shortened))
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppColor.background)
        .navigationTitle("Expense Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showingEditExpense = true
                }
                .accessibilityLabel("Edit Expense")
            }
        }
        .sheet(isPresented: $showingEditExpense) {
            editExpenseSheet
        }
    }

    private func detailRow(_ title: LocalizedStringKey, _ value: String) -> some View {
        LabeledContent(title) {
            Text(value)
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }

    private var editExpenseSheet: some View {
        let expenseRepository = SwiftDataExpenseRepository(context: modelContext)
        let categoryRepository = SwiftDataCategoryRepository(context: modelContext)
        let budgetRepository = SwiftDataBudgetRepository(modelContainer: modelContext.container)

        // reuse add/edit form; split only when detail edit needs a different flow.
        return AddExpenseView(
            viewModel: AddExpenseViewModel(
                addExpenseUseCase: AddExpenseUseCase(repository: expenseRepository),
                categoryRepository: categoryRepository,
                currency: currency,
                expense: expense,
                updateExpenseUseCase: UpdateExpenseUseCase(repository: expenseRepository),
                previewBudgetImpactUseCase: DefaultPreviewBudgetImpactUseCase(
                    budgetRepository: budgetRepository,
                    expenseRepository: expenseRepository
                )
            )
        ) {
            onSaved()
        }
    }
}

#Preview {
    NavigationStack {
        let category = Category(name: "Food", icon: "fork.knife", colorHex: "#FF7444", isSystem: true)
        ExpenseDetailView(
            expense: Expense(amount: 65_000, note: "Coffee", merchant: "Starbucks", category: category),
            currency: .IDR
        )
    }
}
