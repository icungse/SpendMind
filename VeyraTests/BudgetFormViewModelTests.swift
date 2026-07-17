//
//  BudgetFormViewModelTests.swift
//  VeyraTests
//
//  Created by Icung on 16/07/26.
//

import XCTest
@testable import Veyra

@MainActor
final class BudgetFormViewModelTests: XCTestCase {
    func testSaveIsDisabledForInvalidInputAndShowsFieldErrors() {
        let viewModel = makeViewModel()

        viewModel.name = ""
        viewModel.amountText = "0"

        XCTAssertFalse(viewModel.canSave)
        XCTAssertEqual(viewModel.nameError, "Budget name is required.")
        XCTAssertEqual(viewModel.amountError, "Amount must be greater than zero.")
    }

    func testCategoryBudgetRequiresCategory() {
        let viewModel = makeViewModel(categories: [])

        viewModel.name = "Food"
        viewModel.amountText = "100"
        viewModel.budgetType = .category

        XCTAssertFalse(viewModel.canSave)
        XCTAssertEqual(viewModel.categoryError, "Category is required.")
    }

    func testAlertThresholdMustBeAProvidedOption() {
        let viewModel = makeViewModel()

        viewModel.amountText = "100"
        viewModel.alertThresholdPercent = 60

        XCTAssertFalse(viewModel.canSave)
        XCTAssertEqual(viewModel.alertThresholdError, "Alert threshold must be valid.")
    }

    func testAlertThresholdDefaultsToEightyPercent() {
        let viewModel = makeViewModel()

        XCTAssertEqual(viewModel.alertThresholdPercent, 80)
        XCTAssertEqual(viewModel.alertThresholdOptions, [50, 75, 80, 90])
    }

    func testSavesCategoryBudget() async {
        let repository = BudgetFormMockRepository()
        let category = Veyra.Category(name: "Food", icon: "fork.knife", colorHex: "#5B7FFF")
        let viewModel = makeViewModel(repository: repository, categories: [category])

        await viewModel.loadCategories()
        viewModel.name = "Food"
        viewModel.budgetType = .category
        viewModel.selectedCategoryID = category.id
        viewModel.amountText = "250"
        viewModel.alertThresholdPercent = 75

        XCTAssertTrue(viewModel.canSave)
        let didSave = await viewModel.save()
        XCTAssertTrue(didSave)
        XCTAssertEqual(repository.createdBudgets.first?.name, "Food")
        XCTAssertEqual(repository.createdBudgets.first?.categoryID, category.id)
        XCTAssertEqual(repository.createdBudgets.first?.amount, 250)
        XCTAssertEqual(repository.createdBudgets.first?.alertThreshold, 0.75)
    }

    func testDecimalInputUsesLocale() async {
        let repository = BudgetFormMockRepository()
        let viewModel = makeViewModel(repository: repository, locale: Locale(identifier: "id_ID"))

        viewModel.updateAmountText("1,5")

        let didSave = await viewModel.save()
        XCTAssertTrue(didSave)
        XCTAssertEqual(repository.createdBudgets.first?.amount, Decimal(string: "1.5"))
    }

    func testEditModePrefillsAndUpdatesExistingBudget() async throws {
        let category = Veyra.Category(name: "Food", icon: "fork.knife", colorHex: "#5B7FFF")
        let existingBudget = try budget(categoryID: category.id, amount: 100, alertThreshold: 0.8)
        let repository = BudgetFormMockRepository(budgets: [existingBudget])
        let viewModel = makeViewModel(repository: repository, categories: [category], budget: existingBudget)

        await viewModel.loadCategories()

        XCTAssertTrue(viewModel.isEditing)
        XCTAssertEqual(viewModel.name, "Monthly")
        XCTAssertEqual(viewModel.budgetType, .category)
        XCTAssertEqual(viewModel.selectedCategoryID, category.id)
        XCTAssertEqual(viewModel.alertThresholdPercent, 80)

        viewModel.amountText = "150"
        viewModel.alertThresholdPercent = 90

        let didSave = await viewModel.save()
        XCTAssertTrue(didSave)
        XCTAssertEqual(repository.updatedBudgets.first?.id, existingBudget.id)
        XCTAssertEqual(repository.updatedBudgets.first?.amount, 150)
        XCTAssertEqual(repository.updatedBudgets.first?.alertThreshold, 0.9)
    }

