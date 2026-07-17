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
    private let dependencies: AppDependencyProviding
    @State private var settings: AppSettings

    init() {
        let container = DependencyContainer()
        self.dependencies = container
        self._settings = State(initialValue: container.settingsManager.load())

        do {
            try SpendMindModelContainer.seedDefaultCategoriesIfNeeded(in: container.modelContainer.mainContext)
        } catch {
            AppLogger.error("Failed to seed default categories: \(error.localizedDescription)")
        }

        AppLogger.debug("SpendMindApp initialized. Theme loaded: \(self.settings.theme)")
    }

    var body: some Scene {
        WindowGroup {
            ContentView(settings: $settings)
                .environment(\.dependencies, dependencies)
                .modelContainer(dependencies.modelContainer)
                .preferredColorScheme(colorScheme)
                .onChange(of: settings) { _, newValue in
                    dependencies.settingsManager.save(newValue)
                    AppLogger.debug("Settings updated and saved. Theme: \(newValue.theme)")
                }
        }
    }

    private var colorScheme: ColorScheme? {
        switch settings.theme {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

private struct ContentView: View {
    @Environment(\.dependencies) private var dependencies
    @Binding var settings: AppSettings
    @State private var router = AppRouter()
    @State private var showSplash = true

    var body: some View {
        @Bindable var router = router

        Group {
            if showSplash {
                SplashView(isFinished: Binding(
                    get: { !showSplash },
                    set: { showSplash = !$0 }
                ))
            } else {
                NavigationStack(path: $router.path) {
                    rootView
                        .navigationDestination(for: AppRoute.self) { route in
                            destination(for: route)
                        }
                }
                .transition(.opacity)
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
        }
    }

    private var rootView: some View {
        let expenseRepository = SwiftDataExpenseRepository(context: dependencies.modelContainer.mainContext)
        let budgetRepository = SwiftDataBudgetRepository(modelContainer: dependencies.modelContainer)

        return DashboardView(
            viewModel: DashboardViewModel(
                dateService: dependencies.dateService,
                fetchExpensesUseCase: FetchExpensesUseCase(repository: expenseRepository),
                getCurrentBudgetsUseCase: DefaultGetCurrentBudgetsUseCase(
                    budgetRepository: budgetRepository,
                    expenseRepository: expenseRepository
                )
            ),
            settings: $settings
        )
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .dashboard:
            let expenseRepository = SwiftDataExpenseRepository(context: dependencies.modelContainer.mainContext)
            let budgetRepository = SwiftDataBudgetRepository(modelContainer: dependencies.modelContainer)

            DashboardView(
                viewModel: DashboardViewModel(
                    dateService: dependencies.dateService,
                    fetchExpensesUseCase: FetchExpensesUseCase(repository: expenseRepository),
                    getCurrentBudgetsUseCase: DefaultGetCurrentBudgetsUseCase(
                        budgetRepository: budgetRepository,
                        expenseRepository: expenseRepository
                    )
                ),
                settings: $settings
            )
        case .expenses:
            let expenseRepository = SwiftDataExpenseRepository(context: dependencies.modelContainer.mainContext)

            ExpenseListView(
                viewModel: ExpenseListViewModel(
                    fetchExpensesUseCase: FetchExpensesUseCase(
                        repository: expenseRepository
                    ),
                    deleteExpenseUseCase: DeleteExpenseUseCase(
                        repository: expenseRepository
                    )
                ),
                currency: settings.currency
            )
        case .budgets:
            let expenseRepository = SwiftDataExpenseRepository(context: dependencies.modelContainer.mainContext)
            let budgetRepository = SwiftDataBudgetRepository(modelContainer: dependencies.modelContainer)
            let budgetAlertStateRepository = SwiftDataBudgetAlertStateRepository(modelContainer: dependencies.modelContainer)
            let categoryRepository = SwiftDataCategoryRepository(context: dependencies.modelContainer.mainContext)

            BudgetListView(
                viewModel: BudgetListViewModel(
                    getCurrentBudgetsUseCase: DefaultGetCurrentBudgetsUseCase(
                        budgetRepository: budgetRepository,
                        expenseRepository: expenseRepository
                    ),
                    categoryRepository: categoryRepository,
                    currency: settings.currency,
                    budgetAlertStateRepository: budgetAlertStateRepository,
                    budgetNotificationService: dependencies.budgetNotificationService,
                    budgetNotificationsEnabled: settings.isBudgetNotificationsEnabled
                ),
                createBudgetUseCase: DefaultCreateBudgetUseCase(repository: budgetRepository),
                updateBudgetUseCase: DefaultUpdateBudgetUseCase(repository: budgetRepository),
                deleteBudgetUseCase: DefaultDeleteBudgetUseCase(repository: budgetRepository),
                budgetRepository: budgetRepository,
                categoryRepository: categoryRepository
            )
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
    ContentView(settings: .constant(.default))
        .modelContainer(SpendMindModelContainer.preview)
}
