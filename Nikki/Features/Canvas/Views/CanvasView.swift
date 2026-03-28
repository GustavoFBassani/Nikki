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

// MARK: - CanvasView
/// View principal do canvas que permite ao usuário criar e editar páginas com diferentes tipos de conteúdo
/// Suporta: desenho com PencilKit, inserção de imagens, stickers, texto e música
struct CanvasView: View {
    // MARK: - Properties
    @State private var viewModel: CanvasViewModel
    @State private var showDeleteAlert = false
    @State private var isTabBarHidden = true
    @State private var showCheckMark = false
    @State private var showExportMenu = false
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
        NavigationStack {
            editorContent
                .toolbar { toolbarContent }
                .overlay(alignment: .bottom) { tabBarOverlay }
        }
        .preferredColorScheme(.light)
        .toolbarColorScheme(.light, for: .navigationBar)
        .sheet(isPresented: $viewModel.showITunesSearch) { itunesSearchSheet } /*Sheet para buscar músicas no iTunes*/
        .sheet(isPresented: $viewModel.showAudioPicker) { audioPickerSheet } /*Sheet para escolher áudios gravados*/
        .sheet(isPresented: $viewModel.showStickers) { stickersSheet } /*Sheet para escolher stickers/carimbos*/
        .photosPicker(isPresented: $viewModel.showImagePicker, selection: $viewModel.photoItem) /*Photo picker para selecionar imagens da galeria*/
        .onChange(of: viewModel.photoItem) { _, _ in handlePhotoSelection() } /*Observa mudanças na seleção de foto e processa a imagem*/
        .alert("Deletar página?", isPresented: $showDeleteAlert) { deleteAlertButtons } message: { deleteAlertMessage } /*Alerta de confirmação para deletar página*/
        .overlay(alignment: .center) {
            if showExportMenu {
                exportOverlay
            }
        }
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
    
    /// Overlay customizado com opções de export
    @ViewBuilder
    private var exportOverlay: some View {
        ZStack {
            // Fundo semi-transparente
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    showExportMenu = false
                }
            
            // Card com opções
            VStack(spacing: 20) {
                // Header com dismiss
                HStack {
                    Button(action: { showExportMenu = false }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                    }
                    Spacer()
                }
                .padding(.bottom, 10)
                
                // Opções de export
                Button(action: { handleExportImageOnly() }) {
                    Text("Only image")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blueNikki)
                        .cornerRadius(8)
                }
                
                Button(action: { handleExportWithCanvas() }) {
                    Text("Canvas")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blueNikki)
                        .cornerRadius(8)
                }
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(16)
        }
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
        Button("Cancelar", role: .cancel) {}
        Button("Deletar") {
            Task {
                await handleDeletePage()
            }
        }
    }
    
    /// Mensagem do alerta de confirmação de exclusão
    private var deleteAlertMessage: some View {
        Text("Essa ação não pode ser desfeita, você tem certeza que deseja excluir esta página?")
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

                    Button(action: { showExportMenu = true }) {
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
    
    private func handleExportImageOnly() {
        showExportMenu = false
        Task {
            guard let image = await viewModel.exportImageOnly() else {
                return
            }
            viewModel.shareExportedImage(image)
        }
    }
    
    private func handleExportWithCanvas() {
        showExportMenu = false
        Task {
            guard let image = await viewModel.exportWithCanvas() else {
                return
            }
            viewModel.shareExportedImage(image)
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
}

// MARK: - Preview


#Preview {
    Text("Delete")
        .font(.custom("Caveat-Regular", size: 99))
}
