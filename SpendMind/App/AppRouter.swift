//
//  AppRouter.swift
//  SpendMind
//
//  Created by Icung on 03/07/26.
//

import Foundation
import Observation

enum AppRoute: Hashable {
    case dashboard
    case expenses
}

enum AppModal: Identifiable {
    case placeholder

    var id: String {
        switch self {
        case .placeholder:
            "placeholder"
        }
    }
}

enum AppFullScreenCover: Identifiable {
    case placeholder

    var id: String {
        switch self {
        case .placeholder:
            "placeholder"
        }
    }
}

@Observable
final class AppRouter {
    var path: [AppRoute] = []
    var modal: AppModal?
    var fullScreenCover: AppFullScreenCover?

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func pop() {
        guard !path.isEmpty else { return }

        path.removeLast()
    }

    func popToRoot() {
        path.removeAll()
    }

    func presentModal(_ modal: AppModal) {
        self.modal = modal
    }

    func dismissModal() {
        modal = nil
    }

    func presentFullScreenCover(_ fullScreenCover: AppFullScreenCover) {
        self.fullScreenCover = fullScreenCover
    }

    func dismissFullScreenCover() {
        fullScreenCover = nil
    }

    func handleDeepLink(_ url: URL) {
        guard url.scheme == AppConstants.DeepLink.scheme else { return }

        switch url.host {
        case AppConstants.DeepLink.dashboardHost:
            popToRoot()
            push(.dashboard)
        default:
            break
        }
    }
}