    func testDuplicateActiveBudgetShowsSaveError() async throws {
        let existingBudget = try budget(categoryID: nil, amount: 100, alertThreshold: 0.8)
        let repository = BudgetFormMockRepository(activeBudgets: [existingBudget])
        let viewModel = makeViewModel(repository: repository)

        viewModel.amountText = "200"

        let didSave = await viewModel.save()
        XCTAssertFalse(didSave)
        XCTAssertEqual(viewModel.formMessage, "An active budget already exists for this category and period.")
    }

    func testLoadCategoriesHidesArchivedCategoriesUnlessSelected() async throws {
        let active = Veyra.Category(name: "Food", icon: "fork.knife", colorHex: "#5B7FFF")
        let archived = Veyra.Category(name: "Old", icon: "archivebox", colorHex: "#999999", isArchived: true)
        let existingBudget = try budget(categoryID: archived.id, amount: 100, alertThreshold: 0.8)
        let editViewModel = makeViewModel(categories: [active, archived], budget: existingBudget)
        let createViewModel = makeViewModel(categories: [active, archived])

        await editViewModel.loadCategories()
        await createViewModel.loadCategories()

        XCTAssertEqual(editViewModel.categories.map(\.id), [active.id, archived.id])
        XCTAssertEqual(editViewModel.categorySubtitle(for: archived), "Archived")
        XCTAssertEqual(createViewModel.categories.map(\.id), [active.id])
    }

    func testCategoryWithActiveBudgetIsDisabledForSelectedMonth() async throws {
        let category = Veyra.Category(name: "Food", icon: "fork.knife", colorHex: "#5B7FFF")
        let existingBudget = try budget(categoryID: category.id, amount: 100, alertThreshold: 0.8)
        let repository = BudgetFormMockRepository(activeBudgets: [existingBudget])
        let viewModel = makeViewModel(repository: repository, categories: [category])

        await viewModel.loadCategories()
        viewModel.budgetType = .category
        viewModel.selectedCategoryID = category.id
        viewModel.amountText = "200"

        XCTAssertTrue(viewModel.isCategoryDisabled(category.id))
        XCTAssertEqual(viewModel.categorySubtitle(for: category), "Already budgeted")
        XCTAssertFalse(viewModel.canSave)
        XCTAssertEqual(viewModel.categoryError, "Category already has an active budget for this month.")
    }

    func testEditingBudgetDoesNotDisableItsOwnCategory() async throws {
        let category = Veyra.Category(name: "Food", icon: "fork.knife", colorHex: "#5B7FFF")
        let existingBudget = try budget(categoryID: category.id, amount: 100, alertThreshold: 0.8)
        let repository = BudgetFormMockRepository(budgets: [existingBudget], activeBudgets: [existingBudget])
        let viewModel = makeViewModel(repository: repository, categories: [category], budget: existingBudget)

        await viewModel.loadCategories()
        viewModel.amountText = "200"

        XCTAssertFalse(viewModel.isCategoryDisabled(category.id))
        XCTAssertTrue(viewModel.canSave)
    }

    func testDeletesEditingBudgetWhenConfirmed() async throws {
        let existingBudget = try budget(categoryID: nil, amount: 100, alertThreshold: 0.8)
        let repository = BudgetFormMockRepository(budgets: [existingBudget])
        let viewModel = makeViewModel(repository: repository, budget: existingBudget)

        let didDelete = await viewModel.delete(isConfirmed: true)

        XCTAssertTrue(didDelete)
        XCTAssertEqual(repository.deletedBudgetIDs, [existingBudget.id])
    }

