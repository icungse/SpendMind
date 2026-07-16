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
    @State private var editingBudget: Budget?
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
                    deleteBudgetUseCase: deleteBudgetUseCase,
                    budgetRepository: budgetRepository,
                    categoryRepository: categoryRepository
                )
            ) {
                Task { await viewModel.load() }
            }
        }
        .sheet(isPresented: Binding(
            get: { editingBudget != nil },
            set: { if !$0 { editingBudget = nil } }
        )) {
            if let editingBudget {
                BudgetFormView(
                    viewModel: BudgetFormViewModel(
                        createBudgetUseCase: createBudgetUseCase,
                        updateBudgetUseCase: updateBudgetUseCase,
                        deleteBudgetUseCase: deleteBudgetUseCase,
                        budgetRepository: budgetRepository,
                        categoryRepository: categoryRepository,
                        budget: editingBudget
                    )
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
                    Button {
                        editingBudget = totalBudget.budget
                    } label: {
                        BudgetProgressCardView(progress: totalBudget, viewModel: viewModel, isTotal: true)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Edit \(totalBudget.budget.name)")
                }

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Category Budgets")
                        .appFont(.headline)
                        .foregroundStyle(AppColor.textPrimary)

                    ForEach(viewModel.categoryBudgets, id: \.budget.id) { progress in
                        Button {
                            editingBudget = progress.budget
                        } label: {
                            BudgetProgressCardView(progress: progress, viewModel: viewModel, isTotal: false)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Edit \(progress.budget.name)")
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
    @State private var showingDeleteConfirmation = false
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
                Section("Budget Type") {
                    Picker("Type", selection: $viewModel.budgetType) {
                        Text("Total spending").tag(BudgetFormViewModel.BudgetType.total)
                        Text("Specific category").tag(BudgetFormViewModel.BudgetType.category)
                    }
                    .pickerStyle(.inline)
                    .accessibilityLabel("Budget Type")
                }

                Section("Budget Details") {
                    TextField("Name", text: $viewModel.name)
                        .textInputAutocapitalization(.words)
                        .focused($focusedField, equals: .name)
                        .accessibilityLabel("Budget Name")
                    validationText(viewModel.nameError)

                    if viewModel.budgetType == .category {
                        Picker("Category", selection: $viewModel.selectedCategoryID) {
                            Text("Select Category").tag(UUID?.none)
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

                    MonthPicker(
                        selection: $viewModel.month,
                        selectedDate: viewModel.monthPickerSelectedDate,
                        calendar: viewModel.calendar,
                        locale: viewModel.monthPickerLocale
                    )
                }

                Section("Alert Settings") {
                    Picker("Alert threshold", selection: $viewModel.alertThresholdPercent) {
                        ForEach(viewModel.alertThresholdOptions, id: \.self) { percent in
                            Text(viewModel.alertThresholdLabel(percent)).tag(percent)
                        }
                    }
                    .pickerStyle(.inline)
                    .accessibilityLabel("Budget Alert Threshold")
                    validationText(viewModel.alertThresholdError)
                }

                if viewModel.isEditing {
                    Section {
                        Button("Delete Budget", role: .destructive) {
                            showingDeleteConfirmation = true
                        }
                        .accessibilityLabel("Delete Budget")
                    }
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
                Task { await viewModel.loadCategories() }
            }
            .onChange(of: viewModel.month) { _, _ in
                Task { await viewModel.loadCategories() }
            }
            .confirmationDialog(
                "Delete this budget?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    Task { await deleteBudget() }
                }

                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Your expenses will not be deleted.")
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

    private func deleteBudget() async {
        guard await viewModel.delete(isConfirmed: true) else { return }
        onSaved()
        dismiss()
    }
} 
