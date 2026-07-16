//
//  AppConstants.swift
//  SpendMind
//
//  Created by Icung on 05/07/26.
//

import CoreGraphics
import Foundation

enum AppConstants {
    static let appName = "SpendMind"
    static let bundleIdentifier = "dev.spendmind.app"

    enum DeepLink {
        static let scheme = "spendmind"
        static let dashboardHost = "dashboard"
    }

    enum Logging {
        static let debug = "Debug"
        static let error = "Error"
        static let analytics = "Analytics"
        static let performance = "Performance"
    }

    enum SettingsKey {
        static let theme = "settings.theme"
        static let currency = "settings.currency"
        static let localeIdentifier = "settings.localeIdentifier"
        static let isBiometricEnabled = "settings.isBiometricEnabled"
        static let isAIEnabled = "settings.isAIEnabled"
        static let defaultCategoryId = "settings.defaultCategoryId"
        static let isFirstLaunchCompleted = "settings.isFirstLaunchCompleted"
    }

    enum Layout {
        static let minimumControlHeight: CGFloat = 44
    }

    enum Notifications {
        static let expensesDidChange = Notification.Name("expensesDidChange")
        static let expenseDatesKey = "expenseDates"
        static let expenseCategoryIDsKey = "expenseCategoryIDs"
    }
}
