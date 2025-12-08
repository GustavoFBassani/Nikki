//
//  SceneView.swift
//  Nikki
//
//  Created by Gustavo Ferreira bassani on 17/11/25.
//

import RealityKit
import SwiftData
import SwiftUI

struct SceneView: View {
    
    // FIX
    @State var vm = SceneViewModel()
    @State var showCanvas = false
    @State private var isLocalizationMode = false
    
    @Environment(\.modelContext) var context
    //    @Query var pages: [Page]
    
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
                
                // DateBar quando está em modo de localização
                if isLocalizationMode {
                    VStack {
                        Spacer()
                        DateBar()
                            .padding(.bottom, 32)
                    }
                    .transition(.move(edge: .bottom))
                }
                
            }
            .task {
                if vm.scene == nil {
                    await vm.loadScene()
                    vm.repositioningCameraToTree()
                }
                //
                //                    pages.forEach { page in  ///provisorio
                //                        context.delete(page)
                //                    }
                //                    try? context.save()
                
                vm.updateCamera()
                vm.loadMotivation()
            }
            .gesture(
                /// DragGesture permite detectar movimento de um dedo na tela
                /// Usado para rotacionar a câmera orbital
                ///
                /// **Fluxo:**
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
                /// **Fluxo:**
                /// 1. Usuário coloca dois dedos na tela
                /// 2. `onChanged` é chamado enquanto afasta/aproxima os dedos
                /// 3. Calcula a escala acumulada
                /// 4. Passa a escala para o ViewModel calcular nova distância
                /// 5. `onEnded` salva a escala final para o próximo gesto
                MagnificationGesture()
                    .onChanged { value in
                        vm.currentScale = vm.lastScale * value
                        vm.zoom(scale: Float(vm.currentScale))
                    }
                    .onEnded { _ in
                        vm.lastScale = vm.currentScale
                    }
            ) // zoom
            .simultaneousGesture(
                TapGesture()
                    .targetedToAnyEntity()
                    .onEnded { value in
                        vm.handleTap(on: value.entity)
                    }
            ) // tocar no tsuru
            .navigationDestination(item: $vm.openCanvasWithStyle, destination: { style in
                CanvasView(page: vm.currentPage, paperStyle: style, addNewTsuru: vm.addNewTsuru)
            })
            .overlay(alignment: .topTrailing) {
                // Só mostra o + quando:
                // - não está em modo de localização
                // - e o canvas não está aberto
                if !isLocalizationMode && !showCanvas {
                    Menu {
                        ForEach(PaperStyles.allCases, id: \.self) { style in
                            Button(style.name) {
                                vm.openCanvasWithStyle = style.name
                                showCanvas.toggle()
                            }
                        }
                        
                    } label: {
                        Image("customPlus")
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 999)
                                    .fill(Color.white.opacity(0.85))
                            )
                            .padding(.trailing, 20)
                            .padding(.leading, 333)
                            .padding(.top, 26)
                    }
                }
                
            }
            .overlay(alignment: .topLeading) {
                if isLocalizationMode {
                    Button {
                        withAnimation {
                            isLocalizationMode = false
                        }
                    } label: {
                        Image("xCustom")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.85))
                            )
                    }
                    .padding(.leading, 20)
                    .padding(.top, 26)
                }
            }
            .overlay(alignment: .bottomLeading) {
                // Botão de localização só aparece:
                // - quando NÃO está em modo de localização
                // - e quando o canvas NÃO está aberto
                if !isLocalizationMode && !showCanvas {
                    Button {
                        withAnimation {
                            isLocalizationMode = true
                        }
                    } label: {
                        Image(systemName: "location")
                            .foregroundStyle(.blueNikki)
                            .font(Fonts.Footnote)
                            .frame(width: 44, height: 44)
                            .clipShape(Circle())
                            .background(
                                RoundedRectangle(cornerRadius: 999)
                                    .fill(Color.white.opacity(0.85))
                            )
                    }
                    .padding(.leading, 20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(PaperStyles.allCases, id: \.self) { style in
                            Button(style.name) {
                                vm.openCanvasWithStyle = style.rawValue
                            }
                        }
                    } label: {
                        Label("Nova página", systemImage: "plus")
                    }
                }
                if vm.isFocusedOnTsuru {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            vm.repositioningCameraToTree()
                            vm.updateCamera()
                        } label: {
                            Image(systemName: "chevron.left")

                        }
                    }
                }
            }
        }
    }
}
#Preview {
    SceneView()
}
