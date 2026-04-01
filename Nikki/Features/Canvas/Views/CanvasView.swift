//
//  CanvasView.swift
//  Nikki
//
//  Created by Alex Fraga on 06/11/25.
//

import SwiftUI
import PaperKit
import PhotosUI
import MusicKit
import AVFoundation
import UIKit

// MARK: - CanvasView
/// View principal do canvas que permite ao usuário criar e editar páginas com diferentes tipos de conteúdo
/// Suporta: desenho com PencilKit, inserção de imagens, stickers, texto e música
struct CanvasView: View {
    private enum PendingShareAction {
        case otherApps(UIImage)
        case messages(UIImage)
    }

    // MARK: - Properties
    @State private var viewModel: CanvasViewModel
    @State private var showDeleteAlert = false
    @State private var isTabBarHidden = true
    @State private var showCheckMark = false
    @State private var isPreparingShare = false
    @State private var showCustomShare = false
    @State private var pendingShareAction: PendingShareAction?
    @State private var exportedImageToShare: UIImage?
    @State private var showShareFeedback = false
    @State private var shareFeedbackMessage = ""
    @Environment(\.dismiss) private var dismiss
    var addNewTsuru: () async -> Void
    var reloadTsurus: () async -> Void
    var isPageNil: Bool = false
    
    // appear and dissapear
    // MARK: - Initialization
    
    /// Inicializa a view do canvas
    /// - Parameters:
    ///   - page: Página existente para edição (opcional)
    ///   - paperStyle: Estilo do papel de fundo (opcional)
    
    init(page: Page? = nil, paperStyle: String? = nil, addNewTsuru: @escaping () async -> Void, reloadTsurus: @escaping () async -> Void) {
        if page == nil {
            isPageNil = true
        }
        _viewModel = State(initialValue: CanvasViewModel(page: page, paperStyle: paperStyle))
        self.addNewTsuru = addNewTsuru
        self.reloadTsurus = reloadTsurus
    }
    
    // MARK: - Body
    var body: some View {
        editorContent
            .toolbar { toolbarContent }
            .overlay(alignment: .bottom) { tabBarOverlay }
        .preferredColorScheme(.light)
        .toolbarColorScheme(.light, for: .navigationBar)
        .sheet(isPresented: $viewModel.showITunesSearch) { itunesSearchSheet } /*Sheet para buscar músicas no iTunes*/
        .sheet(isPresented: $viewModel.showAudioPicker) { audioPickerSheet } /*Sheet para escolher áudios gravados*/
        .sheet(isPresented: $viewModel.showStickers) { stickersSheet } /*Sheet para escolher stickers/carimbos*/
        .sheet(isPresented: $showCustomShare, onDismiss: handleShareSheetDismiss) {
            customShareSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(24)
        }
        .photosPicker(isPresented: $viewModel.showImagePicker, selection: $viewModel.photoItem) /*Photo picker para selecionar imagens da galeria*/
        .onChange(of: viewModel.photoItem) { _, _ in handlePhotoSelection() } /*Observa mudanças na seleção de foto e processa a imagem*/
        .onDisappear { handleCanvasExit() }
        .alert("Delete page?", isPresented: $showDeleteAlert) { deleteAlertButtons } message: { deleteAlertMessage } /*Alerta de confirmação para deletar página*/
        .overlay(alignment: .center) {
            if isPreparingShare {
                ZStack {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()

                    ProgressView("Preparing share...")
                        .padding(16)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .alert("Share", isPresented: $showShareFeedback) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(shareFeedbackMessage)
        }
        // Disables swipe back to dismiss screen. If it wasnt disabled some draws with the pencil tools might dismiss the screen
        .background(DisableCanvasBackSwipe())
    }
    
    // MARK: - View Components
    
    /// View principal do editor PaperKit com tamanho fixo de 3610x3610
    private var editorContent: some View {
        EditorView(size: CGSize(width: 3610, height: 3610), data: viewModel.editorData)
            .ignoresSafeArea()
    }
    
    /// Overlay que exibe a barra de ferramentas na parte inferior da tela
    /// Oculta quando o usuário está usando a ferramenta de desenho
    @ViewBuilder
    private var tabBarOverlay: some View {
        if isTabBarHidden {
            TabBarToolKit(
                showTextEditor: handleTextEditor,      // Adiciona texto ao canvas
                showPencilTool: handlePencilTool,      // Ativa a ferramenta de desenho
                showImages: { viewModel.showImagePicker.toggle() },     // Abre o seletor de imagens
                showMusics: { viewModel.showITunesSearch.toggle() },    // Abre a busca de músicas
                showStickers: { viewModel.showStickers.toggle() }       // Abre a seleção de stickers
            )
        }
    }

    @ViewBuilder
    private var customShareSheet: some View {
        ShareSheet(
            onStories: { handleShareToStories() },
            onMessages: { handleShareToMessages() },
            onSaveImage: { handleSaveImage() },
            onShareOtherApps: { handleShareWithOtherApps() }
        )
    }
    
    /// Sheet de busca do iTunes para adicionar músicas ao canvas
    private var itunesSearchSheet: some View {
        ITunesSearchView { track in
            viewModel.handleITunesTrackSelection(track)
        }
        .presentationDetents([.medium])
    }
    
    /// Sheet para selecionar áudios previamente gravados
    private var audioPickerSheet: some View {
        AudioPickerSheet(audioRecorder: viewModel.audioRecorder)
            .presentationDetents([.medium])
    }
    
    /// Sheet para selecionar stickers/carimbos e adicionar ao canvas
    private var stickersSheet: some View {
        StickersSheet(
            stickers: viewModel.stickers,
            onSelect: { stickerName in
                viewModel.insertSticker(named: stickerName)
            }
        )
        .presentationDetents([.medium])
    }
    
    /// Botões do alerta de confirmação de exclusão
    @ViewBuilder
    private var deleteAlertButtons: some View {
        Button("Cancel", role: .cancel) {}
        Button("Delete") {
            Task {
                await handleDeletePage()
            }
        }
    }
    
    /// Mensagem do alerta de confirmação de exclusão
    private var deleteAlertMessage: some View {
        Text("This action cannot be undone. Are you sure you want to delete this page?")
    }
    
    // MARK: - Toolbar
    
    /// Toolbar superior com ações principais: deletar, desfazer e salvar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button(role: .destructive, action: { showDeleteAlert = true }) {
                        Image(.customGarbage)
                    }

                    // Botão para desfazer última ação (TODO: implementar funcionalidade)
                    Button(action: handleUndo) {
                        Image(.undo)
                    }

                    Button(action: { handleShareButtonTap() }) {
                        Image("shareCustom")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25, height: 25)
                    }

