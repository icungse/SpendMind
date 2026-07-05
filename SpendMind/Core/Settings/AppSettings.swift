//
//  AppSettings.swift
//  SpendMind
//
//  Created by Icung on 05/07/26.
//

import Foundation

enum AppTheme: String {
    case system
    case light
    case dark
}

enum CurrencyCode: String {
    case IDR
    case USD
    case SGD
    case MYR
    case EUR
    case GBP
}

struct AppSettings: Equatable {
    var theme: AppTheme
    var currency: CurrencyCode
    var localeIdentifier: String
    var isBiometricEnabled: Bool
    var isAIEnabled: Bool
    var defaultCategoryId: UUID?
    var isFirstLaunchCompleted: Bool

    static var `default`: AppSettings {
        AppSettings(
            theme: .system,
            currency: .IDR,
            localeIdentifier: Locale.current.identifier,
            isBiometricEnabled: false,
            isAIEnabled: true,
            defaultCategoryId: nil,
            isFirstLaunchCompleted: false
        )
    }
}
