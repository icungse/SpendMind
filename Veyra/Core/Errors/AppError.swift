//
//  AppError.swift
//  Veyra
//
//  Created by Icung on 05/07/26.
//

import Foundation

enum AppError: Error, Equatable {
    case validation(String)
    case database(String)
    case persistence(String)
    case settings(String)
    case ai(String)
    case unknown(String)

    static func wrap(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }

        return .unknown(error.localizedDescription)
    }
}

extension AppError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .validation(let message),
             .database(let message),
             .persistence(let message),
             .settings(let message),
             .ai(let message),
             .unknown(let message):
            return message
        }
    }
}
