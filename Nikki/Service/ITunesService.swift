//
//  ITunesService.swift
//  POCCanvas
//
//  Created by GitHub Copilot on 19/11/25.
//

import Foundation
import UIKit

/// Service responsável por buscar e gerenciar dados do iTunes
@Observable
class ITunesService {
    // MARK: - Properties
    var tracks: [ITunesTrack] = []
    var isLoading = false
    var errorMessage: String?
    
    // MARK: - Public Methods
    
    /// Realiza busca de músicas no iTunes
    /// - Parameter searchTerm: Termo a ser buscado
    func searchTracks(searchTerm: String) async {
        guard !searchTerm.isEmpty else { return }
        
        let term = searchTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://itunes.apple.com/search?term=\(term)&entity=song&limit=25"
        guard let url = URL(string: urlString) else {
            errorMessage = "URL inválida"
            return
        }
        
        isLoading = true
        tracks = []
        errorMessage = nil
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let result = try? JSONDecoder().decode(ITunesResponse.self, from: data) {
                tracks = result.results.compactMap { dto in
                    guard
                        let previewStr = dto.previewUrl,
                        let previewURL = URL(string: previewStr)
                    else {
                        return nil
                    }
                    
                    let artworkURL = dto.artworkUrl100.flatMap { URL(string: $0) }
                    
                    return ITunesTrack(
                        name: dto.trackName,
                        artist: dto.artistName,
                        artworkURL: artworkURL,
                        previewURL: previewURL
                    )
                }
            }
        } catch {
            errorMessage = "Erro na busca: \(error.localizedDescription)"
            print("Erro na busca iTunes: \(error)")
        }
        
        isLoading = false
    }
    
    /// Baixa a capa de um track
    /// - Parameter track: Track do iTunes
    /// - Returns: Imagem da capa ou nil
    func downloadArtwork(for track: ITunesTrack) async -> UIImage? {
        guard let url = track.artworkURL else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            print("Erro ao baixar capa: \(error)")
            return nil
        }
    }
    
    /// Cria uma imagem de card do iTunes para inserir no canvas
    /// - Parameters:
    ///   - track: Track do iTunes
    ///   - cover: Imagem da capa (opcional)
    /// - Returns: Imagem do card pronta para inserir
    func createTrackCard(track: ITunesTrack, cover: UIImage?) -> UIImage {
        let size = CGSize(width: 615, height: 384)
        
        let cardView = ITunesTrackCardView(track: track, cover: cover)
        
        return cardView.asImage(size: size)
    }
    /// Limpa os resultados da busca
    func clearSearch() {
        tracks = []
        errorMessage = nil
    }
}
