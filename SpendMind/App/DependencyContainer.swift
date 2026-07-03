//
//  DependencyContainer.swift
//  SpendMind
//
//  Created by Icung on 03/07/26.
//

import SwiftUI

protocol AppDependencyProviding: Sendable { }

struct DependencyContainer: AppDependencyProviding { }

private struct DependenciesKey: EnvironmentKey {
    static let defaultValue: AppDependencyProviding = DependencyContainer()
}

extension EnvironmentValues {
    var dependencies: AppDependencyProviding {
        get { self[DependenciesKey.self] }
        set { self[DependenciesKey.self] = newValue }
    }
}
