//
//  MotivationViewModel.swift
//  Nikki
//
//  Created by Rafael Toneto on 03/12/25.
//

import Foundation
import SwiftData

@Observable
class MotivationViewModel {

    private let dataManager = SwiftDataManager.shared
        
    // Objeto Motivation que veio do banco (se ja existir um)
    private(set) var currentMotivation: Motivation?
    
    var motivationText: String = ""
    
    // Ultima data de atualizacao
    var lastUpdated: Date?
    
    // Flags de estado
    var isLoading: Bool = false
    var errorMessage: String?
    
    
    init() { }
    
    // MARK: - Public Methods
    
    func loadMotivation() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let motivation = try dataManager.fetchMotivation()
            currentMotivation = motivation
            motivationText = motivation?.text ?? ""
            lastUpdated = motivation?.updatedAt
        } catch {
            errorMessage = "Não foi possível carregar sua motivação."
            print("Erro ao buscar Motivation: \(error)")
        }
        
        isLoading = false
    }
    
    // Se ja existir uma Motivation, atualiza.
    // Se nao existir, cria uma nova.
    func saveMotivation() async {
        let trimmed = motivationText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }
        
        errorMessage = nil
        let now = Date()
        
        do {
            if let motivation = currentMotivation {
                // atualiza motivacao existente
                motivation.text = trimmed
                motivation.updatedAt = now
                try dataManager.updateMotivation(motivation)
                lastUpdated = motivation.updatedAt
            } else {
                // cria um novo
                let newMotivation = Motivation(text: trimmed, updatedAt: now)
                try dataManager.saveMotivation(newMotivation)
                currentMotivation = newMotivation
                lastUpdated = now
            }
        } catch {
            errorMessage = "Não foi possível salvar sua motivação."
            print("Erro ao salvar Motivation: \(error)")
        }
    }
    
    // remove a motivacao do banco
    func deleteMotivation() async {
        guard let motivation = currentMotivation else { return }
        
        errorMessage = nil
        
        do {
            try dataManager.deleteMotivation(motivation)
            currentMotivation = nil
            motivationText = ""
            lastUpdated = nil
        } catch {
            errorMessage = "Não foi possível apagar sua motivação."
            print("Erro ao apagar Motivation: \(error)")
        }
    }
}
