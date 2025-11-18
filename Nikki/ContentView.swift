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

    var body: some View {
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
    }
}

#Preview {
    ContentView()
}
