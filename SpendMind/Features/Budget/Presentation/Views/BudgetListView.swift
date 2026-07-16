//
//  BudgetListView.swift
//  SpendMind
//
//  Created by Icung on 15/07/26.
//

import SwiftUI

struct BudgetListView: View {
    @State private var viewModel: BudgetListViewModel
    @State private var showingCreateBudget = false
    nonisolated(unsafe) private let createBudgetUseCase: any CreateBudgetUseCase
    nonisolated(unsafe) private let updateBudgetUseCase: any UpdateBudgetUseCase
    private let categoryRepository: any CategoryRepository

    init(
        viewModel: BudgetListViewModel,
        createBudgetUseCase: any CreateBudgetUseCase,
        updateBudgetUseCase: any UpdateBudgetUseCase,
        categoryRepository: any CategoryRepository
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.createBudgetUseCase = createBudgetUseCase
        self.updateBudgetUseCase = updateBudgetUseCase
        self.categoryRepository = categoryRepository
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
                    showingCreateBudget = true
                } label: {
                    Label("Create Budget", systemImage: "plus")
                }
                .accessibilityLabel("Create Budget")
            }
        }
        .sheet(isPresented: $showingCreateBudget) {
            BudgetFormView(
                viewModel: BudgetFormViewModel(
                    createBudgetUseCase: createBudgetUseCase,
                    updateBudgetUseCase: updateBudgetUseCase,
                    categoryRepository: categoryRepository
                )
            ) {
                Task { await viewModel.load() }
            }
        }
        .task {
            if case .idle = viewModel.state {
                await viewModel.load()
            }
        }
    }

    private var emptyState: some View {
        EmptyState(
            title: "Create your first budget",
            message: "Set a monthly spending limit and track your progress throughout the month.",
            actionTitle: "Create Budget"
        ) {
            showingCreateBudget = true
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
                    BudgetProgressCardView(progress: totalBudget, viewModel: viewModel, isTotal: true)
                }

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Category Budgets")
                        .appFont(.headline)
                        .foregroundStyle(AppColor.textPrimary)

                    ForEach(viewModel.categoryBudgets, id: \.budget.id) { progress in
                        BudgetProgressCardView(progress: progress, viewModel: viewModel, isTotal: false)
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
            PrimaryButton(title: "Create Budget") {
                showingCreateBudget = true
            }
            .padding(AppSpacing.md)
            .background(AppColor.background.opacity(0.95))
        }
    }

    private var monthlyTotalCard: some View {
        Card {
            BudgetCardBodyView(
                title: "Total Monthly Budget",
                subtitle: "All active budgets",
                icon: "chart.pie.fill",
                iconColor: AppColor.primary,
                amount: viewModel.formattedTotalLimit,
                spent: viewModel.formattedTotalSpent,
                remaining: viewModel.formattedTotalRemaining,
                progress: viewModel.totalProgress,
                status: totalStatus,
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
    let onSaved: () -> Void

    private enum Field {
        case name
        case amount
        case alertThreshold
    }

    init(viewModel: BudgetFormViewModel, onSaved: @escaping () -> Void = {}) {
        self._viewModel = State(initialValue: viewModel)
        self.onSaved = onSaved
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            Form {
                Section("Budget") {
                    TextField("Name", text: $viewModel.name)
                        .textInputAutocapitalization(.words)
                        .focused($focusedField, equals: .name)
                        .accessibilityLabel("Budget Name")
                    validationText(viewModel.nameError)

                    Picker("Type", selection: $viewModel.budgetType) {
                        ForEach(BudgetFormViewModel.BudgetType.allCases) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    .accessibilityLabel("Budget Type")

                    if viewModel.budgetType == .category {
                        Picker("Category", selection: $viewModel.selectedCategoryID) {
                            Text("Select Category").tag(UUID?.none)
                            ForEach(viewModel.categories, id: \.id) { category in
                                Text(category.name).tag(Optional(category.id))
                            }
                        }
                        .accessibilityLabel("Budget Category")
                        validationText(viewModel.categoryError)
                    }

                    TextField("Amount", text: Binding(
                        get: { viewModel.amountText },
                        set: { viewModel.updateAmountText($0) }
                    ))
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .amount)
                    .accessibilityLabel("Budget Amount")
                    validationText(viewModel.amountError)

                    DatePicker("Month", selection: $viewModel.month, displayedComponents: .date)
                        .accessibilityLabel("Budget Month")

                    TextField("Alert Threshold", text: Binding(
                        get: { viewModel.alertThresholdText },
                        set: { viewModel.updateAlertThresholdText($0) }
                    ))
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .alertThreshold)
                    .accessibilityLabel("Budget Alert Threshold")
                    validationText(viewModel.alertThresholdError)
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
            .navigationTitle(viewModel.isEditing ? "Edit Budget" : "Create Budget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityLabel("Cancel Budget Form")
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(!viewModel.canSave)
                    .accessibilityLabel("Save Budget")
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                        .accessibilityLabel("Dismiss Keyboard")
                }
            }
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(
                    title: viewModel.isEditing ? "Update Budget" : "Save Budget",
                    isLoading: viewModel.isSaving,
                    isDisabled: !viewModel.canSave
                ) {
                    Task { await save() }
                }
                .padding(AppSpacing.md)
                .background(AppColor.background)
            }
            .onAppear {
                viewModel.loadCategories()
            }
        }
    }

    @ViewBuilder
    private func validationText(_ message: String?) -> some View {
        if let message {
            Text(message)
                .appFont(.footnote)
                .foregroundStyle(AppColor.error)
                .accessibilityLabel("Validation Error: \(message)")
        }
    }

    private func save() async {
        guard await viewModel.save() else { return }
        onSaved()
        dismiss()
    }
} 
