//
//  DashboardView.swift
//  Veyra
//
//  Created by Icung on 05/07/26.
//

import SwiftData
import SwiftUI

struct DashboardView: View {
    @Environment(\.dependencies) private var dependencies
    @Environment(\.modelContext) private var modelContext
    @Binding var settings: AppSettings
    @State private var viewModel: DashboardViewModel
    @State private var showingQuickAdd = false

    init(viewModel: DashboardViewModel, settings: Binding<AppSettings>) {
        self._viewModel = State(initialValue: viewModel)
        self._settings = settings
    }

    var body: some View {
        ZStack {
            AppColor.background
                .ignoresSafeArea()

            if viewModel.isLoading {
                LoadingView(title: "Loading Dashboard...")
            } else {
                ScrollView {
                    VStack(spacing: AppSpacing.relaxed) {
                        headerView

                        overviewCard

                        budgetCard

                        categorySpendingSection

                        budgetInsightsSection

                        recentTransactionsSection

                        Spacer()
                    }
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.bottom, AppSpacing.xxl)
                }
                .refreshable {
                    await viewModel.loadDashboardData(currency: settings.currency)
                }
            }

            quickAddButton
        }
        .navigationTitle(AppConstants.appName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: toggleBudgetNotifications) {
                        Label(
                            "budget.notifications",
                            systemImage: settings.isBudgetNotificationsEnabled ? "checkmark" : ""
                        )
                    }

