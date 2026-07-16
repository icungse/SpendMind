//
//  BudgetListViewModelTests.swift
//  SpendMindTests
//
//  Created by Icung on 15/07/26.
//

import XCTest
@testable import SpendMind

@MainActor
final class BudgetListViewModelTests: XCTestCase {
    func testInitialStateIsIdle() {
        let viewModel = makeViewModel(useCase: BudgetListMockUseCase(results: []))

        XCTAssertEqual(viewModel.state, .idle)
    }

    func testLoadShowsLoadingState() async {
        let useCase = BlockingBudgetListMockUseCase()
        let viewModel = makeViewModel(useCase: useCase)

        let task = Task { await viewModel.load() }
        while !useCase.isWaiting {
            await Task.yield()
        }

        XCTAssertEqual(viewModel.state, .loading)

        useCase.resume(returning: [])
        await task.value
    }

    func testLoadShowsEmptyStateWhenNoBudgetsExist() async {
        let viewModel = makeViewModel(useCase: BudgetListMockUseCase(results: []))

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .empty)
    }

    func testLoadShowsLoadedStateWithBudgets() async throws {
        let progress = BudgetProgress(budget: try budget(amount: 100), spentAmount: 40)
        let viewModel = makeViewModel(useCase: BudgetListMockUseCase(results: [[progress]]))

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .loaded([progress]))
    }

    func testLoadShowsFailedState() async {
        let viewModel = makeViewModel(useCase: BudgetListMockUseCase(error: .persistence("Load failed.")))

        await viewModel.load()

        XCTAssertEqual(viewModel.state, BudgetListState.failed(.persistence("Load failed.")))
    }

    func testRetryLoadsAgainAfterFailure() async throws {
        let progress = BudgetProgress(budget: try budget(amount: 100), spentAmount: 20)
        let useCase = BudgetListMockUseCase(error: .database("Offline."), results: [[progress]])
        let viewModel = makeViewModel(useCase: useCase)

        await viewModel.load()
        await viewModel.retry()

        XCTAssertEqual(useCase.executeCount, 2)
        XCTAssertEqual(viewModel.state, .loaded([progress]))
    }

    func testRefreshLoadsLatestBudgets() async throws {
        let first = BudgetProgress(budget: try budget(amount: 100), spentAmount: 20)
        let second = BudgetProgress(budget: try budget(amount: 200), spentAmount: 80)
        let useCase = BudgetListMockUseCase(results: [[first], [first, second]])
        let viewModel = makeViewModel(useCase: useCase)

        await viewModel.load()
        await viewModel.refresh()

        XCTAssertEqual(useCase.executeCount, 2)
        XCTAssertEqual(viewModel.state, .loaded([first, second]))
    }

    func testFormattedTotalsUseSelectedCurrency() async throws {
        let locale = Locale(identifier: "en_US")
        let progress = [
            BudgetProgress(budget: try budget(amount: 100), spentAmount: 40),
            BudgetProgress(budget: try budget(amount: 50), spentAmount: 10)
        ]
        let viewModel = makeViewModel(
            useCase: BudgetListMockUseCase(results: [progress]),
            currency: .USD,
            locale: locale
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.formattedTotalLimit, Decimal(150).formattedCurrency(code: "USD", locale: locale))
        XCTAssertEqual(viewModel.formattedTotalSpent, Decimal(50).formattedCurrency(code: "USD", locale: locale))
        XCTAssertEqual(viewModel.formattedTotalRemaining, Decimal(100).formattedCurrency(code: "USD", locale: locale))
    }

    func testCurrentMonthLabelUsesSelectedDate() {
        let viewModel = makeViewModel(useCase: BudgetListMockUseCase(results: []), locale: Locale(identifier: "en_US"))

        XCTAssertEqual(viewModel.currentMonthLabel, "July 2026")
    }

    func testSplitsTotalAndCategoryBudgets() async throws {
        let categoryID = UUID()
        let total = BudgetProgress(budget: try budget(amount: 100), spentAmount: 40)
        let category = BudgetProgress(budget: try budget(categoryID: categoryID, amount: 50), spentAmount: 10)
        let viewModel = makeViewModel(useCase: BudgetListMockUseCase(results: [[total, category]]))

        await viewModel.load()

        XCTAssertEqual(viewModel.totalBudget, total)
        XCTAssertEqual(viewModel.categoryBudgets, [category])
    }

    func testCategoryMetadataUsesRepositoryWhenAvailable() async throws {
        let category = SpendMind.Category(name: "Very Long Grocery Category", icon: "cart.fill", colorHex: "#00AA55")
        let progress = BudgetProgress(budget: try budget(categoryID: category.id, amount: 100), spentAmount: 25)
        let viewModel = makeViewModel(
            useCase: BudgetListMockUseCase(results: [[progress]]),
            categoryRepository: BudgetListMockCategoryRepository(categories: [category])
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.categoryIcon(for: progress), "cart.fill")
        XCTAssertEqual(viewModel.categoryColorHex(for: progress), "#00AA55")
        XCTAssertEqual(viewModel.typeLabel(for: progress), "Category Budget")
        XCTAssertEqual(viewModel.statusLabel(for: progress.status), "Safe")
        XCTAssertEqual(viewModel.percentageUsed(for: progress), "25%")
    }

    func testExpenseChangeRefreshesWhenItTouchesCurrentMonth() {
        let viewModel = makeViewModel(useCase: BudgetListMockUseCase(results: []))
        let userInfo = [AppConstants.Notifications.expenseDatesKey: [date(year: 2026, month: 6, day: 30), date(year: 2026, month: 7, day: 1)]]

        XCTAssertTrue(viewModel.shouldRefreshForExpenseChange(userInfo))
    }

    func testExpenseChangeSkipsRefreshWhenItDoesNotTouchCurrentMonth() {
        let viewModel = makeViewModel(useCase: BudgetListMockUseCase(results: []))
        let userInfo = [AppConstants.Notifications.expenseDatesKey: [date(year: 2026, month: 6, day: 30), date(year: 2026, month: 8, day: 1)]]

        XCTAssertFalse(viewModel.shouldRefreshForExpenseChange(userInfo))
    }

    func testExpenseChangeSkipsRefreshForUnbudgetedCategoryWhenNoTotalBudgetExists() async throws {
        let budgetedCategoryID = UUID()
        let unbudgetedCategoryID = UUID()
        let progress = BudgetProgress(budget: try budget(categoryID: budgetedCategoryID, amount: 100), spentAmount: 25)
        let viewModel = makeViewModel(useCase: BudgetListMockUseCase(results: [[progress]]))

        await viewModel.load()

        let userInfo: [String: Any] = [
            AppConstants.Notifications.expenseDatesKey: [date(year: 2026, month: 7, day: 15)],
            AppConstants.Notifications.expenseCategoryIDsKey: [unbudgetedCategoryID]
        ]
        XCTAssertFalse(viewModel.shouldRefreshForExpenseChange(userInfo))
    }

    func testExpenseChangeRefreshesForOldOrNewBudgetedCategory() async throws {
        let oldCategoryID = UUID()
        let newCategoryID = UUID()
        let progress = BudgetProgress(budget: try budget(categoryID: oldCategoryID, amount: 100), spentAmount: 25)
        let viewModel = makeViewModel(useCase: BudgetListMockUseCase(results: [[progress]]))

        await viewModel.load()

        let userInfo: [String: Any] = [
            AppConstants.Notifications.expenseDatesKey: [date(year: 2026, month: 7, day: 15)],
            AppConstants.Notifications.expenseCategoryIDsKey: [oldCategoryID, newCategoryID]
        ]
        XCTAssertTrue(viewModel.shouldRefreshForExpenseChange(userInfo))
    }

    func testWarningMessageExplainsWarningAndExceededStates() throws {
        let locale = Locale(identifier: "en_US")
        let viewModel = makeViewModel(useCase: BudgetListMockUseCase(results: []), currency: .USD, locale: locale)
        let warning = BudgetProgress(budget: try budget(amount: 100), spentAmount: 80)
        let exceeded = BudgetProgress(budget: try budget(amount: 100), spentAmount: 125)

        XCTAssertEqual(
            viewModel.warningMessage(for: warning),
            "You've used $80.00 of Monthly. $20.00 remains."
        )
        XCTAssertEqual(viewModel.warningMessage(for: exceeded), "Monthly is exceeded by $25.00.")
    }

    private func makeViewModel(
        useCase: any GetCurrentBudgetsUseCase,
        categoryRepository: (any CategoryRepository)? = nil,
        currency: CurrencyCode = .IDR,
        locale: Locale = .current
    ) -> BudgetListViewModel {
        BudgetListViewModel(
            getCurrentBudgetsUseCase: useCase,
            categoryRepository: categoryRepository,
            currency: currency,
            locale: locale,
            currentDate: date(year: 2026, month: 7, day: 15),
            calendar: calendar
        )
    }

    private func budget(categoryID: UUID? = nil, amount: Decimal) throws -> Budget {
        try Budget(
            categoryID: categoryID,
            name: "Monthly",
            amount: amount,
            period: .monthly,
            startDate: date(year: 2026, month: 7, day: 1),
            endDate: date(year: 2026, month: 7, day: 31),
            alertThreshold: 0.8,
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

private final class BudgetListMockUseCase: GetCurrentBudgetsUseCase {
    private var error: AppError?
    private var results: [[BudgetProgress]]
    private(set) var executeCount = 0

    init(error: AppError? = nil, results: [[BudgetProgress]] = []) {
        self.error = error
        self.results = results
    }

    func execute(referenceDate: Date) async throws -> [BudgetProgress] {
        executeCount += 1

        if let error {
            self.error = nil
            throw error
        }

        if results.isEmpty {
            return []
        }

        return results.removeFirst()
    }
}

private final class BlockingBudgetListMockUseCase: GetCurrentBudgetsUseCase {
    private var continuation: CheckedContinuation<[BudgetProgress], Error>?
    private(set) var isWaiting = false

    func execute(referenceDate: Date) async throws -> [BudgetProgress] {
        try await withCheckedThrowingContinuation { continuation in
            isWaiting = true
            self.continuation = continuation
        }
    }

    func resume(returning progress: [BudgetProgress]) {
        continuation?.resume(returning: progress)
    }
}

private final class BudgetListMockCategoryRepository: CategoryRepository {
    let categories: [SpendMind.Category]

    init(categories: [SpendMind.Category]) {
        self.categories = categories
    }

    func getCategories() throws -> [SpendMind.Category] { categories }
    func getDefaultCategories() throws -> [SpendMind.Category] { categories.filter { $0.isSystem } }
    func seedDefaultCategoriesIfNeeded() throws { }
}
