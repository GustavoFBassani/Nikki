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
    @State private var showMotivationRoll = false
    @State private var isEditingMotivation = false
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
                .allowsHitTesting(!showMotivationRoll)
                
            }
            .task {
                if vm.scene == nil {
                    await vm.loadScene()
                    vm.loadMotivation()
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    vm.repositioningCameraToTree()
                    
                }
                
                if DEBUG_SHOULD_DELETE {
                    pages.forEach { page in
                        ///provisorio
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
                        guard !vm.isFocusedOnBandstand else { return }
                        // Na primeira chamada, apenas salva a posição inicial
                        if vm.lastDragPosition == .zero {
                            vm.lastDragPosition = value.location
                            return
                        }
                        
                        // Calcula quanto o dedo se moveu desde o último frame
                        // dTheta: movimento horizontal (+ = direita, - = esquerda)
                        let dTheta = Float(
                            value.location.x - vm.lastDragPosition.x
                        )
                        // dPhi: movimento vertical (+ = baixo, - = cima)
                        let dPhi = Float(
                            value.location.y - vm.lastDragPosition.y
                        )
                        
                        // Envia os deltas para o ViewModel atualizar theta e phi
                        vm.rotate(dTheta: dTheta, dPhi: dPhi)
                        // Atualiza a última posição para o próximo frame
                    }
                    .onEnded { _ in
                        // Reseta a posição quando o usuário solta o dedo
                        // Prepara para o próximo gesto
                        vm.lastDragPosition = .zero
                    }
            )  // movimentar para o lado
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
            .navigationDestination(item: $vm.openCanvasWithStyle, destination: { style in CanvasView(page: vm.currentPage, paperStyle: style, addNewTsuru: vm.parseCanvasDateAndAddNewTsuruAtScene, reloadTsurus: vm.deleteTsurusAtScene)
                
            })
            .navigationDestination(isPresented: $vm.showCredits){ CreditsView() }
            .simultaneousGesture(
                TapGesture()
                    .targetedToAnyEntity()
                    .onEnded { value in
                        vm.handleTap(on: value.entity)
                        Task {
                            vm.isCameraNotMoving = false
                            try? await Task.sleep(nanoseconds: 1_200_000_000)
                            vm.isCameraNotMoving = true
                        }
                    }
            )  // tocar nos objetos
            .onChange(of: vm.isFocusedOnBandstand) { _, newValue in
                if newValue {
                    //focou no coreto
                    showMotivationRoll = false
                    isEditingMotivation = false
                    
                    Task {
                        try? await Task.sleep(nanoseconds: 1_000_500_000)
                        
                        // só mostra se ainda estiver focado no coreto
                        if vm.isFocusedOnBandstand {
                            await MainActor.run {
                                withAnimation(.easeInOut) {
                                    showMotivationRoll = true
                                }
                            }
                        }
                    }
                } else {
                    //saiu do foco no coreto, some na hora
                    withAnimation(.easeOut) {
                        showMotivationRoll = false
                        isEditingMotivation = false
                    }
                }
            }
            .overlay(alignment: .topTrailing) {
                // Só mostra o + quando NÃO está focado no tsuru e NÃO está focado no coreto
                if !(vm.isFocusedOnTsuru || vm.isFocusedOnBandstand) {
                    VStack(alignment: .trailing, spacing: 8) {
                        
                        Menu {
                            ForEach(PaperStyles.allCases, id: \.self) { style in
                                Button {
                                    vm.openCanvasWithStyle = style.name
                                } label: {
                                    Text(style.title)
                                        .font(.custom("CaveatBrush-Regular", size: 5))
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
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 26)
                        
                        // tip popup
                        if vm.showNewPageTip {
                            
                            ZStack(alignment: .topTrailing) {
                                TipView(vm.newPageTip)
                                    .tipViewStyle(BubbleTipStyle())
                                    .tipBackground(.clear)
                                    .padding(.trailing, 16)
                                
                                Button {
                                    vm.dismissNewPageTip()
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.gray)
                                        .padding(8)
                                        .font(.custom("CaveatBrush-Regular", size: 5))
                                }
                                .padding(.trailing, 32)
                                .padding(.top, 20)
                            }
                            
                        }
                        
                    }
                }  else if vm.isFocusedOnTsuru {
                    Button {
                        vm.openTsuru()
                    } label: {
                        Text("Abrir origami")
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
                
            }  //  custom xmark toolbar
            .overlay(alignment: .bottom) {
                if vm.isFocusedOnTsuru {
                    OrigamiSelectorToolBar(
                        selectedDate: vm.selectedPage?.createdAt ?? Date(),
                        thereIsTsuruAtRight: vm.thereIsTsuruAtRight,
                        thereIsTsuruAtLeft: vm.thereIsTsuruAtLeft,
                        navigateToTsuru: vm.navigateToTsuru
                    )
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom))
                }
                
            }  // custom data and chevrons tabbar
            .overlay(alignment: .bottomLeading) {
                if !vm.isFocusedOnTsuru && !vm.isFocusedOnBandstand {
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
                            .offset(x: 18)
                        }
                        
                        Button {
                            if !vm.orderedPages.isEmpty {
                                vm.repositioningCameraToTsuru(vm.pickLastTsuru())
                            }
                            
                            Task {
                                vm.isCameraNotMoving = false
                                try? await Task.sleep(nanoseconds: 700_000_000)
                                vm.isCameraNotMoving = true
                            }
                            
                        } label: {
                            Image(systemName: "location")
                                .foregroundStyle(.blueNikki)
                                .font(Fonts.Footnote)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.white.opacity(0.85)))
                        }
                        .padding(.leading, 20)
                        .disabled(vm.isCamerMovingToTree)
                    }
                } else {

                }
            }
            .overlay {
                if showMotivationRoll {
                    MotivationRoll(
                        motivation: $vm.motivationText,
                        isEditing: isEditingMotivation
                    )
                    .padding(
                        EdgeInsets(
                            top: 423,
                            leading: 46,
                            bottom: 156,
                            trailing: 38
                        )
                    )
                    .contentShape(Rectangle())  // garante área de toque
                    .onTapGesture {
                        withAnimation(.easeInOut) {
                            isEditingMotivation = true
                        }
                    }
                    .zIndex(1)
                }
            }
            .overlay(alignment: .topLeading) {
                if vm.isFocusedOnBandstand || vm.isFocusedOnTsuru {
                    Button {
                        vm.repositioningCameraToTree()
                        vm.isFocusedOnBandstand = false
                        isEditingMotivation = false
                        vm.saveMotivation()
                        
                        Task {
                            vm.isCamerMovingToTree = true
                            try? await Task.sleep(nanoseconds: 1_200_000_000
                            )
                            vm.isCamerMovingToTree = false
                        }
                        
                    } label: {
                        Image("customXmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.85))
                            )
                    }
                    .padding(.leading, 16)
                    .padding(.top, 24)
                    .zIndex(3)
                }
            }
            .sensoryFeedback(.impact, trigger: vm.selectedPage)

        }
        .navigationBarBackButtonHidden(true)
    }
}
    
    #Preview {
        SceneView(vm: SceneViewModel())
    }
