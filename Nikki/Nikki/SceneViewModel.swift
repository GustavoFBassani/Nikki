//
//  SceneViewModel.swift
//  Nikki
//
//  Created by Gustavo Ferreira bassani on 17/11/25.
//

import SwiftUI
import RealityKit
import NikkiProject

@Observable
class SceneViewModel {
    
    var scene: Entity?
    
    func loadScene() async {
        do {
            self.scene = try await Entity(named: "Scene", in: nikkiProjectBundle)
            print("foi?", scene)
        } catch {
            print("Erro ao carregar a cena: \(error.localizedDescription)")
        }
    }
}