                    Button(action: { settings.currency = .USD }) {
                        Label("USD ($)", systemImage: settings.currency == .USD ? "checkmark" : "")
                    }
                    Button(action: { settings.currency = .IDR }) {
                        Label("IDR (Rp)", systemImage: settings.currency == .IDR ? "checkmark" : "")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(AppColor.primary)
                        .accessibilityLabel("Settings Menu")
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadDashboardData(currency: settings.currency)
            }
        }
        .onChange(of: settings.currency) { _, newCurrency in
            Task {
                await viewModel.loadDashboardData(currency: newCurrency)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: AppConstants.Notifications.expensesDidChange)) { notification in
            guard viewModel.shouldRefreshForExpenseChange(notification.userInfo) else { return }
            Task {
                await viewModel.loadDashboardData(currency: settings.currency)
            }
        }
        .sheet(isPresented: $showingQuickAdd) {
            quickAddSheet
        }
    }

    private func toggleBudgetNotifications() {
        let requestedValue = !settings.isBudgetNotificationsEnabled

        Task {
            let enabled = await dependencies.budgetNotificationService.setEnabled(requestedValue)
            settings.isBudgetNotificationsEnabled = enabled
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("Welcome Back")
                    .appFont(.caption)
                    .foregroundStyle(AppColor.textSecondary)

                Text("Your Financial Mind")
                    .appFont(.title2)
                    .foregroundStyle(AppColor.textPrimary)
            }
            Spacer()

            HStack(spacing: AppSpacing.xs) {
                Circle()
                    .fill(AppColor.success)
                    .frame(width: 8, height: 8)
                Text("Local AI")
                    .appFont(.caption2)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .background(AppColor.surfaceAlt)
            .clipShape(Capsule())
        }
        .padding(.top, AppSpacing.sm)
    }

    private var overviewCard: some View {
        Card {
            VStack(spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("Total Balance")
                        .appFont(.caption)
                        .foregroundStyle(AppColor.textSecondary)

                    Text(viewModel.balance.formattedCurrency(code: viewModel.currencyCode))
                        .appFont(.largeTitle)
                        .foregroundStyle(AppColor.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .background(AppColor.border)

                HStack(spacing: AppSpacing.md) {
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Label("Income", systemImage: "arrow.down.left.circle.fill")
                            .appFont(.caption2)
                            .foregroundStyle(AppColor.success)

                        Text(viewModel.totalIncome.formattedCurrency(code: viewModel.currencyCode))
                            .appFont(.headline)
                            .foregroundStyle(AppColor.textPrimary)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Divider()
                        .background(AppColor.border)
                        .frame(height: 32)

                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Label("Total Monthly Expense", systemImage: "arrow.up.right.circle.fill")
                            .appFont(.caption2)
                            .foregroundStyle(AppColor.secondary)

                        Text(viewModel.totalExpense.formattedCurrency(code: viewModel.currencyCode))
                            .appFont(.headline)
                            .foregroundStyle(AppColor.textPrimary)
                            .minimumScaleFactor(0.8)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var budgetCard: some View {
        NavigationLink(value: AppRoute.budgets) {
            Card {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    HStack(alignment: .top) {
                        SectionHeader(
                            title: "budget.summary",
                            subtitle: LocalizedStringKey(
                                viewModel.hasBudgets ? "budget.summary.current_month" : "budget.summary.no_budgets_yet"
                            )
                        )

                        Spacer()

                        Image(systemName: "chevron.right")
                            .appFont(.caption)
                            .foregroundStyle(AppColor.textSecondary)
                            .accessibilityHidden(true)
                    }

                    if viewModel.hasBudgets {
                        budgetSummaryContent
                    } else {
                        Text("budget.empty.summary.message")
                            .appFont(.footnote)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(budgetSummaryAccessibilityLabel)
        .accessibilityHint("budget.accessibility.summary.opens_list")
    }

    private var budgetSummaryContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            let progress = CGFloat(NSDecimalNumber(decimal: viewModel.budgetProgress).doubleValue)

            VStack(spacing: AppSpacing.xs) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(AppColor.surfaceAlt)
                            .frame(height: 8)

                        Capsule()
                            .fill(viewModel.budgetStatus == .exceeded ? AppColor.error : AppColor.secondary)
                            .frame(width: geo.size.width * min(progress, 1.0), height: 8)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text(String.localizedStringWithFormat(
                        String(localized: "budget.spent.value"),
                        viewModel.budgetProgressPercentText
                    ))
                        .appFont(.caption2)
                        .foregroundStyle(viewModel.budgetStatus == .safe ? AppColor.textSecondary : AppColor.error)

                    Spacer()

                    Text(String.localizedStringWithFormat(
                        String(localized: "budget.remaining.left"),
                        viewModel.budgetRemaining.formattedCurrency(code: viewModel.currencyCode)
                    ))
                        .appFont(.caption2)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }

            VStack(spacing: AppSpacing.xs) {
                budgetSummaryRow("budget.summary.total_budget", viewModel.budgetLimit.formattedCurrency(code: viewModel.currencyCode))
                budgetSummaryRow("budget.summary.total_spent", viewModel.budgetSpent.formattedCurrency(code: viewModel.currencyCode))
                budgetSummaryRow("budget.remaining", viewModel.budgetRemaining.formattedCurrency(code: viewModel.currencyCode))
                budgetSummaryRow("budget.warning", "\(viewModel.budgetWarningCount)")
                budgetSummaryRow("budget.exceeded", "\(viewModel.budgetExceededCount)")
            }

            if let budgetWarningMessage = viewModel.budgetWarningMessage {
                BudgetWarningBanner(status: viewModel.budgetStatus, message: budgetWarningMessage)
            }
        }
    }

    private func budgetSummaryRow(_ title: LocalizedStringKey, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .appFont(.footnote)
                .foregroundStyle(AppColor.textSecondary)

            Spacer(minLength: AppSpacing.md)

            Text(value)
                .appFont(.footnote)
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }

    private var budgetSummaryAccessibilityLabel: String {
        guard viewModel.hasBudgets else {
            return String(localized: "budget.accessibility.summary.empty")
        }

        return String.localizedStringWithFormat(
            String(localized: "budget.accessibility.summary.loaded"),
            viewModel.budgetLimit.formattedCurrency(code: viewModel.currencyCode),
            viewModel.budgetSpent.formattedCurrency(code: viewModel.currencyCode),
            viewModel.budgetRemaining.formattedCurrency(code: viewModel.currencyCode),
            viewModel.budgetProgressPercentText,
            budgetWarningCountText,
            budgetExceededCountText
        )
    }

    private var budgetWarningCountText: String {
        String.localizedStringWithFormat(
            String(localized: "budget.summary.warning_count"),
            viewModel.budgetWarningCount
        )
    }

    private var budgetExceededCountText: String {
        String.localizedStringWithFormat(
            String(localized: "budget.summary.exceeded_count"),
            viewModel.budgetExceededCount
        )
    }

    private var categorySpendingSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            SectionHeader(title: "Category Spending")

            if viewModel.categorySpendings.isEmpty {
                EmptyState(
                    title: "No category spending yet",
                    message: "Add expenses this month to see category totals."
                )
            } else {
                VStack(spacing: AppSpacing.none) {
                    ForEach(viewModel.categorySpendings) { category in
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: category.icon)
                                .foregroundStyle(AppColor.textInverse)
                                .frame(width: 36, height: 36)
                                .background(Color(hexString: category.colorHex))
                                .clipShape(Circle())

                            Text(category.name)
                                .appFont(.bodyBold)
                                .foregroundStyle(AppColor.textPrimary)

                            Spacer()

                            Text(category.amount.formattedCurrency(code: viewModel.currencyCode))
                                .appFont(.headline)
                                .foregroundStyle(AppColor.textPrimary)
                        }
                        .padding(.vertical, AppSpacing.sm)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(category.name) spending \(category.amount.formattedCurrency(code: viewModel.currencyCode))")

                        if category != viewModel.categorySpendings.last {
                            Divider()
                                .background(AppColor.border)
                        }
                    }
                }
                .padding(AppSpacing.md)
                .background(AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.large))
                .overlay {
                    RoundedRectangle(cornerRadius: Radius.large)
                        .stroke(AppColor.border)
                }
            }
        }
    }

    private var budgetInsightsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "chart.bar.doc.horizontal")
                    .foregroundStyle(AppColor.primary)
                    .accessibilityHidden(true)

                SectionHeader(title: "budget.insights")
            }

            if viewModel.budgetInsights.isEmpty {
                EmptyState(
                    title: "budget.empty.insights.title",
                    message: "budget.empty.insights.message"
                )
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(viewModel.budgetInsights) { insight in
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundStyle(AppColor.primary)
                                .frame(width: 24, height: 24)
                                .background(AppColor.surfaceAlt)
                                .clipShape(Circle())
                                .accessibilityHidden(true)

                            Text(LocalizedStringKey(insight.message))
                                .appFont(.footnote)
                                .foregroundStyle(AppColor.textPrimary)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer()
                        }
                        .padding(AppSpacing.sm)
                        .background(AppColor.surface)
                        .clipShape(RoundedRectangle(cornerRadius: Radius.medium))
                        .overlay {
                            RoundedRectangle(cornerRadius: Radius.medium)
                                .stroke(AppColor.border)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                SectionHeader(title: "Recent Transactions")

                Spacer()

                NavigationLink("View All", value: AppRoute.expenses)
                    .appFont(.caption)
                    .foregroundStyle(AppColor.primary)
                    .accessibilityLabel("View All Expenses")
            }

            if viewModel.recentTransactions.isEmpty {
                EmptyState(
                    title: "No Transactions yet",
                    message: "Tap the + button to add your first expense or income."
                )
            } else {
                VStack(spacing: AppSpacing.none) {
                    ForEach(viewModel.recentTransactions) { transaction in
                        HStack(spacing: AppSpacing.md) {
                            Image(systemName: transaction.categoryIcon)
                                .foregroundStyle(AppColor.textInverse)
                                .frame(width: 36, height: 36)
                                .background(transaction.isExpense ? AppColor.secondary : AppColor.success)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                                Text(transaction.merchant)
                                    .appFont(.bodyBold)
                                    .foregroundStyle(AppColor.textPrimary)

                                Text(transaction.categoryName)
                                    .appFont(.caption)
                                    .foregroundStyle(AppColor.textSecondary)
                            }

                            Spacer()

                            let prefix = transaction.isExpense ? "-" : "+"
                            Text("\(prefix)\(transaction.amount.formattedCurrency(code: viewModel.currencyCode))")
                                .appFont(.headline)
                                .foregroundStyle(transaction.isExpense ? AppColor.textPrimary : AppColor.success)
                        }
                        .padding(.vertical, AppSpacing.sm)

                        if transaction != viewModel.recentTransactions.last {
                            Divider()
                                .background(AppColor.border)
                        }
                    }
                }
                .padding(AppSpacing.md)
                .background(AppColor.surface)
                .clipShape(RoundedRectangle(cornerRadius: Radius.large))
                .overlay {
                    RoundedRectangle(cornerRadius: Radius.large)
                        .stroke(AppColor.border)
                }
            }
        }
    }

    private var quickAddButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    showingQuickAdd = true
                }) {
                    Image(systemName: "plus")
                        .appFont(.headline)
                        .foregroundStyle(AppColor.textInverse)
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(AppColor.primary)
                                .appShadow(.floating)
                        )
                }
                .padding(AppSpacing.md)
                .accessibilityLabel("Quick Add Transaction")
            }
        }
    }

    private var quickAddSheet: some View {
        let expenseRepository = SwiftDataExpenseRepository(context: modelContext)
        let categoryRepository = SwiftDataCategoryRepository(context: modelContext)
        let budgetRepository = SwiftDataBudgetRepository(modelContainer: modelContext.container)

        return AddExpenseView(
            viewModel: AddExpenseViewModel(
                addExpenseUseCase: AddExpenseUseCase(repository: expenseRepository),
                categoryRepository: categoryRepository,
                currency: settings.currency,
                previewBudgetImpactUseCase: DefaultPreviewBudgetImpactUseCase(
                    budgetRepository: budgetRepository,
                    expenseRepository: expenseRepository
                )
            )
        ) {
            Task {
                await viewModel.loadDashboardData(currency: settings.currency)
            }
        }
    }
}

#Preview {
    NavigationStack {
        DashboardView(
            viewModel: DashboardViewModel(),
            settings: .constant(.default)
        )
    }
}
