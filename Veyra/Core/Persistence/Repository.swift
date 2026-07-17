//
//  Repository.swift
//  Veyra
//
//  Created by Icung on 04/07/26.
//

protocol Repository {
    associatedtype Entity

    func fetchAll() throws -> [Entity]
    func insert(_ entity: Entity) throws
    func delete(_ entity: Entity) throws
    func save() throws
}
