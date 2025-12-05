//
//  SceneView.swift
//  Nikki
//
//  Created by Gustavo Ferreira bassani on 17/11/25.
//

import SwiftUI
import RealityKit

struct SceneView: View {
    
    @State var vm = SceneViewModel()
    @State private var showMotivationPopup = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // RealityView para o conteúdo 3D
                RealityView { content in
                    
                } update: { content in
                    if let scene = vm.scene, content.entities.isEmpty {
                        content.add(scene)
                    }
                }
                .edgesIgnoringSafeArea(.all)
                .task {
                    if vm.scene == nil {
                        await vm.loadScene()
                    }
                }
                .gesture(
                    /// DragGesture permite detectar movimento de um dedo na tela
                    /// Usado para rotacionar a câmera orbital
                    ///
                    /// Fluxo:
                    /// 1. Usuário toca e arrasta
                    /// 2. onChanged é chamado continuamente durante o movimento
                    /// 3. Calcula a diferença entre posição atual e última
                    /// 4. Passa os deltas (dx, dy) para o ViewModel rotacionar a câmera
                    /// 5. onEnded reseta a posição ao soltar o dedo
                    DragGesture()
                        .onChanged { value in
                            // Na primeira chamada, apenas salva a posição inicial
                            if vm.lastDragPosition == .zero {
                                vm.lastDragPosition = value.location
                                return
                            }
                            
                            // Calcula quanto o dedo se moveu desde o último frame
                            // dTheta: movimento horizontal (+ = direita, - = esquerda)
                            let dTheta = Float(value.location.x - vm.lastDragPosition.x)
                            // dPhi: movimento vertical (+ = baixo, - = cima)
                            let dPhi = Float(value.location.y - vm.lastDragPosition.y)
                            
                            // Envia os deltas para o ViewModel atualizar theta e phi
                            vm.rotate(dTheta: dTheta, dPhi: dPhi)
                            // Atualiza a última posição para o próximo frame
                            vm.lastDragPosition = value.location
                        }
                        .onEnded { _ in
                            // Reseta a posição quando o usuário solta o dedo
                            // Prepara para o próximo gesto
                            vm.lastDragPosition = .zero
                        }
                ) // movimentar para o lado
                .gesture(
                    // MARK: - Gesto de Zoom (Pinch)
                    
                    /// MagnificationGesture detecta movimento de pinça com dois dedos
                    /// Usado para controlar a distância da câmera (zoom)
                    ///
                    /// Fluxo:
                    /// 1. Usuário coloca dois dedos na tela
                    /// 2. onChanged é chamado enquanto afasta/aproxima os dedos
                    /// 3. Calcula a escala acumulada
                    /// 4. Passa a escala para o ViewModel calcular nova distância
                    /// 5. onEnded salva a escala final para o próximo gesto
                    MagnificationGesture()
                        .onChanged { value in
                            vm.currentScale = vm.lastScale * value
                            vm.zoom(scale: Float(vm.currentScale))
                        }
                        .onEnded { _ in
                            vm.lastScale = vm.currentScale
                        }
                ) // zoom
                
                // POPUP DE MOTIVAÇÃO
                if showMotivationPopup {
                    motivationPopup
                        .transition(.scale.combined(with: .opacity))
                        .zIndex(1)
                }
            }
            .toolbar {
                // Botão de motivação (abre popup)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showMotivationPopup = true
                    } label: {
                        Label("Motivation", systemImage: "quote.bubble")
                    }
                }
                
                // Botão para ir para o Canvas / PageList
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        PageListView()
                    } label: {
                        Label {
                            Text("New Page")
                        } icon: {
                            Image("customPlus")
                                .resizable()
                                .scaledToFit()
                        }
                    }
                }
            }
        }
        .task {
            // carrega a motivação salva assim que a SceneView aparecer
            vm.loadMotivation()
        }
    }
    
    // MARK: - Popup de Motivação
    
    private var motivationPopup: some View {
        ZStack {
            // Fundo escurecido atrás do card
            Color.black.opacity(0.45)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Text("Why are you writing? \(vm.datadamotivacaodosguri)")
                    .font(.headline)
                
                Text("Describe your motivation. This text stays saved and you can edit it whenever you want.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // TextEditor ligado ao texto do ViewModel
                TextEditor(
                    text: Binding(
                        get: { vm.motivationText },
                        set: { vm.motivationText = $0 }
                    )
                )
                .frame(minHeight: 120, maxHeight: 180)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                )
                .scrollContentBackground(.hidden)
                
                HStack {
                    Button("Cancel") {
                        showMotivationPopup = false
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Save") {
                        vm.saveMotivation()
                        showMotivationPopup = false
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.regularMaterial)
            )
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    SceneView()
}
