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
    let shareService = ShareService()
    let audioRecorder = AudioRecorder()
    private let audioPlayer = AudioPlayer.shared

    let canvasSize = CGSize(width: 2304, height: 2304)
    let previewExport: CGFloat = 256
    
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

    /// Stops any active preview audio played from iTunes selection.
    func stopAudio() {
        audioPlayer.stop()
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
        let size = CGSize(width: 40, height: 40)
        return UIGraphicsImageRenderer(size: size).image { ctx in
            let circleRect = CGRect(origin: .zero, size: size)
            ctx.cgContext.setFillColor(UIColor.systemBlue.cgColor)
            ctx.cgContext.fillEllipse(in: circleRect)
            
            let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
            let mic = UIImage(systemName: "mic.fill", withConfiguration: config)?
                .withTintColor(.white, renderingMode: .alwaysOriginal)
            mic?.draw(in: CGRect(x: 11, y: 11, width: 18, height: 18))
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
            let size = CGSize(width: 640, height: 320)
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
        
        let size = CGSize(width: 512, height: 512)
        let rect = centeredRect(for: size)
        
        editorData.insertImage(image, rect: rect)
    }
    
    // MARK: - Persistence Methods
    
    func savePage() async throws {
        let data = await editorData.exportMarkupData()
        let fullImage = await editorData.exportAsImage(
            CGRect(origin: .zero, size: canvasSize)
        )

        // Reduces image size to use as texture on tsuru
        let previewImage = fullImage.flatMap { resizeImage($0, maxSide: previewExport) }
        let texturePreviewData = previewImage?.jpegData(compressionQuality: 0.82)
        
        if let page = currentPage {
            page.markupData = data
            page.markupImageData = texturePreviewData
            try dataManager.updatePage(page)
        } else {
            let newPage = Page(
                title: "Nova Página",
                markupData: data,
                paperStyle: paperStyle,
                markupImageData: texturePreviewData
            )
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
    
    /// Exports only the canvas content image, without decorative frame.
    func exportImageOnly() async -> UIImage? {
        return await editorData.exportAsImage(
            CGRect(origin: .zero, size: canvasSize)
        )
    }
    
    /// Exports the canvas merged with the decorative frame used in share flows.
    func exportWithCanvas() async -> UIImage? {
        guard let exportedImage = await exportImageOnly() else {
            return nil
        }
        
        guard let frameAsset = UIImage(named: "exportCanvas") ?? UIImage(named: "canvasExport") else {
            return exportedImage
        }
        
        // Merges the asset with the scrap
        let frameSize = frameAsset.size
        let frameRect = CGRect(origin: .zero, size: frameSize)
        let contentRect = contentRectForFrame(frameRect)
        let cornerRadius = cornerRadiusForFrame(frameRect)

        let format = UIGraphicsImageRendererFormat()
        format.scale = frameAsset.scale
        format.opaque = false

        let finalImage = UIGraphicsImageRenderer(size: frameSize, format: format).image { context in
            let canvasRect = aspectFillRect(for: exportedImage.size, in: contentRect)

            context.cgContext.saveGState()
            UIBezierPath(
                roundedRect: contentRect,
                cornerRadius: cornerRadius
            ).addClip()
            exportedImage.draw(in: canvasRect)
            context.cgContext.restoreGState()

            frameAsset.draw(in: frameRect)
        }
        
        return finalImage
    }

    private func aspectFillRect(for imageSize: CGSize, in container: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else { return container }

        let widthRatio = container.width / imageSize.width
        let heightRatio = container.height / imageSize.height
        let scale = max(widthRatio, heightRatio)

        let fittedSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let origin = CGPoint(
            x: container.midX - fittedSize.width / 2,
            y: container.midY - fittedSize.height / 2
        )

        return CGRect(origin: origin, size: fittedSize)
    }

    private func contentRectForFrame(_ frameRect: CGRect) -> CGRect {
        let insetRatio: CGFloat = 0.064
        return frameRect.insetBy(
            dx: frameRect.width * insetRatio,
            dy: frameRect.height * insetRatio
        )
    }

    private func cornerRadiusForFrame(_ frameRect: CGRect) -> CGFloat {
        let referenceWidth: CGFloat = 768
        let referenceRadius: CGFloat = 4
        return (frameRect.width / referenceWidth) * referenceRadius
    }
    
    // MARK: - Photo Handling
    func handlePhotoSelection() async {
        guard let photoItem = photoItem else { return }
        
        do {
            guard let data = try await photoItem.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                return
            }
            
            let size = CGSize(width: 448, height: 448)
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
        let font = UIFont(name: "CaveatBrush-Regular", size: 72)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font ?? UIFont.systemFont(ofSize: 72, weight: .medium)
        ]
        
        let attributed = NSAttributedString(string: string, attributes: attributes)

        let size = CGSize(width: 384, height: 80)
        let rect = centeredRect(for: size)

        editorData.insertText(attributed, rect: rect)
    }

    // Downscale of canvas image
    private func resizeImage(_ image: UIImage, maxSide: CGFloat) -> UIImage {
        let longestSide = max(image.size.width, image.size.height)
        guard longestSide > maxSide else { return image }

        let ratio = maxSide / longestSide
        let targetSize = CGSize(width: image.size.width * ratio, height: image.size.height * ratio)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false

        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
