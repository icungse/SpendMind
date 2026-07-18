//
//  SwiftDataCategoryRepository.swift
//  Veyra
//
//  Created by Icung on 09/07/26.
//

import Foundation
import SwiftData

struct SwiftDataCategoryRepository: CategoryRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func getCategories() throws -> [Category] {
        do {
            return try context.fetch(FetchDescriptor<Category>())
        } catch {
            throw AppError.persistence("Failed to fetch categories: \(error.localizedDescription)")
        }
    }

    func getDefaultCategories() throws -> [Category] {
        let descriptor = FetchDescriptor<Category>(predicate: #Predicate { $0.isSystem })

        do {
            return try context.fetch(descriptor)
        } catch {
            throw AppError.persistence("Failed to fetch default categories: \(error.localizedDescription)")
        }
    }

    func seedDefaultCategoriesIfNeeded() throws {
        do {
            try VeyraModelContainer.seedDefaultCategoriesIfNeeded(in: context)
        } catch {
            throw AppError.persistence("Failed to seed default categories: \(error.localizedDescription)")
        }
    }
}
