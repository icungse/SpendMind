//
//  BudgetNotificationService.swift
//  Veyra
//
//  Created by Icung on 16/07/26.
//

import Foundation
@preconcurrency import UserNotifications

protocol BudgetNotificationServiceProtocol: Sendable {
    func setEnabled(_ enabled: Bool) async -> Bool
    func notify(event: BudgetAlertEvent) async
}

protocol UserNotificationCenterProtocol: Sendable {
    func authorizationStatus() async -> UNAuthorizationStatus
    func requestAuthorization() async throws -> Bool
    func add(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
}

struct BudgetNotificationService: BudgetNotificationServiceProtocol {
    private let center: any UserNotificationCenterProtocol

    init(center: any UserNotificationCenterProtocol = UserNotificationCenter()) {
        self.center = center
    }

    func setEnabled(_ enabled: Bool) async -> Bool {
        guard enabled else {
            center.removePendingNotificationRequests(withIdentifiers: BudgetAlertEvent.notificationIdentifiers)
            return false
        }

        switch await center.authorizationStatus() {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization()) == true
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    func notify(event: BudgetAlertEvent) async {
        guard await canNotify else { return }

        let content = UNMutableNotificationContent()
        content.title = event.notificationTitle
        content.body = event.notificationBody
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: event.notificationIdentifier,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )

        try? await center.add(request)
    }

    private var canNotify: Bool {
        get async {
            switch await center.authorizationStatus() {
            case .authorized, .provisional, .ephemeral:
                true
            case .denied, .notDetermined:
                false
            @unknown default:
                false
            }
        }
    }
}

private struct UserNotificationCenter: UserNotificationCenterProtocol, @unchecked Sendable {
    private let center = UNUserNotificationCenter.current()

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func requestAuthorization() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound])
    }

    func add(_ request: UNNotificationRequest) async throws {
        try await center.add(request)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}

private extension BudgetAlertEvent {
    static var notificationIdentifiers: [String] {
        [BudgetAlertEvent.thresholdReached, .budgetExceeded].map(\.notificationIdentifier)
    }

    var notificationIdentifier: String {
        switch self {
        case .thresholdReached:
            "\(AppConstants.NotificationIdentifier.budgetAlertPrefix)-threshold"
        case .budgetExceeded:
            "\(AppConstants.NotificationIdentifier.budgetAlertPrefix)-exceeded"
        }
    }

    var notificationTitle: String {
        switch self {
        case .thresholdReached:
            "Budget warning"
        case .budgetExceeded:
            "Budget exceeded"
        }
    }

    var notificationBody: String {
        // generic copy avoids leaking category or transaction details in lock-screen notifications.
        "One of your budgets needs attention."
    }
}
