//
//  ExpenseListView.swift
//  SpendMind
//
//  Created by Icung on 10/07/26.
//

import SwiftUI
import SwiftData

struct ExpenseListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: ExpenseListViewModel
    @State private var showingAddExpense = false
    @State private var deletingExpense: Expense?
    let currency: CurrencyCode

    init(viewModel: ExpenseListViewModel, currency: CurrencyCode) {
        self._viewModel = State(initialValue: viewModel)
        self.currency = currency
    }

    var body: some View {
        expenseList
        .background(AppColor.background)
        .navigationTitle("Expenses")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .appFont(.footnote)
                    .foregroundStyle(AppColor.error)
                    .padding(AppSpacing.md)
                    .background(AppColor.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.medium))
                    .padding(AppSpacing.md)
                    .accessibilityLabel("Expense List Error: \(errorMessage)")
            }
        }
        .refreshable {
            viewModel.load()
        }
        .task {
            viewModel.load()
        }
    }

    private var expenseList: some View {
        List {
            if viewModel.isLoading && viewModel.sections.isEmpty {
                LoadingView(title: "Loading Expenses...")
                    .listRowBackground(Color.clear)
            } else if viewModel.sections.isEmpty {
                EmptyState(
                    title: "No expenses yet",
                    message: "Add your first expense and SpendMind will keep this month organized.",
                    actionTitle: "Add First Expense"
                ) {
                    showingAddExpense = true
                }
                .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.sections) { section in
                    Section(section.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())) {
                        ForEach(section.expenses) { expense in
                            NavigationLink {
                                ExpenseDetailView(expense: expense, currency: currency) {
                                    viewModel.load()
                                }
                            } label: {
                                expenseRow(expense)
                            }
                            .accessibilityLabel("Open Expense Detail")
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deletingExpense = expense
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .accessibilityLabel("Delete Expense")
                            }
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .sheet(isPresented: $showingAddExpense) {
            addExpenseSheet
        }
        .confirmationDialog(
            "Delete Expense?",
            isPresented: Binding(
                get: { deletingExpense != nil },
                set: { if !$0 { deletingExpense = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let deletingExpense {
                    viewModel.delete(deletingExpense)
                }
                deletingExpense = nil
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This expense will be removed from the list.")
        }
    }

    private func expenseRow(_ expense: Expense) -> some View {
        let categoryColor = expense.category.map { Color(hexString: $0.colorHex) } ?? AppColor.secondary

        // shared row gets primitive values, not the SwiftData model.
        return ExpenseRow(
            title: expense.merchant ?? expense.note,
            categoryName: expense.category?.name ?? "Uncategorized",
            categoryIcon: expense.category?.icon ?? "creditcard.fill",
            categoryColor: categoryColor,
            date: expense.expenseDate,
            amount: expense.amount,
            currencyCode: currency.rawValue
        )
    }
    
    
    private var addExpenseSheet: some View {
        let expenseRepository = SwiftDataExpenseRepository(context: modelContext)
        let categoryRepository = SwiftDataCategoryRepository(context: modelContext)
        
        return AddExpenseView(
            viewModel: AddExpenseViewModel(
                addExpenseUseCase: AddExpenseUseCase(repository: expenseRepository),
                categoryRepository: categoryRepository,
                currency: currency
            )
        ) {
            viewModel.load()
        }
    }

}

#Preview {
    NavigationStack {
        ExpenseListView(
            viewModel: ExpenseListViewModel(
                fetchExpensesUseCase: FetchExpensesUseCase(repository: ExpenseListPreviewRepository()),
                deleteExpenseUseCase: DeleteExpenseUseCase(repository: ExpenseListPreviewRepository())
            ),
            currency: .IDR
        )
    }
}

private final class ExpenseListPreviewRepository: ExpenseRepository {
    func createExpense(_ expense: Expense) throws { }
    func updateExpense(_ expense: Expense) throws { }
    func deleteExpense(id: UUID) throws { }
    func getExpense(id: UUID) throws -> Expense? { nil }
    func getExpenses() throws -> [Expense] { try getExpensesByMonth(.now) }

    func getExpensesByMonth(_ month: Date) throws -> [Expense] {
        let category = Category(name: "Food", icon: "fork.knife", colorHex: "#FF7444", isSystem: true)
        return [
            Expense(amount: 65_000, note: "Coffee", merchant: "Starbucks", category: category),
            Expense(amount: 120_000, note: "Lunch", merchant: "Warung", expenseDate: .now.addingTimeInterval(-86_400), category: category)
        ]
    }

    func getExpenses(from startDate: Date, to endDate: Date) throws -> [Expense] { try getExpensesByMonth(startDate) }
}
