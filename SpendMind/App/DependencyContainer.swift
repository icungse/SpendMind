//
//  DependencyContainer.swift
//  SpendMind
//
//  Created by Icung on 03/07/26.
//

import SwiftUI
import SwiftData

protocol AppDependencyProviding: Sendable {
    var settingsManager: any AppSettingsManagerProtocol { get }
    var dateService: any DateServiceProtocol { get }
    var modelContainer: ModelContainer { get }
}

struct DependencyContainer: AppDependencyProviding {
    let settingsManager: any AppSettingsManagerProtocol
    let dateService: any DateServiceProtocol
    let modelContainer: ModelContainer

    init(
        settingsManager: any AppSettingsManagerProtocol = AppSettingsManager(),
        dateService: any DateServiceProtocol = DateService(),
        modelContainer: ModelContainer = SpendMindModelContainer.app
    ) {
        self.settingsManager = settingsManager
        self.dateService = dateService
        self.modelContainer = modelContainer
    }
}

private struct DependenciesKey: EnvironmentKey {
    static let defaultValue: AppDependencyProviding = DependencyContainer()
}

extension EnvironmentValues {
    var dependencies: AppDependencyProviding {
        get { self[DependenciesKey.self] }
        set { self[DependenciesKey.self] = newValue }
    }
}
