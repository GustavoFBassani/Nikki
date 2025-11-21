//
//  CanvasViewModel.swift
//  POCCanvas
//
//  Created by Alex Fraga on 14/11/25.
//

import Foundation
import SwiftUI
import PaperKit
import PhotosUI
import MusicKit
import AVFoundation

@Observable
class CanvasViewModel {
    // MARK: - Services
    private let iTunesService = ITunesService()
    private let dataManager = SwiftDataManager.shared
    let audioRecorder = AudioRecorder()
    private let audioPlayer = AudioPlayer.shared
    
    // MARK: - Editor Data
    var editorData: EditorData
    
    // MARK: - State Properties
    var showTools: Bool = false
    var showImagePicker: Bool = false
    var showITunesSearch = false
    var showAudioRecorder = false
    var showAudioPicker = false
    
    var photoItem: PhotosPickerItem?
    
    // MARK: - Page Reference
    var currentPage: Page?
    
    // MARK: - Initialization
    init(page: Page? = nil) {
        self.currentPage = page
        self.editorData = EditorData(data: page?.markupData)
    }
    
    // MARK: - Audio Methods
    func startRecording() {
        audioRecorder.startRecording()
    }
    
    func stopRecording() {
        audioRecorder.stopRecording()
    }
    
    /// Cria um ícone visual para representar áudio
    func createAudioIcon() -> UIImage {
        let size = CGSize(width: 60, height: 60)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            let circleRect = CGRect(origin: .zero, size: size)
            ctx.cgContext.setFillColor(UIColor.systemBlue.cgColor)
            ctx.cgContext.fillEllipse(in: circleRect)
            
            let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
            let mic = UIImage(systemName: "mic.fill", withConfiguration: config)?
                .withTintColor(.white, renderingMode: .alwaysOriginal)
            mic?.draw(in: CGRect(x: 16, y: 16, width: 28, height: 28))
        }
    }
    
    // MARK: - iTunes Methods
    
    /// Processa a seleção de um track do iTunes
    /// - Parameter track: Track selecionado
    func handleITunesTrackSelection(_ track: ITunesTrack) {
        Task {
            // Baixa a capa
            let cover = await iTunesService.downloadArtwork(for: track)
            
            // Cria o card
            let cardImage = iTunesService.createTrackCard(track: track, cover: cover)
            
            // Insere no canvas
            let size = CGSize(width: 250, height: 100)
            let origin = CGPoint(x: 20, y: 20)
            editorData.insertImage(cardImage, rect: CGRect(origin: origin, size: size))
            
            // Toca o preview
            audioPlayer.play(url: track.previewURL)
        }
    }
    
    // MARK: - Persistence Methods
    
    /// Salva ou atualiza a página atual
    func savePage() async throws {
        // Exporta o Data do PaperKit
        let data = await editorData.exportMarkupData()
        
        if let page = currentPage {
            // Atualiza página existente
            page.markupData = data
            try dataManager.updatePage(page)
        } else {
            // Cria nova página
            let newPage = Page(title: "Nova Página", markupData: data)
            try dataManager.savePage(newPage)
            currentPage = newPage
        }
    }
    
    // MARK: - Photo Handling
    
    /// Processa a foto selecionada e insere no editor
    func handlePhotoSelection() async {
        guard let photoItem = photoItem else { return }
        
        do {
            guard let data = try await photoItem.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                return
            }
            
            editorData.insertImage(
                image,
                rect: CGRect(origin: .zero, size: CGSize(width: 100, height: 100))
            )
            self.photoItem = nil
        } catch {
            print("Erro ao carregar foto: \(error)")
        }
    }
}
