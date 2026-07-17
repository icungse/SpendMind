//
//  VeyraTest.swift
//  VeyraTests
//
//  Created by Icung on 03/07/26.
//

import XCTest
import SwiftUI
import SwiftData
@testable import Veyra

final class VeyraTests: XCTestCase {
    func testAppTargetLoads() {
        XCTAssertTrue(true)
    }

    func testDependenciesCanBeMocked() {
        struct MockDependencies: AppDependencyProviding {
            let settingsManager: any AppSettingsManagerProtocol = AppSettingsManager(userDefaults: UserDefaults())
            let budgetNotificationService: any BudgetNotificationServiceProtocol = BudgetNotificationService()
            let dateService: any DateServiceProtocol = DateService()
            let modelContainer: ModelContainer = VeyraModelContainer.preview
        }

        var environment = EnvironmentValues()
        environment.dependencies = MockDependencies()

        XCTAssertTrue(environment.dependencies is MockDependencies)
    }

    func testDependencyContainerInitializesDefaultDependencies() {
        let container = DependencyContainer()
        XCTAssertEqual(container.settingsManager.load(), .default)
    }

    func testSwiftDataTestContainerLoads() {
        XCTAssertNoThrow(try VeyraModelContainer.test())
    }

    func testVeyraModelContainerAppAndPreview() {
        // Touch static properties to verify instantiation and ensure code coverage.
        XCTAssertNotNil(VeyraModelContainer.preview)
        XCTAssertNotNil(VeyraModelContainer.app)
    }

    @MainActor
    func testViewApplyIf() {
        let view = Text("Hello")

        var appliedTrueExecuted = false
        let appliedTrue = view.applyIf(true) { original in
            appliedTrueExecuted = true
            return original.bold()
        }

        var appliedFalseExecuted = false
        let appliedFalse = view.applyIf(false) { original in
            appliedFalseExecuted = true
            return original.bold()
        }

        XCTAssertTrue(appliedTrueExecuted)
        XCTAssertFalse(appliedFalseExecuted)
        XCTAssertNotNil(appliedTrue)
        XCTAssertNotNil(appliedFalse)
    }

    func testAppLoggerAcceptsSupportedModes() {
        AppLogger.debug("Debug log")
        AppLogger.error("Error log")
        AppLogger.analytics("Analytics log")
        AppLogger.performance("Performance log")
    }

    func testAppErrorProvidesLocalizedDescription() {
        XCTAssertEqual(AppError.validation("Amount is required.").errorDescription, "Amount is required.")
    }

    func testAppErrorWrapKeepsExistingAppError() {
        let error = AppError.database("Database unavailable.")

        XCTAssertEqual(AppError.wrap(error), error)
    }

    func testAppErrorWrapConvertsUnknownError() {
        let error = NSError(domain: "VeyraTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed."])

