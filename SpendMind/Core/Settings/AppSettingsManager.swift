//
//  AppSettingsManager.swift
//  SpendMind
//
//  Created by Icung on 05/07/26.
//

import Foundation

protocol AppSettingsManagerProtocol: Sendable {
    func load() -> AppSettings
    func save(_ settings: AppSettings)
}

struct AppSettingsManager: AppSettingsManagerProtocol, @unchecked Sendable {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func load() -> AppSettings {
        let defaults = AppSettings.default

        return AppSettings(
            theme: AppTheme(rawValue: userDefaults.string(forKey: AppConstants.SettingsKey.theme) ?? "") ?? defaults.theme,
            currency: CurrencyCode(rawValue: userDefaults.string(forKey: AppConstants.SettingsKey.currency) ?? "") ?? defaults.currency,
            localeIdentifier: userDefaults.string(forKey: AppConstants.SettingsKey.localeIdentifier) ?? defaults.localeIdentifier,
            isBiometricEnabled: userDefaults.bool(forKey: AppConstants.SettingsKey.isBiometricEnabled),
            isAIEnabled: userDefaults.object(forKey: AppConstants.SettingsKey.isAIEnabled) as? Bool ?? defaults.isAIEnabled,
            defaultCategoryId: defaultCategoryId,
            isFirstLaunchCompleted: userDefaults.bool(forKey: AppConstants.SettingsKey.isFirstLaunchCompleted)
        )
    }

    func save(_ settings: AppSettings) {
        userDefaults.set(settings.theme.rawValue, forKey: AppConstants.SettingsKey.theme)
        userDefaults.set(settings.currency.rawValue, forKey: AppConstants.SettingsKey.currency)
        userDefaults.set(settings.localeIdentifier, forKey: AppConstants.SettingsKey.localeIdentifier)
        userDefaults.set(settings.isBiometricEnabled, forKey: AppConstants.SettingsKey.isBiometricEnabled)
        userDefaults.set(settings.isAIEnabled, forKey: AppConstants.SettingsKey.isAIEnabled)
        userDefaults.set(settings.defaultCategoryId?.uuidString, forKey: AppConstants.SettingsKey.defaultCategoryId)
        userDefaults.set(settings.isFirstLaunchCompleted, forKey: AppConstants.SettingsKey.isFirstLaunchCompleted)
    }

    private var defaultCategoryId: UUID? {
        guard let value = userDefaults.string(forKey: AppConstants.SettingsKey.defaultCategoryId) else {
            return nil
        }

        /// invalid persisted UUID means no default category; add migration only if shipped bad data exists.
        return UUID(uuidString: value)
    }
}
