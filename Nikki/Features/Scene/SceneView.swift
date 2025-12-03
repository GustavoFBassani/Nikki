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
        NavigationStack {
            ZStack {
                // realityView para o conteudo 3D
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
                    // gesto de rotacao (arrastar)
                    DragGesture()
                        .onChanged { value in
                            if vm.lastDragPosition == .zero {
                                vm.lastDragPosition = value.location
                                return
                            }
                            
                            let dTheta = Float(value.location.x - vm.lastDragPosition.x)
                            let dPhi   = Float(value.location.y - vm.lastDragPosition.y)
                            
                            vm.rotate(dTheta: dTheta, dPhi: dPhi)
                            vm.lastDragPosition = value.location
                        }
                        .onEnded { _ in
                            vm.lastDragPosition = .zero
                        }
                )
                .gesture(
                    // gesto de zoom (pinça)
                    MagnificationGesture()
                        .onChanged { value in
                            vm.currentScale = vm.lastScale * value
                            vm.zoom(scale: Float(vm.currentScale))
                        }
                        .onEnded { _ in
                            vm.lastScale = vm.currentScale
                        }
                )
            }
            .toolbar {
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
//                                .frame(width: 18, height: 18) // ajuste fino
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
