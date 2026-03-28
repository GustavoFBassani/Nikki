//
//  CanvasViewModel.swift
//  POCCanvas
//
//  Created by Alex Fraga on 14/11/25.
//

import Foundation
import SwiftUI
import SwiftData
import PaperKit
import PhotosUI
import MusicKit
import AVFoundation

@Observable
class CanvasViewModel {
    // MARK: - Services
    private let iTunesService = ITunesService()
    private let dataManager = ScrapService.shared
    let audioRecorder = AudioRecorder()
    private let audioPlayer = AudioPlayer.shared
    private let canvasSize = CGSize(width: 3610, height: 3610)
    
    // MARK: - Editor Data
    var editorData: EditorData
    
    // MARK: - State Properties
    var showTools: Bool = false
    var showImagePicker: Bool = false
    var showITunesSearch = false
    var showAudioRecorder = false
    var showAudioPicker = false
    var showStickers = false
    
    let stickers: [String] = [
            "redLetter",
            "leque",
            "blueDragon",
            "cloud",
            "dragon",
            "envelope",
            "fuji",
            "goldenStar",
            "house",
            "lamp",
            "redEnvelope",
            "moth",
            "orangeFish",
            "star",
      ]
    
    var photoItem: PhotosPickerItem?
    
    // MARK: - Page Reference
    var currentPage: Page?
    
    let paperStyle: String?
    
    // MARK: - Initialization
    init(page: Page? = nil, paperStyle: String?) {
        self.currentPage = page
        self.paperStyle = paperStyle
        self.editorData = EditorData(data: page?.markupData, paperStyle: paperStyle)
    }
    
    func undoAction() {
        editorData.undo()
    }
    
    private func centeredRect(for itemSize: CGSize) -> CGRect {
        let origin = CGPoint(
            x: (canvasSize.width  - itemSize.width)  / 2,
            y: (canvasSize.height - itemSize.height) / 2
        )
        return CGRect(origin: origin, size: itemSize)
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
            let size = CGSize(width: 1000, height: 500)
            let rect = centeredRect(for: size)
            
//            let origin = CGPoint(x: 50, y: 70)
            editorData.insertImage(cardImage, rect: rect)
            
            // Toca o preview
            audioPlayer.play(url: track.previewURL)
        }
    }
    
    //MARK: - Stickers
    func insertSticker(named name: String) {
          guard let image = UIImage(named: name) else { return }
          
          let size = CGSize(width: 800, height: 800)
//          let origin = CGPoint(x: 20, y: 20)
          let rect = centeredRect(for: size)
          
          editorData.insertImage(image, rect: rect)
      }
    
    // MARK: - Persistence Methods
    
    func savePage() async throws {
        let data = await editorData.exportMarkupData()
        let image = await editorData.exportAsImage(CGRect(origin: .zero, size: CGSize(width: 3610, height: 3610)))
        
        let imageData = image?.pngData()
        
        if let page = currentPage {
            page.markupData = data
            page.markupImageData = imageData
            try dataManager.updatePage(page)
        } else {
            let newPage = Page(title: "Nova Página", markupData: data, paperStyle: paperStyle, markupImageData: imageData)
            try dataManager.savePage(newPage)
            currentPage = newPage
        }
    }
    
    func deleteCurrentPage() throws {
        guard let page = currentPage else { return }
        try? dataManager.deletePage(page)
        
        currentPage = nil
    }
    
    // MARK: - Export Methods
    
    /// Export only the image
    func exportImageOnly() async -> UIImage? {
        return await editorData.exportAsImage(CGRect(origin: .zero, size: canvasSize))
    }
    
    /// Export the image with the frame
    func exportWithCanvas() async -> UIImage? {
        guard let exportedImage = await exportImageOnly() else {
            return nil
        }
        
        guard let frameAsset = UIImage(named: "exportCanvas") ?? UIImage(named: "canvasExport") else {
            return exportedImage
        }
        
        let frameSize = frameAsset.size
        let finalImage = UIGraphicsImageRenderer(size: frameSize).image { context in
            let imageRect = CGRect(origin: .zero, size: frameSize)
            
            exportedImage.draw(in: imageRect)
            
            frameAsset.draw(in: CGRect(origin: .zero, size: frameSize))
        }
        
        return finalImage
    }
    
    func shareExportedImage(_ image: UIImage) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first,
              let rootViewController = window.rootViewController else {
            return
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )
        activityViewController.excludedActivityTypes = [
            .print,
            .assignToContact,
            .saveToCameraRoll,
            .markupAsPDF,
            .addToReadingList,
            .collaborationCopyLink,
            .collaborationInviteWithLink,
            .mail,
        ]

        rootViewController.present(activityViewController, animated: true)
    }
    
    // MARK: - Photo Handling
    func handlePhotoSelection() async {
        guard let photoItem = photoItem else { return }
        
        do {
            guard let data = try await photoItem.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                return
            }
            
            let size = CGSize(width: 700, height: 700)
            let rect = centeredRect(for: size)
            
            editorData.insertImage(
                image,
                rect: rect
            )
            self.photoItem = nil
        } catch {
            print("Erro ao carregar foto: \(error)")
        }
    }
    
    func insertDefaultText(_ string: String = "Nikki") {
        let font = UIFont(name: "CaveatBrush-Regular", size: 112)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font ?? UIFont.systemFont(ofSize: 112, weight: .medium)
        ]
        
        let attributed = NSAttributedString(string: string, attributes: attributes)

        let size = CGSize(width: 600, height: 120)
        let rect = centeredRect(for: size)

        editorData.insertText(attributed, rect: rect)
    }
}
