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
    
//    private let pageSize: CGFloat = 1080
//    private let minPageSize: CGFloat = 361
    
    init(page: Page? = nil) {
        _viewModel = State(initialValue: CanvasViewModel(page: page))
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
        .photosPicker(isPresented: $viewModel.showImagePicker, selection: $viewModel.photoItem)
        .onChange(of: viewModel.photoItem) { _, _ in
            Task {
                await viewModel.handlePhotoSelection()
            }
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
                Button("Salvar") {
                    Task {
                        do {
                            try await viewModel.savePage()
                        } catch {
                            print("Erro ao salvar: \(error)")
                        }
                    }
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

