//
//  SpendMindApp.swift
//  SpendMind
//
//  Created by Icung on 03/07/26.
//

import SwiftUI

@main
struct SpendMindApp: App {
    private let dependencies: AppDependencyProviding = DependencyContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.dependencies, dependencies)
        }
    }
}

private struct ContentView: View {
    var body: some View {
        Text(verbatim: "SpendMind")
            .accessibilityAddTraits(.isHeader)
    }
}

#Preview {
    ContentView()
}
