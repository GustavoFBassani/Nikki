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
    private init() {
        do {
            // Versão simples e recomendada
            container = try ModelContainer(for: Page.self, Motivation.self)
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
    
    // MARK: - CRUD de Motivation
        
        /// Busca a motivacao salva (caso exista).
        /// Como a ideia é ter uma motivacao única, sempre usamos o primeiro registro.
        func fetchMotivation() throws -> Motivation? {
            let descriptor = FetchDescriptor<Motivation>()
            return try context.fetch(descriptor).first
        }
        
        /// Salva uma nova motivacao
        /// Usar quando ainda não existe nenhuma Motivation no banco.
        func saveMotivation(_ motivation: Motivation) throws {
            context.insert(motivation)
            try context.save()
        }
        
        /// Atualiza a motivacao existente.
        /// Como o objeto ja está no contexto, basta alterar as propriedades e chamar esse metodo
        func updateMotivation(_ motivation: Motivation) throws {
            try context.save()
        }
        
        /// Deleta a motivaçao
        func deleteMotivation(_ motivation: Motivation) throws {
            context.delete(motivation)
            try context.save()
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
