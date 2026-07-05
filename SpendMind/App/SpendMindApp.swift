//
//  SpendMindApp.swift
//  SpendMind
//
//  Created by Icung on 03/07/26.
//

import SwiftUI
import SwiftData

@main
struct SpendMindApp: App {
    private let dependencies: AppDependencyProviding = DependencyContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.dependencies, dependencies)
                .modelContainer(SpendMindModelContainer.app)
        }
    }
}

private struct ContentView: View {
    @State private var router = AppRouter()

    var body: some View {
        @Bindable var router = router

        NavigationStack(path: $router.path) {
            rootView
                .navigationDestination(for: AppRoute.self) { route in
                    destination(for: route)
                }
        }
        .sheet(item: $router.modal) { modal in
            modalView(for: modal)
        }
        .fullScreenCover(item: $router.fullScreenCover) { fullScreenCover in
            fullScreenCoverView(for: fullScreenCover)
        }
        .onOpenURL { url in
            router.handleDeepLink(url)
        }
    }

    private var rootView: some View {
        Text(verbatim: AppConstants.appName)
            .accessibilityAddTraits(.isHeader)
    }

    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .dashboard:
            Text(verbatim: AppConstants.appName)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private func modalView(for modal: AppModal) -> some View {
        switch modal {
        case .placeholder:
            Text(verbatim: AppConstants.appName)
                .accessibilityAddTraits(.isHeader)
        }
    }

    private func fullScreenCoverView(for fullScreenCover: AppFullScreenCover) -> some View {
        switch fullScreenCover {
        case .placeholder:
            Text(verbatim: AppConstants.appName)
                .accessibilityAddTraits(.isHeader)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(SpendMindModelContainer.preview)
}
