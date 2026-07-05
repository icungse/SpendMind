//
//  SpendMindTest.swift
//  SpendMindTests
//
//  Created by Icung on 03/07/26.
//

import XCTest
import SwiftUI
@testable import SpendMind

final class SpendMindTests: XCTestCase {
    func testAppTargetLoads() {
        XCTAssertTrue(true)
    }

    func testDependenciesCanBeMocked() {
        struct MockDependencies: AppDependencyProviding { }

        var environment = EnvironmentValues()
        environment.dependencies = MockDependencies()

        XCTAssertTrue(environment.dependencies is MockDependencies)
    }

    func testSwiftDataTestContainerLoads() {
        XCTAssertNoThrow(try SpendMindModelContainer.test())
    }

    func testAppLoggerAcceptsSupportedModes() {
        AppLogger.debug("Debug log")
        AppLogger.error("Error log")
        AppLogger.analytics("Analytics log")
        AppLogger.performance("Performance log")
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
            isFirstLaunchCompleted: true
        )

        manager.save(settings)

        XCTAssertEqual(manager.load(), settings)
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
        guard let url = URL(string: "spendmind://dashboard") else {
            return XCTFail("Expected valid dashboard URL.")
        }

        router.handleDeepLink(url)

        XCTAssertEqual(router.path, [.dashboard])
    }

    private func makeTestUserDefaults() -> UserDefaults {
        let suiteName = "dev.spendmind.tests.\(UUID().uuidString)"
        guard let userDefaults = UserDefaults(suiteName: suiteName) else {
            return .standard
        }

        userDefaults.removePersistentDomain(forName: suiteName)
        return userDefaults
    }
}
