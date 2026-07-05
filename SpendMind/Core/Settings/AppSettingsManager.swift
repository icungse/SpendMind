//
//  AppSettingsManager.swift
//  SpendMind
//
//  Created by Icung on 05/07/26.
//

import Foundation

struct AppSettingsManager {
    private enum Key {
        static let theme = "settings.theme"
        static let currency = "settings.currency"
        static let localeIdentifier = "settings.localeIdentifier"
        static let isBiometricEnabled = "settings.isBiometricEnabled"
        static let isAIEnabled = "settings.isAIEnabled"
        static let defaultCategoryId = "settings.defaultCategoryId"
        static let isFirstLaunchCompleted = "settings.isFirstLaunchCompleted"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> AppSettings {
        let defaults = AppSettings.default

        return AppSettings(
            theme: AppTheme(rawValue: userDefaults.string(forKey: Key.theme) ?? "") ?? defaults.theme,
            currency: CurrencyCode(rawValue: userDefaults.string(forKey: Key.currency) ?? "") ?? defaults.currency,
            localeIdentifier: userDefaults.string(forKey: Key.localeIdentifier) ?? defaults.localeIdentifier,
            isBiometricEnabled: userDefaults.bool(forKey: Key.isBiometricEnabled),
            isAIEnabled: userDefaults.object(forKey: Key.isAIEnabled) as? Bool ?? defaults.isAIEnabled,
            defaultCategoryId: defaultCategoryId,
            isFirstLaunchCompleted: userDefaults.bool(forKey: Key.isFirstLaunchCompleted)
        )
    }

    func save(_ settings: AppSettings) {
        userDefaults.set(settings.theme.rawValue, forKey: Key.theme)
        userDefaults.set(settings.currency.rawValue, forKey: Key.currency)
        userDefaults.set(settings.localeIdentifier, forKey: Key.localeIdentifier)
        userDefaults.set(settings.isBiometricEnabled, forKey: Key.isBiometricEnabled)
        userDefaults.set(settings.isAIEnabled, forKey: Key.isAIEnabled)
        userDefaults.set(settings.defaultCategoryId?.uuidString, forKey: Key.defaultCategoryId)
        userDefaults.set(settings.isFirstLaunchCompleted, forKey: Key.isFirstLaunchCompleted)
    }

    private var defaultCategoryId: UUID? {
        guard let value = userDefaults.string(forKey: Key.defaultCategoryId) else {
            return nil
        }

        /// invalid persisted UUID means no default category; add migration only if shipped bad data exists.
        return UUID(uuidString: value)
    }
}
