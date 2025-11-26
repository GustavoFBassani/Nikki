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
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    //MARK: UI LOGIC States
    @State var showDeleteAlert: Bool = false
    @State var hiddenTabBarToolKit: Bool = true
    @State var showCheckMark: Bool = false
    
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
                .overlay(alignment: .bottom) {
                    if hiddenTabBarToolKit {
                        TabBarToolKit(
                            showPaperKit: {
                                
                            },
                            showPencilTool: {
                                viewModel.showTools.toggle()  // mostra o pencilkit
                                viewModel.editorData.showPencilKitTools(viewModel.showTools) //mostra pencilkit
                                hiddenTabBarToolKit.toggle() //esconde a tabbar
                                showCheckMark.toggle() // mostra tabbar
                            },
                            showImages: { viewModel.showImagePicker.toggle() /*mostra image picker*/},
                            showMusics: { viewModel.showITunesSearch.toggle();  /*mostra music picker*/ },
                            showStickers: { viewModel.showStickers.toggle() /*mostra sticker pickers*/ }
                        )
                    }
                }
        }
        .sheet(isPresented: $viewModel.showITunesSearch) {
            ITunesSearchView { track in viewModel.handleITunesTrackSelection(track) }
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $viewModel.showAudioPicker) {
            AudioPickerSheet(audioRecorder: viewModel.audioRecorder)
                .presentationDetents([.medium])
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
            .presentationDetents([.medium])

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
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button {
                
            } label: { Image(.customGarbage) }
            Button {
                
            } label: { Image(.undo) }
            Button {
                
            } label: { Image(.tsuruBird) }
        }
        if showCheckMark  {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    // Ação do checkmark
                    
                    showCheckMark.toggle() // esconde checkmark
                    hiddenTabBarToolKit.toggle() // mostra tabbar
                    
                    viewModel.showTools.toggle()  // esconde o pencilkit
                    viewModel.editorData.showPencilKitTools(viewModel.showTools) //esconde pencilkit
                    
                } label: {
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
        
    
    //        ToolbarItem {
    //            Menu("Itens") {
    //                Button("Text") {
    //                    viewModel.editorData.insertText(.init("Nikki"), rect: .zero)
    //                }
    //                Button("Image") {
    //                    viewModel.showImagePicker.toggle()
    //                }
    //                Button("iTunes") {
    //                    viewModel.showITunesSearch.toggle()
    //                }
    //                Button("Áudio") {
    //                    viewModel.showAudioRecorder.toggle()
    //                }
    //                Button("Play Audio") {
    //                    viewModel.showAudioPicker = true
    //                }
    //                Button ("Stickers"){
    //                    viewModel.showStickers.toggle()
    //                }
    //                Button("Save") {
    //                    Task {
    //                        do {
    //                            try await viewModel.savePage()
    //                            dismiss()
    //                        } catch {
    //                            print("Erro ao salvar: \(error)")
    //                        }
    //                    }
    //                }
    //                Button(role: .destructive) {
    //                    showDeleteAlert = true
    //                } label: {
    //                    Text("Delete")
    //                }
    //            }
    //        } // BOTAO ITENS
    //TOOLS E ITENS
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
    } //A
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
    

    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(),GridItem()], spacing: 37) {
                    ForEach(stickers, id: \.self) { stickerName in
                        Button {
                            onSelect(stickerName)
                            dismiss()
                        } label: {
                            Image(stickerName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 133, height: 133)
                                .background(.gray.opacity(0.10))
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8).stroke(Color.customStroke, lineWidth: 0.5)
                                )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Carimbos")
//            .navigationTitleFont(<#T##font: UIFont##UIFont#>) COLOCAR A FONTE DE PREFERENCIA AQUIII
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label : {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
        .background(Color.clear)
    }
}

#Preview {
    
    CanvasView()
    
}
