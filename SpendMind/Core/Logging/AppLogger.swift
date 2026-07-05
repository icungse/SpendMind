//
//  AppLogger.swift
//  SpendMind
//
//  Created by Icung on 05/07/26.
//

import OSLog

enum AppLogger {
    private static let subsystem = "dev.spendmind.app"

    private static let debugLogger = Logger(subsystem: subsystem, category: "Debug")
    private static let errorLogger = Logger(subsystem: subsystem, category: "Error")
    private static let analyticsLogger = Logger(subsystem: subsystem, category: "Analytics")
    private static let performanceLogger = Logger(subsystem: subsystem, category: "Performance")

    static func debug(_ message: String) {
        debugLogger.debug("\(message, privacy: .public)")
    }

    static func error(_ message: String) {
        errorLogger.error("\(message, privacy: .public)")
    }
    
    static func analytics(_ message: String) {
        /**
         -- local category only --
         add a real analytics sink only if privacy policy changes.
         **/
        analyticsLogger.info("\(message, privacy: .public)")
    }

    static func performance(_ message: String) {
        performanceLogger.info("\(message, privacy: .public)")
    }
}
