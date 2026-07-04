//
//  SwiftDataRepository.swift
//  SpendMind
//
//  Created by Icung on 04/07/26.
//

import SwiftData

struct SwiftDataRepository<Entity: PersistentModel>: Repository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [Entity] {
        try context.fetch(FetchDescriptor<Entity>())
    }

    func insert(_ entity: Entity) throws {
        context.insert(entity)
        try save()
    }

    func delete(_ entity: Entity) throws {
        context.delete(entity)
        try save()
    }

    func save() throws {
        try context.save()
    }
}
