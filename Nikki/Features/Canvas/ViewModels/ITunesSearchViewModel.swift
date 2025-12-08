//
//  ITunesSearchViewModel.swift
//  POCCanvas
//
//  Created by GitHub Copilot on 19/11/25.
//

import Foundation
import SwiftUI

@Observable
class ITunesSearchViewModel {
    // MARK: - Properties
    private let iTunesService = ITunesService()
    
    var searchText = "" {
        didSet {
            // Cancela a busca anterior se existir
            searchTask?.cancel()
            
            // Se o texto estiver vazio, volta para músicas default
            guard !searchText.isEmpty else {
                Task {
                    await loadDefaultTracks()
                }
                return
            }
            
            // Adiciona um debounce de 300ms antes de buscar
            searchTask = Task {
                
                // Verifica se a task não foi cancelada
                guard !Task.isCancelled else { return }
                
                await performSearch()
            }
        }
    }
    
    var tracks: [ITunesTrack] {
        iTunesService.tracks
    }
    var isLoading: Bool {
        iTunesService.isLoading
    }
    var errorMessage: String? {
        iTunesService.errorMessage
    }
    
    private var searchTask: Task<Void, Never>?
    
    // MARK: - Initialization
    init() {
        // Carrega 4 músicas default ao inicializar
        Task {
            await loadDefaultTracks()
        }
    }
    
    // MARK: - Methods
    
    /// Carrega músicas default (Beatles como exemplo)
    private func loadDefaultTracks() async {
        await iTunesService.searchTracks(searchTerm: "Beatles")
    }
    
    /// Realiza a busca com base no texto digitado
    private func performSearch() async {
        await iTunesService.searchTracks(searchTerm: searchText)
    }
    
    /// Limpa os resultados da busca
    func clearSearch() {
        searchTask?.cancel()
        searchText = ""
    }
}
