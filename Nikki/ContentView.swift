//
//  ContentView.swift
//  Nikki
//
//  Created by Gustavo Ferreira bassani on 17/11/25.
//

import SwiftUI
import RealityKit

struct ContentView : View {
    
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
//        .sheet(isPresented: $showCanvas) {
//            PageListView()
//        }
        .navigationDestination(isPresented: $showCanvas) {
            PageListView()
        }
    }
}

#Preview {
    ContentView()
}
