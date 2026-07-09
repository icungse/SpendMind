//
//  CategoryRepository.swift
//  SpendMind
//
//  Created by Icung on 09/07/26.
//

// reuse the current Category type; split domain/persistence models when Data mappers exist.
protocol CategoryRepository {
    func getCategories() throws -> [Category]
    func getDefaultCategories() throws -> [Category]
    func seedDefaultCategoriesIfNeeded() throws
}