    func testDeleteRequiresConfirmation() async throws {
        let existingBudget = try budget(categoryID: nil, amount: 100, alertThreshold: 0.8)
        let repository = BudgetFormMockRepository(budgets: [existingBudget])
        let viewModel = makeViewModel(repository: repository, budget: existingBudget)

        let didDelete = await viewModel.delete(isConfirmed: false)

        XCTAssertFalse(didDelete)
        XCTAssertTrue(repository.deletedBudgetIDs.isEmpty)
        XCTAssertEqual(viewModel.formMessage, "Confirm delete before continuing.")
    }

    private func makeViewModel(
        repository: BudgetFormMockRepository = BudgetFormMockRepository(),
        categories: [Veyra.Category] = [],
        budget: Budget? = nil,
        locale: Locale = Locale(identifier: "en_US")
    ) -> BudgetFormViewModel {
        BudgetFormViewModel(
            createBudgetUseCase: DefaultCreateBudgetUseCase(repository: repository, calendar: calendar),
            updateBudgetUseCase: DefaultUpdateBudgetUseCase(repository: repository, calendar: calendar),
            deleteBudgetUseCase: DefaultDeleteBudgetUseCase(repository: repository),
            budgetRepository: repository,
            categoryRepository: BudgetFormCategoryRepository(categories: categories),
            budget: budget,
            locale: locale
        )
    }

    private func budget(categoryID: UUID?, amount: Decimal, alertThreshold: Decimal) throws -> Budget {
        try Budget(
            categoryID: categoryID,
            name: "Monthly",
            amount: amount,
            period: .monthly,
            startDate: date(year: 2026, month: 7, day: 1),
            endDate: date(year: 2026, month: 7, day: 31),
            alertThreshold: alertThreshold,
            calendar: calendar
        )
    }

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }

    private func date(year: Int, month: Int, day: Int) -> Date {
        DateComponents(calendar: calendar, year: year, month: month, day: day).date ?? Date()
    }
}

private final class BudgetFormMockRepository: BudgetRepository {
    private var budgetsByID: [UUID: Budget]
    private let activeBudgetResults: [Budget]
    private(set) var createdBudgets: [Budget] = []
    private(set) var updatedBudgets: [Budget] = []
    private(set) var deletedBudgetIDs: [UUID] = []

    init(budgets: [Budget] = [], activeBudgets: [Budget] = []) {
        self.budgetsByID = Dictionary(uniqueKeysWithValues: budgets.map { ($0.id, $0) })
        self.activeBudgetResults = activeBudgets
    }

    func create(_ budget: Budget) async throws {
        createdBudgets.append(budget)
        budgetsByID[budget.id] = budget
    }

    func update(_ budget: Budget) async throws {
        updatedBudgets.append(budget)
        budgetsByID[budget.id] = budget
    }

    func delete(id: UUID) async throws {
        deletedBudgetIDs.append(id)
        budgetsByID[id] = nil
    }

    func budget(id: UUID) async throws -> Budget? {
        budgetsByID[id]
    }

    func activeBudgets(for date: Date) async throws -> [Budget] {
        activeBudgetResults
    }

    func budgets(from startDate: Date, to endDate: Date) async throws -> [Budget] {
        Array(budgetsByID.values)
    }
}

private final class BudgetFormCategoryRepository: CategoryRepository {
    private let categories: [Veyra.Category]

    init(categories: [Veyra.Category]) {
        self.categories = categories
    }

    func getCategories() throws -> [Veyra.Category] { categories }
    func getDefaultCategories() throws -> [Veyra.Category] { categories.filter(\.isSystem) }
    func seedDefaultCategoriesIfNeeded() throws { }
}
