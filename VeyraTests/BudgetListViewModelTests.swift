//
//  BudgetListViewModelTests.swift
//  VeyraTests
//
//  Created by Icung on 15/07/26.
//

import XCTest
@testable import Veyra

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
        let category = Veyra.Category(name: "Very Long Grocery Category", icon: "cart.fill", colorHex: "#00AA55")
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

    func testLoadRecordsAlertStateAndNotifiesWhenEnabled() async throws {
        let progress = BudgetProgress(budget: try budget(amount: 100), spentAmount: 80)
        let alertRepository = BudgetListMockAlertStateRepository()
        let notificationService = BudgetListMockNotificationService()
        let viewModel = makeViewModel(
            useCase: BudgetListMockUseCase(results: [[progress]]),
            budgetAlertStateRepository: alertRepository,
            budgetNotificationService: notificationService,
            budgetNotificationsEnabled: true
        )

        await viewModel.load()

        let state = await alertRepository.state(for: progress.budget.id)
        let events = await notificationService.sentEvents()
        XCTAssertEqual(state?.status, .warning)
        XCTAssertEqual(events, [.thresholdReached])
    }

    func testLoadRecordsAlertStateWithoutNotifyingWhenDisabled() async throws {
        let progress = BudgetProgress(budget: try budget(amount: 100), spentAmount: 125)
        let alertRepository = BudgetListMockAlertStateRepository()
        let notificationService = BudgetListMockNotificationService()
        let viewModel = makeViewModel(
            useCase: BudgetListMockUseCase(results: [[progress]]),
            budgetAlertStateRepository: alertRepository,
            budgetNotificationService: notificationService,
            budgetNotificationsEnabled: false
        )

        await viewModel.load()

        let state = await alertRepository.state(for: progress.budget.id)
        let events = await notificationService.sentEvents()
        XCTAssertEqual(state?.status, .exceeded)
        XCTAssertEqual(events, [])
    }

    private func makeViewModel(
        useCase: any GetCurrentBudgetsUseCase,
        categoryRepository: (any CategoryRepository)? = nil,
        currency: CurrencyCode = .IDR,
        locale: Locale = .current,
        budgetAlertStateRepository: (any BudgetAlertStateRepository)? = nil,
        budgetNotificationService: (any BudgetNotificationServiceProtocol)? = nil,
        budgetNotificationsEnabled: Bool = false
    ) -> BudgetListViewModel {
        BudgetListViewModel(
            getCurrentBudgetsUseCase: useCase,
            categoryRepository: categoryRepository,
            currency: currency,
            locale: locale,
            currentDate: date(year: 2026, month: 7, day: 15),
            calendar: calendar,
            budgetAlertStateRepository: budgetAlertStateRepository,
            budgetNotificationService: budgetNotificationService,
            budgetNotificationsEnabled: budgetNotificationsEnabled
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
    let categories: [Veyra.Category]

    init(categories: [Veyra.Category]) {
        self.categories = categories
    }

    func getCategories() throws -> [Veyra.Category] { categories }
    func getDefaultCategories() throws -> [Veyra.Category] { categories.filter { $0.isSystem } }
    func seedDefaultCategoriesIfNeeded() throws { }
}

private actor BudgetListMockAlertStateRepository: BudgetAlertStateRepository {
    private var states: [UUID: BudgetAlertState] = [:]

    func state(for budgetID: UUID) -> BudgetAlertState? {
        states[budgetID]
    }

    func save(_ state: BudgetAlertState) {
        states[state.budgetID] = state
    }

    func delete(budgetID: UUID) {
        states[budgetID] = nil
    }
}

private actor BudgetListMockNotificationService: BudgetNotificationServiceProtocol {
    private var events: [BudgetAlertEvent] = []

    func setEnabled(_ enabled: Bool) -> Bool {
        enabled
    }

    func notify(event: BudgetAlertEvent) {
        events.append(event)
    }

    func sentEvents() -> [BudgetAlertEvent] {
        events
    }
}
