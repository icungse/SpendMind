//
//  BudgetListView.swift
//  Veyra
//
//  Created by Icung on 15/07/26.
//

import SwiftUI

struct BudgetListView: View {
    @State private var viewModel: BudgetListViewModel
    @State private var showingCreateBudget = false
    @State private var editingProgress: BudgetProgress?
    nonisolated(unsafe) private let createBudgetUseCase: any CreateBudgetUseCase
    nonisolated(unsafe) private let updateBudgetUseCase: any UpdateBudgetUseCase
    nonisolated(unsafe) private let deleteBudgetUseCase: any DeleteBudgetUseCase
    nonisolated(unsafe) private let budgetRepository: any BudgetRepository
    private let categoryRepository: any CategoryRepository

    init(
        viewModel: BudgetListViewModel,
        createBudgetUseCase: any CreateBudgetUseCase,
        updateBudgetUseCase: any UpdateBudgetUseCase,
        deleteBudgetUseCase: any DeleteBudgetUseCase,
        budgetRepository: any BudgetRepository,
        categoryRepository: any CategoryRepository
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.createBudgetUseCase = createBudgetUseCase
        self.updateBudgetUseCase = updateBudgetUseCase
        self.deleteBudgetUseCase = deleteBudgetUseCase
        self.budgetRepository = budgetRepository
        self.categoryRepository = categoryRepository
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                LoadingView(title: "budget.loading")
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
        .navigationTitle("budget.title_plural")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingCreateBudget = true
                } label: {
                    Label("budget.create", systemImage: "plus")
                }
                .accessibilityLabel("budget.create")
            }
        }
        .sheet(isPresented: $showingCreateBudget) {
            BudgetFormView(
                viewModel: BudgetFormViewModel(
                    createBudgetUseCase: createBudgetUseCase,
                    updateBudgetUseCase: updateBudgetUseCase,
                    deleteBudgetUseCase: deleteBudgetUseCase,
                    budgetRepository: budgetRepository,
                    categoryRepository: categoryRepository
                )
            ) {
                Task { await viewModel.load() }
            }
        }
        .sheet(isPresented: Binding(
            get: { editingProgress != nil },
            set: { if !$0 { editingProgress = nil } }
        )) {
            if let editingProgress {
                BudgetFormView(
                    viewModel: BudgetFormViewModel(
                        createBudgetUseCase: createBudgetUseCase,
                        updateBudgetUseCase: updateBudgetUseCase,
                        deleteBudgetUseCase: deleteBudgetUseCase,
                        budgetRepository: budgetRepository,
                        categoryRepository: categoryRepository,
                        budget: editingProgress.budget
                    ),
                    warningStatus: editingProgress.status,
                    warningMessage: viewModel.warningMessage(for: editingProgress)
                ) {
                    Task { await viewModel.load() }
                }
            }
        }
        .task {
            if case .idle = viewModel.state {
                await viewModel.load()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: AppConstants.Notifications.expensesDidChange)) { notification in
            guard viewModel.shouldRefreshForExpenseChange(notification.userInfo) else { return }
            Task { await viewModel.refresh() }
        }
    }

    private var emptyState: some View {
        EmptyState(
            title: "budget.empty.create_first.title",
            message: "budget.empty.create_first.message",
            actionTitle: "budget.create"
        ) {
            showingCreateBudget = true
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorState(_ error: BudgetError) -> some View {
        EmptyState(
            title: "budget.load.failed",
            message: LocalizedStringKey(error.errorDescription ?? String(localized: "budget.try_again")),
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
                    .accessibilityLabel(String.localizedStringWithFormat(
                        String(localized: "budget.accessibility.current_month"),
                        viewModel.currentMonthLabel
                    ))

                monthlyTotalCard

                if let totalBudget = viewModel.totalBudget {
                    Button {
                        editingProgress = totalBudget
                    } label: {
                        BudgetProgressCardView(progress: totalBudget, viewModel: viewModel, isTotal: true)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(String.localizedStringWithFormat(
                        String(localized: "budget.accessibility.edit"),
                        totalBudget.budget.name
                    ))
                }

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("budget.category_budgets")
                        .appFont(.headline)
                        .foregroundStyle(AppColor.textPrimary)

                    ForEach(viewModel.categoryBudgets, id: \.budget.id) { progress in
                        Button {
                            editingProgress = progress
                        } label: {
                            BudgetProgressCardView(progress: progress, viewModel: viewModel, isTotal: false)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(String.localizedStringWithFormat(
                            String(localized: "budget.accessibility.edit"),
                            progress.budget.name
                        ))
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
            PrimaryButton(title: "budget.create") {
                showingCreateBudget = true
            }
            .padding(AppSpacing.md)
            .background(AppColor.background.opacity(0.95))
        }
    }

    private var monthlyTotalCard: some View {
        Card {
            BudgetCardBodyView(
                title: String(localized: "budget.total_monthly"),
                subtitle: String(localized: "budget.total.active_budgets"),
                icon: "chart.pie.fill",
                iconColor: AppColor.primary,
                amount: viewModel.formattedTotalLimit,
                spent: viewModel.formattedTotalSpent,
                remaining: viewModel.formattedTotalRemaining,
                progress: viewModel.totalProgress,
                status: totalStatus,
                warningMessage: viewModel.warningMessage(
                    status: totalStatus,
                    name: String(localized: "budget.total_monthly"),
                    spent: viewModel.totalSpentAmount,
                    remaining: viewModel.totalRemainingAmount
                ),
                isTotal: true
            )
        }
    }

    private var totalStatus: BudgetStatus {
        if viewModel.totalSpentAmount > viewModel.totalLimitAmount { return .exceeded }
        if viewModel.totalProgress >= 0.8 { return .warning }
        return .safe
    }
}

private struct BudgetFormView: View {
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    @State private var viewModel: BudgetFormViewModel
    @State private var showingDeleteConfirmation = false
    let warningStatus: BudgetStatus?
    let warningMessage: String?
    let onSaved: () -> Void

    private enum Field {
        case name
        case amount
        case alertThreshold
    }

    init(
        viewModel: BudgetFormViewModel,
        warningStatus: BudgetStatus? = nil,
        warningMessage: String? = nil,
        onSaved: @escaping () -> Void = {}
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.warningStatus = warningStatus
        self.warningMessage = warningMessage
        self.onSaved = onSaved
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Form {
                if let warningStatus, let warningMessage, warningStatus != .safe {
                    Section {
                        BudgetWarningBanner(status: warningStatus, message: warningMessage)
                    }
                }

                Section("budget.type") {
                    Picker("budget.type", selection: $viewModel.budgetType) {
                        Text("budget.form.type.total").tag(BudgetFormViewModel.BudgetType.total)
                        Text("budget.form.type.category").tag(BudgetFormViewModel.BudgetType.category)
                    }
                    .pickerStyle(.inline)
                    .accessibilityLabel("budget.accessibility.type")
                }

                Section("budget.details") {
                    TextField("budget.name", text: $viewModel.name)
                        .textInputAutocapitalization(.words)
                        .focused($focusedField, equals: .name)
                        .accessibilityLabel("budget.accessibility.name")
                    validationText(viewModel.nameError)

                    if viewModel.budgetType == .category {
                        Picker("budget.accessibility.category", selection: $viewModel.selectedCategoryID) {
                            Text("budget.select_category").tag(UUID?.none)
                            ForEach(viewModel.categories, id: \.id) { category in
                                CategoryPickerRow(
                                    category: category,
                                    isSelected: viewModel.selectedCategoryID == category.id,
                                    subtitle: viewModel.categorySubtitle(for: category),
                                    isDisabled: viewModel.isCategoryDisabled(category.id)
                                )
                                .tag(Optional(category.id))
                                .disabled(viewModel.isCategoryDisabled(category.id))
                            }
                        }
                        .accessibilityLabel("budget.accessibility.category")
                        validationText(viewModel.categoryError)
                    }

                    TextField("budget.amount", text: Binding(
                        get: { viewModel.amountText },
                        set: { viewModel.updateAmountText($0) }
                    ))
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .amount)
                    .accessibilityLabel("budget.accessibility.amount")
                    validationText(viewModel.amountError)

                    MonthPicker(
                        selection: $viewModel.month,
                        selectedDate: viewModel.monthPickerSelectedDate,
                        calendar: viewModel.calendar,
                        locale: viewModel.monthPickerLocale
                    )
                }

                Section("budget.alert_settings") {
                    Picker("budget.alert_threshold", selection: $viewModel.alertThresholdPercent) {
                        ForEach(viewModel.alertThresholdOptions, id: \.self) { percent in
                            Text(viewModel.alertThresholdLabel(percent)).tag(percent)
                        }
                    }
                    .pickerStyle(.inline)
                    .accessibilityLabel("budget.accessibility.threshold")
                    validationText(viewModel.alertThresholdError)
                }

                if viewModel.isEditing {
                    Section {
                        Button("budget.delete", role: .destructive) {
                            showingDeleteConfirmation = true
                        }
                        .accessibilityLabel("budget.accessibility.delete")
                    }
                }

                if let message = viewModel.formMessage {
                    Text(message)
                        .appFont(.footnote)
                        .foregroundStyle(AppColor.error)
                        .accessibilityLabel(String.localizedStringWithFormat(
                            String(localized: "budget.accessibility.validation_error"),
                            message
                        ))
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(.hidden)
            .background(AppColor.background)
            .navigationTitle(LocalizedStringKey(viewModel.isEditing ? "budget.edit" : "budget.create"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("general.cancel") { dismiss() }
                        .accessibilityLabel("budget.accessibility.form.cancel")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("general.save") {
                        Task { await save() }
                    }
                    .disabled(!viewModel.canSave)
                    .accessibilityLabel("budget.accessibility.form.save")
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("general.done") { focusedField = nil }
                        .accessibilityLabel("budget.accessibility.dismiss_keyboard")
                }
            }
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(
                    title: LocalizedStringKey(viewModel.isEditing ? "budget.update" : "general.save"),
                    isLoading: viewModel.isSaving,
                    isDisabled: !viewModel.canSave
                ) {
                    Task { await save() }
                }
                .padding(AppSpacing.md)
                .background(AppColor.background)
            }
            .onAppear {
                Task { await viewModel.loadCategories() }
            }
            .onChange(of: viewModel.month) { _, _ in
                Task { await viewModel.loadCategories() }
            }
            .confirmationDialog(
                "budget.delete.confirmation.title",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("general.delete", role: .destructive) {
                    Task { await deleteBudget() }
                }

                Button("general.cancel", role: .cancel) { }
            } message: {
                Text("budget.delete.confirmation.message")
            }
        }
    }

    @ViewBuilder
    private func validationText(_ message: String?) -> some View {
        if let message {
            Text(message)
                .appFont(.footnote)
                .foregroundStyle(AppColor.error)
                .accessibilityLabel(String.localizedStringWithFormat(
                    String(localized: "budget.accessibility.validation_error"),
                    message
                ))
        }
    }

    private func save() async {
        guard await viewModel.save() else { return }
        onSaved()
        dismiss()
    }

    private func deleteBudget() async {
        guard await viewModel.delete(isConfirmed: true) else { return }
        onSaved()
        dismiss()
    }
} 
