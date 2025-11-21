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
    @State private var showCanvas = false
    
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
                await vm.loadScene()
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
                        if vm.lastPos == .zero {
                            vm.lastPos = value.location
                            return
                        }
                        
                        // Calcula quanto o dedo se moveu desde o último frame
                        // dx: movimento horizontal (+ = direita, - = esquerda)
                        let dx = Float(value.location.x - vm.lastPos.x)
                        // dy: movimento vertical (+ = baixo, - = cima)
                        let dy = Float(value.location.y - vm.lastPos.y)
                        
                        // Envia os deltas para o ViewModel atualizar theta e phi
                        vm.rotate(dx: dx, dy: dy)
                        
                        // Atualiza a última posição para o próximo frame
                        vm.lastPos = value.location
                    }
                    .onEnded { _ in
                        // Reseta a posição quando o usuário solta o dedo
                        // Prepara para o próximo gesto
                        vm.lastPos = .zero
                    }
            )
            .gesture(
                // MARK: - Gesto de Zoom (Pinch)
                
                /// MagnificationGesture detecta movimento de pinça com dois dedos
                /// Usado para controlar a distância da câmera (zoom)
                ///
                /// **Fluxo:**
                /// 1. Usuário coloca dois dedos na tela
                /// 2. `onChanged` é chamado enquanto afasta/aproxima os dedos
                /// 3. No primeiro frame, chama `startZoom()` para salvar distância inicial
                /// 4. Passa a escala para o ViewModel calcular nova distância
                /// 5. `onEnded` reseta a flag quando o usuário solta os dedos
                ///
                /// **Escala:**
                /// - value > 1.0: dedos se afastando (zoom in)
                /// - value < 1.0: dedos se aproximando (zoom out)
                /// - value = 1.0: sem movimento
                MagnificationGesture()
                    .onChanged { value in
                        // Na primeira vez, salva a distância atual como referência
                        if !vm.isZooming {
                            vm.startZoom()
                            vm.isZooming = true
                        }
                        
                        // Envia a escala do gesto para calcular nova distância
                        vm.zoom(scale: Float(value))
                    }
                    .onEnded { _ in
                        // Reseta a flag quando termina o gesto
                        // Prepara para o próximo zoom
                        vm.isZooming = false
                    }
            )
            
            
            // Overlay com botão para acessar o Canvas
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button("Canvas"){
                        showCanvas = true
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
                }
            }
        }
        
        .navigationDestination(isPresented: $showCanvas) {
            PageListView()
        }
    }
}

#Preview {
    SceneView()
}
