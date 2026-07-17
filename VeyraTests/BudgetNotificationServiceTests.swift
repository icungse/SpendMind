//
//  BudgetNotificationServiceTests.swift
//  VeyraTests
//
//  Created by Icung on 16/07/26.
//

import UserNotifications
import XCTest
@testable import Veyra

final class BudgetNotificationServiceTests: XCTestCase {
    func testSetEnabledRequestsPermissionOnlyWhenUndetermined() async {
        let center = MockUserNotificationCenter(status: .notDetermined, requestResult: true)
        let service = BudgetNotificationService(center: center)

        let enabled = await service.setEnabled(true)

        XCTAssertTrue(enabled)
        XCTAssertEqual(center.requestAuthorizationCount, 1)
    }

    func testSetEnabledReturnsFalseWhenPermissionDenied() async {
        let center = MockUserNotificationCenter(status: .denied)
        let service = BudgetNotificationService(center: center)

        let enabled = await service.setEnabled(true)

        XCTAssertFalse(enabled)
        XCTAssertEqual(center.requestAuthorizationCount, 0)
    }

    func testSetEnabledFalseClearsKnownBudgetNotifications() async {
        let center = MockUserNotificationCenter(status: .authorized)
        let service = BudgetNotificationService(center: center)

        let enabled = await service.setEnabled(false)

        XCTAssertFalse(enabled)
        XCTAssertEqual(center.removedIdentifiers.count, 2)
        XCTAssertTrue(center.removedIdentifiers.allSatisfy { $0.hasPrefix(AppConstants.NotificationIdentifier.budgetAlertPrefix) })
    }

    func testNotifyDoesNothingWhenPermissionDenied() async {
        let center = MockUserNotificationCenter(status: .denied)
        let service = BudgetNotificationService(center: center)

        await service.notify(event: .budgetExceeded)

        XCTAssertTrue(center.addedRequests.isEmpty)
    }

    func testNotifyDoesNotRequestPermission() async {
        let center = MockUserNotificationCenter(status: .notDetermined, requestResult: true)
        let service = BudgetNotificationService(center: center)

        await service.notify(event: .thresholdReached)

        XCTAssertEqual(center.requestAuthorizationCount, 0)
        XCTAssertTrue(center.addedRequests.isEmpty)
    }

    func testNotifyUsesGenericNotificationCopy() async throws {
        let center = MockUserNotificationCenter(status: .authorized)
        let service = BudgetNotificationService(center: center)

        await service.notify(event: .thresholdReached)

        let request = try XCTUnwrap(center.addedRequests.first)
        XCTAssertEqual(request.content.title, "Budget warning")
        XCTAssertEqual(request.content.body, "One of your budgets needs attention.")
    }
}

private final class MockUserNotificationCenter: UserNotificationCenterProtocol, @unchecked Sendable {
    var status: UNAuthorizationStatus
    var requestResult: Bool
    private(set) var requestAuthorizationCount = 0
    private(set) var addedRequests: [UNNotificationRequest] = []
    private(set) var removedIdentifiers: [String] = []

    init(status: UNAuthorizationStatus, requestResult: Bool = false) {
        self.status = status
        self.requestResult = requestResult
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        status
    }

    func requestAuthorization() async throws -> Bool {
        requestAuthorizationCount += 1
        status = requestResult ? .authorized : .denied
        return requestResult
    }

    func add(_ request: UNNotificationRequest) async throws {
        addedRequests.append(request)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removedIdentifiers.append(contentsOf: identifiers)
    }
}