        XCTAssertEqual(AppError.wrap(error), .unknown("Failed."))
    }

    func testSettingsManagerLoadsDefaults() {
        let manager = AppSettingsManager(userDefaults: makeTestUserDefaults())

        XCTAssertEqual(manager.load(), .default)
    }

    func testSettingsManagerPersistsSupportedSettings() {
        let manager = AppSettingsManager(userDefaults: makeTestUserDefaults())
        let categoryId = UUID()
        let settings = AppSettings(
            theme: .dark,
            currency: .USD,
            localeIdentifier: "en_US",
            isBiometricEnabled: true,
            isAIEnabled: false,
            defaultCategoryId: categoryId,
            isBudgetNotificationsEnabled: true,
            isFirstLaunchCompleted: true
        )

        manager.save(settings)

        XCTAssertEqual(manager.load(), settings)
    }

    func testDateServiceReturnsRelativeDate() {
        let calendar = makeTestCalendar()
        let now = makeDate(year: 2026, month: 7, day: 5, calendar: calendar)
        let yesterday = makeDate(year: 2026, month: 7, day: 4, calendar: calendar)
        let service = DateService(calendar: calendar, locale: Locale(identifier: "en_US_POSIX"), now: { now })

        XCTAssertFalse(service.relativeString(for: yesterday).isEmpty)
    }

    func testDateServiceFormatsDate() {
        let calendar = makeTestCalendar()
        let date = makeDate(year: 2026, month: 1, day: 15, calendar: calendar)
        let service = DateService(calendar: calendar, locale: Locale(identifier: "en_US_POSIX"))

        XCTAssertEqual(service.format(date), "Jan 15, 2026")
    }

    func testDateServiceCalendarUtilities() {
        let calendar = makeTestCalendar()
        let date = makeDate(year: 2026, month: 7, day: 5, calendar: calendar)
        let startOfMonth = makeDate(year: 2026, month: 7, day: 1, calendar: calendar)
        let startOfNextMonth = makeDate(year: 2026, month: 8, day: 1, calendar: calendar)
        let service = DateService(calendar: calendar, locale: Locale(identifier: "en_US_POSIX"), now: { date })

        XCTAssertTrue(service.isToday(date))
        XCTAssertEqual(service.startOfDay(for: date), date)
        XCTAssertEqual(service.startOfMonth(for: date), startOfMonth)
        XCTAssertEqual(service.dateIntervalOfMonth(containing: date), DateInterval(start: startOfMonth, end: startOfNextMonth))
    }

    func testStringExtensionsNormalizeBlankInput() {
        XCTAssertEqual("  coffee  \n".trimmed, "coffee")
        XCTAssertNil(" \n\t ".nilIfBlank)
        XCTAssertEqual("Groceries".nilIfBlank, "Groceries")
    }

    func testDecimalExtensionFormatsCurrency() {
        let value = Decimal(12.5).formattedCurrency(code: "USD", locale: Locale(identifier: "en_US"))

        XCTAssertEqual(value, "$12.50")
    }

    func testDateExtensionsUseProvidedCalendar() {
        let calendar = makeTestCalendar()
        let date = makeDate(year: 2026, month: 7, day: 5, calendar: calendar)
        let sameDay = makeDate(year: 2026, month: 7, day: 5, hour: 12, calendar: calendar)

        XCTAssertTrue(date.isSameDay(as: sameDay, calendar: calendar))
        XCTAssertEqual(sameDay.startOfDay(calendar: calendar), date)
    }

    func testRouterPushesAndPopsRoutes() {
        let router = AppRouter()

        router.push(.dashboard)
        XCTAssertEqual(router.path, [.dashboard])

        router.pop()
        XCTAssertTrue(router.path.isEmpty)
    }

    func testRouterPresentsAndDismissesModal() {
        let router = AppRouter()

        router.presentModal(.placeholder)
        XCTAssertEqual(router.modal?.id, AppModal.placeholder.id)

        router.dismissModal()
        XCTAssertNil(router.modal)
    }

    func testRouterPresentsAndDismissesFullScreenCover() {
        let router = AppRouter()

        router.presentFullScreenCover(.placeholder)
        XCTAssertEqual(router.fullScreenCover?.id, AppFullScreenCover.placeholder.id)

        router.dismissFullScreenCover()
        XCTAssertNil(router.fullScreenCover)
    }

    func testRouterHandlesDashboardDeepLink() {
        let router = AppRouter()
        guard let url = URL(string: "\(AppConstants.DeepLink.scheme)://\(AppConstants.DeepLink.dashboardHost)") else {
            return XCTFail("Expected valid dashboard URL.")
        }

        router.handleDeepLink(url)

        XCTAssertEqual(router.path, [.dashboard])
    }

    @MainActor
    func testDashboardViewModelWithMockServices() async {
        let mockDateService = MockDateService()
        mockDateService.stubbedStartOfDay = Date(timeIntervalSince1970: 10000)

        let viewModel = DashboardViewModel(dateService: mockDateService)
        await viewModel.loadDashboardData(currency: .USD)

        XCTAssertTrue(mockDateService.startOfDayCalled)
        XCTAssertEqual(viewModel.recentTransactions.count, 3)
    }

    private func makeTestUserDefaults() -> UserDefaults {
        let suiteName = "dev.veyra.tests.\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            return .standard
        }

        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }

    private func makeTestCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return calendar
    }

    private func makeDate(year: Int, month: Int, day: Int, hour: Int = 0, calendar: Calendar) -> Date {
        DateComponents(calendar: calendar, timeZone: calendar.timeZone, year: year, month: month, day: day, hour: hour).date ?? Date()
    }
}
