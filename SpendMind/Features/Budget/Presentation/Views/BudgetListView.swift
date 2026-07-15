//
//  BudgetListView.swift
//  SpendMind
//
//  Created by Icung on 15/07/26.
//

import SwiftUI

struct BudgetListView: View {
    @State private var viewModel: BudgetListViewModel
    @State private var showingAddBudgetUnavailable = false

    init(viewModel: BudgetListViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                LoadingView(title: "Loading Budgets...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .empty:
                emptyState
            case .failed(let error):
                errorState(error)
            case .loaded(let budgets):
                budgetList(budgets)
            }
        }
        .background(AppColor.background)
        .navigationTitle("Budgets")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddBudgetUnavailable = true
                } label: {
                    Label("Add Budget", systemImage: "plus")
                }
                .accessibilityLabel("Add Budget")
            }
        }
        .alert("Add Budget", isPresented: $showingAddBudgetUnavailable) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Budget creation will be added in the next budgeting task.")
        }
        .task {
            if case .idle = viewModel.state {
                await viewModel.load()
            }
        }
    }

    private var emptyState: some View {
        EmptyState(
            title: "No budgets yet",
            message: "Create a monthly or category budget to track spending.",
            actionTitle: "Add Budget"
        ) {
            showingAddBudgetUnavailable = true
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorState(_ error: BudgetError) -> some View {
        EmptyState(
            title: "Could not load budgets",
            message: LocalizedStringKey(error.errorDescription ?? "Try again."),
            actionTitle: "Retry"
        ) {
            Task { await viewModel.retry() }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func budgetList(_ budgets: [BudgetProgress]) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.relaxed) {
                Text(viewModel.currentMonthLabel)
                    .appFont(.headline)
                    .foregroundStyle(AppColor.textSecondary)
                    .accessibilityLabel("Current month, \(viewModel.currentMonthLabel)")

                monthlyTotalCard

                if let totalBudget = viewModel.totalBudget {
                    BudgetProgressCard(progress: totalBudget, viewModel: viewModel, isTotal: true)
                }

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Category Budgets")
                        .appFont(.headline)
                        .foregroundStyle(AppColor.textPrimary)

                    ForEach(viewModel.categoryBudgets, id: \.budget.id) { progress in
                        BudgetProgressCard(progress: progress, viewModel: viewModel, isTotal: false)
                    }
                }
            }
            .padding(AppSpacing.md)
            .padding(.bottom, AppSpacing.xxl)
        }
        .refreshable {
            await viewModel.refresh()
        }
        .safeAreaInset(edge: .bottom) {
            PrimaryButton(title: "Add Budget") {
                showingAddBudgetUnavailable = true
            }
            .padding(AppSpacing.md)
            .background(AppColor.background.opacity(0.95))
        }
    }

    private var monthlyTotalCard: some View {
        Card {
            BudgetCardBody(
                title: "Total Monthly Budget",
                subtitle: "All active budgets",
                icon: "chart.pie.fill",
                iconColor: AppColor.primary,
                amount: viewModel.formattedTotalLimit,
                spent: viewModel.formattedTotalSpent,
                remaining: viewModel.formattedTotalRemaining,
                progress: viewModel.totalProgress,
                percentage: percentage(viewModel.totalProgress),
                status: totalStatusLabel,
                statusColor: totalStatusColor,
                isTotal: true
            )
        }
    }

    private var totalStatusLabel: String {
        if viewModel.totalSpentAmount > viewModel.totalLimitAmount { return "Exceeded" }
        if viewModel.totalProgress >= 0.8 { return "Warning" }
        return "Safe"
    }

    private var totalStatusColor: Color {
        if viewModel.totalSpentAmount > viewModel.totalLimitAmount { return AppColor.error }
        if viewModel.totalProgress >= 0.8 { return AppColor.warning }
        return AppColor.success
    }

    private func percentage(_ progress: Decimal) -> String {
        "\(Int(NSDecimalNumber(decimal: progress * 100).doubleValue.rounded()))%"
    }
}

private struct BudgetProgressCard: View {
    let progress: BudgetProgress
    let viewModel: BudgetListViewModel
    let isTotal: Bool

    var body: some View {
        Card {
            BudgetCardBody(
                title: progress.budget.name,
                subtitle: viewModel.typeLabel(for: progress),
                icon: viewModel.categoryIcon(for: progress),
                iconColor: isTotal ? AppColor.primary : Color(hexString: viewModel.categoryColorHex(for: progress)),
                amount: viewModel.formattedAmount(progress.budget.amount),
                spent: viewModel.formattedAmount(progress.spentAmount),
                remaining: viewModel.formattedAmount(progress.remainingAmount),
                progress: progress.progress,
                percentage: viewModel.percentageUsed(for: progress),
                status: viewModel.statusLabel(for: progress.status),
                statusColor: statusColor,
                isTotal: isTotal
            )
        }
    }

    private var statusColor: Color {
        switch progress.status {
        case .safe: AppColor.success
        case .warning: AppColor.warning
        case .exceeded: AppColor.error
        }
    }
}

private struct BudgetCardBody: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    let amount: String
    let spent: String
    let remaining: String
    let progress: Decimal
    let percentage: String
    let status: String
    let statusColor: Color
    let isTotal: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                Image(systemName: icon)
                    .foregroundStyle(AppColor.textInverse)
                    .frame(width: 40, height: 40)
                    .background(iconColor)
                    .clipShape(Circle())
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text(title)
                        .appFont(.headline)
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(subtitle)
                        .appFont(.caption)
                        .foregroundStyle(isTotal ? AppColor.primary : AppColor.textSecondary)
                }

                Spacer(minLength: AppSpacing.sm)

                Text(status)
                    .appFont(.caption)
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
                    .background(statusColor.opacity(0.12))
                    .clipShape(Capsule())
            }

            VStack(spacing: AppSpacing.sm) {
                amountRow(label: "Budget", value: amount)
                amountRow(label: "Spent", value: spent)
                amountRow(label: "Remaining", value: remaining)
            }

            ProgressView(value: min(max(progressValue, 0), 1))
                .tint(statusColor)
                .accessibilityLabel("Budget progress")
                .accessibilityValue("\(percentage) used")

            HStack {
                Text("\(percentage) used")
                    .appFont(.caption)
                    .foregroundStyle(statusColor)

                Spacer()

                Text(status)
                    .appFont(.caption)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
        .padding(isTotal ? AppSpacing.xs : AppSpacing.none)
        .background(isTotal ? AppColor.surfaceAlt.opacity(0.35) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: Radius.medium))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(subtitle), budget \(amount), spent \(spent), remaining \(remaining), \(percentage) used, status \(status)")
    }

    private var progressValue: Double {
        NSDecimalNumber(decimal: progress).doubleValue
    }

    private func amountRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .appFont(.caption)
                .foregroundStyle(AppColor.textSecondary)

            Spacer(minLength: AppSpacing.md)

            Text(value)
                .appFont(.bodyBold)
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.trailing)
                .minimumScaleFactor(0.8)
        }
    }
}
