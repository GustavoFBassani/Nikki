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
    
    var body: some View {
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
                /// **Fluxo:**
                /// 1. Usuário toca e arrasta
                /// 2. `onChanged` é chamado continuamente durante o movimento
                /// 3. Calcula a diferença entre posição atual e última
                /// 4. Passa os deltas (dx, dy) para o ViewModel rotacionar a câmera
                /// 5. `onEnded` reseta a posição ao soltar o dedo
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
                /// **Fluxo:**
                /// 1. Usuário coloca dois dedos na tela
                /// 2. `onChanged` é chamado enquanto afasta/aproxima os dedos
                /// 3. Calcula a escala acumulada
                /// 4. Passa a escala para o ViewModel calcular nova distância
                /// 5. `onEnded` salva a escala final para o próximo gesto
                MagnificationGesture()
                    .onChanged { value in
                        vm.currentScale = vm.lastScale * value
                        print(vm.currentScale)
                        vm.zoom(scale: Float(vm.currentScale))
                        print("lastscale", vm.lastScale)
                    }
                    .onEnded { _ in
                        vm.lastScale = vm.currentScale
                    }
            ) // zoom
            
        }
        .overlay(alignment: .bottomTrailing) {
            NavigationLink {
                PageListView()
            } label: {
                Text("Canvas")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
            }
        }

    }
}
    
    #Preview {
        SceneView()
    }
