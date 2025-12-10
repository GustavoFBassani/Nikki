//
//  SceneView.swift
//  Nikki
//
//  Created by Gustavo Ferreira bassani on 17/11/25.
//

import RealityKit
import SwiftData
import SwiftUI
import TipKit

struct SceneView: View {
    
    @State var vm = SceneViewModel()
    @Environment(\.modelContext) var context
            @Query var pages: [Page]
    var DEBUG_SHOULD_DELETE = false
    
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
                
            }
            .task {
                if vm.scene == nil {
                    await vm.loadScene()
                    vm.loadMotivation()
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    vm.repositioningCameraToTree()

                }
                
                if DEBUG_SHOULD_DELETE {
                    pages.forEach { page in  ///provisorio
                        context.delete(page)
                    }
                    try? context.save()
                }
                vm.evaluateTipsVisibility()
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
            .navigationDestination(isPresented: $vm.showCredits){
                CreditsView()
            }
            .overlay(alignment: .topTrailing) {
                
                if !vm.isFocusedOnTsuru {
                    VStack(alignment: .trailing, spacing: 8) {
                        
                    Menu {
                        ForEach(PaperStyles.allCases, id: \.self) { style in
                            Button {
                                vm.openCanvasWithStyle = style.name
                            } label: {
                                Text(style.title)
                                    .font(.custom("CaveatBrush-Regular", size: 5))
                            }
                            
                        } label: {
                            Image("customPlus")
                                .scaledToFit()
                                .frame(width: 44, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 999)
                                        .fill(Color.white.opacity(0.85))
                                )
                        }
                        
                        // tip popup
                        if vm.showNewPageTip {
                            ZStack(alignment: .topTrailing) {
                                TipView(vm.newPageTip)
                                    .tipViewStyle(BubbleTipStyle())
                                    .tipBackground(.clear)
                                
                                Button {
                                    vm.dismissNewPageTip()
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.gray)
                                        .padding(8)
                                }
                                .padding(.trailing, 8)
                                .padding(.top)
                            }
                            .offset(x: 0)
                        }
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 26)   
                    .font(.custom("CaveatBrush-Regular", size: 5))
                } else {
                    Button {
                        vm.openTsuru()
                    } label: {
                        Text("Open origami")
                            .font(Fonts.Footnote)
                            .foregroundColor(.blueNikki)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 999)
                                    .fill(Color.white.opacity(0.85))
                            )
                            .padding(.trailing, 16)
                            .padding(.top, 24)
                    }
                }
                
            } // custom plus toolbar
            .overlay(alignment: .topLeading) {
                if vm.isFocusedOnTsuru {
                    Button {
                        vm.isFocusedOnTsuru = false
                        vm.repositioningCameraToTree()
                        vm.pageControl = 0

                    } label: {
                        Image("xCustom")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .padding(10)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.85))
                            )
                    }
                    .padding(.leading, 16)
                    .padding(.top, 24)
                }
            } //  custom xmark toolbar
            .overlay(alignment: .bottom) {
                if vm.isFocusedOnTsuru {
                    OrigamiSelectorToolBar(selectedDate: vm.selectedPage?.createdAt ?? Date(), thereIsTsuruAtRight: vm.thereIsTsuruAtRight, thereIsTsuruAtLeft: vm.thereIsTsuruAtLeft, navigateToTsuru: vm.navigateToTsuru)
                        .padding(.bottom, 32)
                        .transition(.move(edge: .bottom))
                }
                
            } // custom data and chevrons tabbar
            .overlay(alignment: .bottomLeading) {
                if !vm.isFocusedOnTsuru {
                    VStack(alignment: .leading, spacing: 8) {

                        if vm.showFocusTsuruTip {
                            ZStack(alignment: .topTrailing) {
                                TipView(vm.focusTsuruTip)
                                    .tipViewStyle(BottomLeftBubbleTipStyle())
                                    .tipBackground(.clear)

                                Button {
                                    vm.dismissFocusTsuruTip()
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.gray)
                                        .padding(8)
                                }
                                .padding(.trailing, 8)
                                .padding(.top, 12)
                            }
                        }

                        Button {
                            vm.repositioningCameraToTsuru(nil)
                        } label: {
                            Image(systemName: "location")
                                .foregroundStyle(.blueNikki)
                                .font(Fonts.Footnote)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.white.opacity(0.85)))
                        }
                    }
                    .padding(.leading, 16)
                    .padding(.bottom, 24)
                }
            } // focar nos tsurus
        }
    }
}
#Preview {
    SceneView(vm: SceneViewModel())
}
