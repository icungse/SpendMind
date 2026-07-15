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

    private func makeViewModel(
        useCase: any GetCurrentBudgetsUseCase,
        currency: CurrencyCode = .IDR,
        locale: Locale = .current
    ) -> BudgetListViewModel {
        BudgetListViewModel(
            getCurrentBudgetsUseCase: useCase,
            currency: currency,
            locale: locale,
            currentDate: date(year: 2026, month: 7, day: 15)
        )
    }

    private func budget(amount: Decimal) throws -> Budget {
        try Budget(
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
