//
//  SpendMindModelContainer.swift
//  SpendMind
//
//  Created by Icung on 04/07/26.
//

import SwiftData

enum SpendMindModelContainer {
    static let app: ModelContainer = makeContainer(isStoredInMemoryOnly: false)

    static let preview: ModelContainer = makeContainer(isStoredInMemoryOnly: true)

    static func test() throws -> ModelContainer {
        try createContainer(isStoredInMemoryOnly: true)
    }

    private static func makeContainer(isStoredInMemoryOnly: Bool) -> ModelContainer {
        do {
            return try createContainer(isStoredInMemoryOnly: isStoredInMemoryOnly)
        } catch {
            preconditionFailure("Failed to create SwiftData container: \(error)")
        }
    }

    private static func createContainer(isStoredInMemoryOnly: Bool) throws -> ModelContainer {
        let schema = Schema([])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isStoredInMemoryOnly)

        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
