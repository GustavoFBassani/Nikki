//
//  ContentView.swift
//  POCCanvas
//
//  Created by Alex Fraga on 06/11/25.
//

import SwiftUI
import PaperKit
import PhotosUI
import MusicKit
import AVFoundation

// MARK: - CanvasView
struct CanvasView: View {
    @State var viewModel: CanvasViewModel
    @State var showDeleteAlert: Bool = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    
    init(page: Page? = nil, paperStyle: String? = nil) {
        _viewModel = State(initialValue: CanvasViewModel(page: page, paperStyle: paperStyle))
    }
    
    var body: some View {
        NavigationStack {
            EditorView(size: .init(width: 3610, height: 3610), data: viewModel.editorData)
                .ignoresSafeArea()
                .toolbar {
                    toolbarContent
                }
        }
        .sheet(isPresented: $viewModel.showITunesSearch) {
            ITunesSearchView { track in
                viewModel.handleITunesTrackSelection(track)
            }
        }
        .sheet(isPresented: $viewModel.showAudioPicker) {
            AudioPickerSheet(audioRecorder: viewModel.audioRecorder)
        }
        .sheet(isPresented: $viewModel.showAudioRecorder) {
            audioRecorderSheet
        }
        .sheet(isPresented: $viewModel.showStickers) {
                 StickersSheet(
                     stickers: viewModel.stickers,
                     onSelect: { stickerName in
                         viewModel.insertSticker(named: stickerName)
                     }
                 )
        }
        .photosPicker(isPresented: $viewModel.showImagePicker, selection: $viewModel.photoItem)
        .onChange(of: viewModel.photoItem) { _, _ in
            Task {
                await viewModel.handlePhotoSelection()
            }
        }
        
        .alert(
            "Delete page?",
            isPresented: $showDeleteAlert
        ) {
            Button("Cancel", role: .cancel) {
            }
            
            Button("Delete", role: .destructive) {
                do {
                    try viewModel.deleteCurrentPage(using: context)
                        dismiss()
                    } catch {
                        print("Failed to delete page: \(error)")
                }
                dismiss()
            }
        } message: {
            Text("This action can't be undone, are you sure you want to delete this page?")
        }

    }
    
    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem {
            Button("Tools") {
                viewModel.showTools.toggle()
                viewModel.editorData.showPencilKitTools(viewModel.showTools)
            }
        }
        
        ToolbarItem {
            Menu("Itens") {
                Button("Text") {
                    viewModel.editorData.insertText(.init("Nikki"), rect: .zero)
                }
                Button("Image") {
                    viewModel.showImagePicker.toggle()
                }
                Button("iTunes") {
                    viewModel.showITunesSearch.toggle()
                }
                Button("Áudio") {
                    viewModel.showAudioRecorder.toggle()
                }
                Button("Play Audio") {
                    viewModel.showAudioPicker = true
                }
                Button ("Stickers"){
                    viewModel.showStickers.toggle()
                }
                Button("Save") {
                    Task {
                        do {
                            try await viewModel.savePage()
                            dismiss()
                        } catch {
                            print("Erro ao salvar: \(error)")
                        }
                    }
                }
                Button(role: .destructive) {
                    showDeleteAlert = true
                } label: {
                    Text("Delete")
                }
            }
        }
    }
    
    // MARK: - Audio Recorder Sheet
    private var audioRecorderSheet: some View {
        VStack(spacing: 16) {
            Text("Gravador de Áudio")
                .font(.title2)
                .padding(.top)
            
            Button("Iniciar Gravação") {
                viewModel.startRecording()
            }
            
            Button("Parar e Inserir") {
                viewModel.stopRecording()
                
                if viewModel.audioRecorder.recordings.last != nil {
                    let image = viewModel.createAudioIcon()
                    let rect = CGRect(origin: .zero, size: CGSize(width: 60, height: 60))
                    viewModel.editorData.insertImage(image, rect: rect)
                }
                
                viewModel.showAudioRecorder = false
            }
        }
        .padding()
    }
}

// MARK: - Audio Picker Sheet
struct AudioPickerSheet: View {
    @State var audioRecorder: AudioRecorder
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(audioRecorder.recordings) { recording in
                    Button(action: {
                        audioRecorder.playRecording(url: recording.url)
                    }) {
                        HStack {
                            Image(systemName: "waveform")
                            Text("Áudio \(recording.sequence + 1)")
                        }
                    }
                }
            }
            .navigationTitle("Escolher Áudio")
        }
    }
}

struct StickersSheet: View {
    let stickers: [String]
    let onSelect: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    private let columns = [
        GridItem(.adaptive(minimum: 80), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(stickers, id: \.self) { stickerName in
                        Button {
                            onSelect(stickerName)
                            dismiss()
                        } label: {
                            Image(stickerName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipped()
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Stickers")
            //   .tint(.white)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") {
                        dismiss()
                    }
                }
            }
        }
    }
}


#Preview {
    Text("Delete")
    .font(.custom("Caveat-Regular", size: 99))
}
