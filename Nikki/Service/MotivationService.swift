//
//  MotivationService.swift
//  Nikki
//
//  Created by Gustavo Ferreira bassani on 12/12/25.
//
import SwiftData
class MotivationService {
    // MARK: - Singleton
    static let shared = MotivationService()
    
    // MARK: - Properties
    let container: ModelContainer
    let context: ModelContext
    
    private init() {
        do {
            // Versão simples e recomendada
            container = try ModelContainer(for: Motivation.self)
            context = ModelContext(container)
        } catch {
            fatalError("Erro ao criar ModelContainer: \(error)")
        }
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
    
}
