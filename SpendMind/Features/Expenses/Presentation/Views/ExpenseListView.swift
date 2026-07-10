//
//  ExpenseListView.swift
//  SpendMind
//
//  Created by Icung on 10/07/26.
//

import SwiftUI

struct ExpenseListView: View {
    @State private var viewModel: ExpenseListViewModel
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
                    title: "No Expenses This Month",
                    message: "Add an expense to see it grouped by date."
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.sections) { section in
                    Section(section.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())) {
                        ForEach(section.expenses) { expense in
                            expenseRow(expense)
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
    }

    private func expenseRow(_ expense: Expense) -> some View {
        let categoryColor = expense.category.map { Color(hexString: $0.colorHex) } ?? AppColor.secondary

        return HStack(spacing: AppSpacing.md) {
            Image(systemName: expense.category?.icon ?? "creditcard.fill")
                .foregroundStyle(AppColor.textInverse)
                .frame(width: 36, height: 36)
                .background(categoryColor)
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(expense.merchant ?? expense.note)
                    .appFont(.bodyBold)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)

                Text(expense.category?.name ?? "Uncategorized")
                    .appFont(.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }

            Spacer()

            Text(expense.amount.formattedCurrency(code: currency.rawValue))
                .appFont(.headline)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)
        }
        .padding(.vertical, AppSpacing.xs)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        ExpenseListView(
            viewModel: ExpenseListViewModel(
                fetchExpensesUseCase: FetchExpensesUseCase(repository: ExpenseListPreviewRepository())
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
