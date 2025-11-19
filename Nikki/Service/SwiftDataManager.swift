//
//  SwiftDataManager.swift
//  POCCanvas
//
//  Created by GitHub Copilot on 19/11/25.
//

import Foundation
import SwiftData

/// Gerenciador singleton para operações com SwiftData
@Observable
class SwiftDataManager {
    // MARK: - Singleton
    static let shared = SwiftDataManager()
    
    // MARK: - Properties
    let container: ModelContainer
    let context: ModelContext
    
    // MARK: - Initialization
//    private init() {
//        do {
//            // Configura o container do SwiftData
//            let schema = Schema([Page.self])
//            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
//            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
//            context = ModelContext(container)
//        } catch {
//            fatalError("Erro ao criar ModelContainer: \(error)")
//        }
//    }
    private init() {
        do {
            // Versão simples e recomendada
            container = try ModelContainer(for: Page.self)
            context = ModelContext(container)
        } catch {
            fatalError("Erro ao criar ModelContainer: \(error)")
        }
    }
    
    // MARK: - CRUD Operations
    
    /// Salva uma nova página
    /// - Parameter page: Página a ser salva
    func savePage(_ page: Page) throws {
        context.insert(page)
        try context.save()
    }
    
    /// Atualiza uma página existente
    /// - Parameter page: Página a ser atualizada
    func updatePage(_ page: Page) throws {
        try context.save()
    }
    
    /// Deleta uma página
    /// - Parameter page: Página a ser deletada
    func deletePage(_ page: Page) throws {
        context.delete(page)
        try context.save()
    }
    
    /// Busca todas as páginas
    /// - Returns: Array de páginas ordenadas por data de criação
    func fetchAllPages() throws -> [Page] {
        let descriptor = FetchDescriptor<Page>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try context.fetch(descriptor)
    }
    
    /// Busca uma página por ID
    /// - Parameter id: UUID da página
    /// - Returns: Página encontrada ou nil
    func fetchPage(by id: UUID) throws -> Page? {
        let descriptor = FetchDescriptor<Page>(predicate: #Predicate { page in
            page.id == id
        })
        return try context.fetch(descriptor).first
    }
    
    /// Salva o contexto atual (útil para updates em lote)
    func saveContext() throws {
        if context.hasChanges {
            try context.save()
        }
    }
    
    /// Desfaz mudanças não salvas
    func rollbackContext() {
        context.rollback()
    }
}
