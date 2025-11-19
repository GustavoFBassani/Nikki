//
//  ITunesSearchViewModel.swift
//  POCCanvas
//
//  Created by GitHub Copilot on 19/11/25.
//

import Foundation

@Observable
class ITunesSearchViewModel {
    // MARK: - Properties
    private let iTunesService = ITunesService()
    
    var searchText = ""
    var tracks: [ITunesTrack] {
        iTunesService.tracks
    }
    var isLoading: Bool {
        iTunesService.isLoading
    }
    var errorMessage: String? {
        iTunesService.errorMessage
    }
    
    // MARK: - Methods
    
    /// Realiza a busca com base no texto digitado
    func performSearch() {
        guard !searchText.isEmpty else { return }
        
        Task {
            await iTunesService.searchTracks(searchTerm: searchText)
        }
    }
    
    /// Limpa os resultados da busca
    func clearSearch() {
        iTunesService.clearSearch()
        searchText = ""
    }
}