                    Button(action: handleSave) {
                        Image(.tsuruBird)
                            .accessibilityIdentifier("canvas_save_button")
                    }
                }
            }
            
            // Botão de confirmação que aparece quando a ferramenta de desenho está ativa
            // Ao clicar, fecha a ferramenta de desenho e mostra a TabBar novamente
            if showCheckMark {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: handleCheckMark) {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.white)
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)
                    .clipShape(Circle())
                }
            }
    }
    
    // MARK: - Actions
    
    /// Insere um texto padrão "Nikki" no canvas
    /// TODO: Implementar editor de texto customizável
    private func handleTextEditor() {
        viewModel.insertDefaultText()
    }
    
    /// Ativa/desativa a ferramenta de desenho PencilKit
    /// Ao ativar: oculta a TabBar e mostra o botão de checkmark
    /// Mostra as ferramentas de desenho do PencilKit
    private func handlePencilTool() {
        viewModel.showTools.toggle()
        viewModel.editorData.showPencilKitTools(viewModel.showTools)
        isTabBarHidden.toggle()
        showCheckMark.toggle()
    }
    
    /// Confirma o fim do uso da ferramenta de desenho
    /// Oculta o checkmark, mostra a TabBar e fecha as ferramentas do PencilKit
    private func handleCheckMark() {
        showCheckMark.toggle()
        isTabBarHidden.toggle()
        viewModel.showTools.toggle()
        viewModel.editorData.showPencilKitTools(viewModel.showTools)
    }
    
    /// Desfaz a última ação no canvas
    /// TODO: Implementar funcionalidade de undo
    private func handleUndo() {
        viewModel.undoAction()
    }
    
    private func handleShareButtonTap() {
        guard !isPreparingShare else { return }
        isPreparingShare = true

        Task {
            defer { isPreparingShare = false }

            guard let image = await viewModel.exportWithCanvas() else {
                shareFeedbackMessage = "It was not possible to export the scrap."
                showShareFeedback = true
                return
            }

            presentShareMenu(with: image)
        }
    }

    private func presentShareMenu(with image: UIImage) {
        exportedImageToShare = image
        showCustomShare = true
    }

    private func handleSaveImage() {
        guard let image = exportedImageToShare else { return }

        viewModel.shareService.saveImageToLibrary(image) { success in
            shareFeedbackMessage = success ? "Image saved to Photos" : "Unable to save image. Check Photos permission"
            showShareFeedback = true
        }
    }

    private func handleShareWithOtherApps() {
        guard let image = exportedImageToShare else { return }
        showCustomShare = false
        pendingShareAction = .otherApps(image)
    }

    private func handleShareToStories() {
        guard let image = exportedImageToShare else { return }
        let openedInstagram = viewModel.shareService.shareToInstagramStories(image)

        showCustomShare = false

        if openedInstagram {
            return
        }

        shareFeedbackMessage = "It was not possible to open Instagram. Please, try again later."
        showShareFeedback = true
    }

    private func handleShareToMessages() {
        guard let image = exportedImageToShare else { return }

        showCustomShare = false
        pendingShareAction = .messages(image)
    }

    private func handleShareSheetDismiss() {
        guard let pendingShareAction else { return }
        self.pendingShareAction = nil

        switch pendingShareAction {
        case .otherApps(let image):
            viewModel.shareService.shareWithOtherApps(image)
        case .messages(let image):
            let openedComposer = viewModel.shareService.shareToMessages(image)
            if !openedComposer {
                shareFeedbackMessage = "It was not possible to open Messages. Please, try again later."
                showShareFeedback = true
            }
        }
    }
    
    /// Salva a página atual no SwiftData e fecha a view
    /// Executa de forma assíncrona e trata possíveis erros
    private func handleSave() {
        Task {
            do {
                
                try await viewModel.savePage()
                if isPageNil {
                    await addNewTsuru()
                }
                dismiss()
            
            } catch {
                print("Error saving page: \(error)")
            }
        }
    }
    
    /// Deleta a página atual do banco de dados
    /// Chamado após confirmação do usuário no alerta
    private func handleDeletePage() async {
        do {
            try viewModel.deleteCurrentPage()
            await reloadTsurus()
            dismiss()
        } catch {
            print("Failed to delete page: \(error)")
        }
    }
    
    /// Processa a foto selecionada pelo usuário
    /// Converte para UIImage e insere no canvas
    private func handlePhotoSelection() {
        Task {
            await viewModel.handlePhotoSelection()
        }
    }

    /// Called when leaving canvas to avoid audio leaking into previous screens.
    private func handleCanvasExit() {
        viewModel.stopPreviewAudio()
    }
}

// MARK: - Preview


#Preview {
    Text("Delete")
        .font(.custom("Caveat-Regular", size: 99))
}
