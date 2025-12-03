//
//  SceneViewModel.swift
//  Nikki
//
//  Created by Gustavo Ferreira bassani on 17/11/25.
//

import SwiftUI
import RealityKit
import NikkiProject

@MainActor
@Observable
class SceneViewModel {
    
    var scene: Entity?
    
    //MARK: - CAMERA PROPERTIES
    /// Câmera perspectiva usada para visualizar a cena
    var camera: PerspectiveCamera?
    // MARK: - Gesture State
    /// Armazena a última posição do toque durante o gesto de arrastar
    var lastDragPosition: CGPoint = .zero
    /// Escala atual do gesto de zoom
    var currentScale: CGFloat = 1.0
    /// Última escala salva para cálculo relativo
    var lastScale: CGFloat = 1.0
    
    // MARK: - Propriedades da Câmera Orbital
    /// Raio da órbita (ρ) - distância da câmera em relação ao centro da cena
    /// Em coordenadas esféricas, representa a distância radial do centro até o ponto
    private var rho: Float = 10.0
    /// Ângulo azimutal (theta/θ) - rotação horizontal em radianos
    /// Controla a rotação da câmera ao redor do eixo Z (esquerda/direita)
    /// Valores positivos rotacionam no sentido anti-horário visto de cima
    private var theta: Float = 0.0
    /// Ângulo polar (phi/φ) - ângulo em relação ao eixo Z positivo
    /// Controla a elevação da câmera (cima/baixo)
    /// - Valor 0: câmera no polo norte (topo, olhando para baixo)
    /// - Valor π/2: câmera no equador (plano XY)
    /// - Valor π: câmera no polo sul (embaixo, olhando para cima)
    private var phi: Float = Float.pi / 2
    /// Raio base para cálculo de zoom relativo
    /// Deve corresponder ao valor inicial de rho para evitar saltos no primeiro zoom
    private let baseRho: Float = 10.0
    
    // Objects positions
    var obj: Entity?
    
    var tree: Entity?
    
    var data = SwiftDataManager.shared
    var orderedPages: [Page?] = []
    var positions: [SIMD3<Float>] = [
        SIMD3<Float>(-1.7,  0.4, 1.6),
        SIMD3<Float>(-2.8, -0.7, 2.5),
        SIMD3<Float>(-2.6, -0.9, 2.4),
        SIMD3<Float>(-3.1, -0.5, 2.7),
        SIMD3<Float>(-3.4, -0.3, 3.1),
        SIMD3<Float>(-3.6, -0.3, 3.3),
        SIMD3<Float>(-2.8, -0.4, 5.0),
        SIMD3<Float>(-3.2, -0.5, 5.0),
        SIMD3<Float>(-4.1, -0.4, 5.4),
        SIMD3<Float>(-4.1,  0.0, 5.7),
        SIMD3<Float>(-5.1,  1.8, 5.8),
        SIMD3<Float>(-6.0,  1.7, 5.6),
        SIMD3<Float>(-5.8,  1.4, 5.4),
        SIMD3<Float>(-5.3,  0.9, 5.1),
        SIMD3<Float>(-5.1,  0.5, 4.9),
        SIMD3<Float>(-2.0,  0.3, 1.9),
        SIMD3<Float>(-3.09, 0.67, 4.58),
        SIMD3<Float>(-3.0, 0.86, 4.35),
        SIMD3<Float>(-2.87, 1.01, 4.14),
        SIMD3<Float>(-2.79, 1.2, 3.95),
        SIMD3<Float>(-2.69, 1.56, 3.97),
        SIMD3<Float>(-2.66, 1.59, 5.01),
        SIMD3<Float>(-2.35, 1.6, 5.1),
        SIMD3<Float>(-2.36, 1.8, 5.3),
        SIMD3<Float>(-2.2, 1.9, 5.5),
        SIMD3<Float>(-3.38, 0.69, 4.47),
        SIMD3<Float>(-3.23, 0.67, 4.26),
        SIMD3<Float>(-3.04, 0.66, 4.1),
        SIMD3<Float>(-2.78, 0.41, 4.118),
        SIMD3<Float>(-2.54, 0.28, 4.08),
    ]
    var dict: [Entity:Page] = [:]
    var selectedEntityName: Entity? = nil
    var currentPage: Page? = nil
    
    
    func loadScene() async {
        do {
            // Carrega a cena do arquivo Reality Composer Pro ou bundle
            let scene = try await Entity(named: "Scene", in: nikkiProjectBundle)
            self.scene = scene
            tree = scene.findEntity(named: "Cherry_Tree_2")
            
            // Cria uma nova câmera perspectiva
            // PerspectiveCamera simula visão humana com perspectiva realista
            let camera = PerspectiveCamera()
            scene.addChild(camera)
            self.camera = camera
            
            try orderedPages = data.fetchAllPages()
            await loadPages2()
//            await loadPages()
            
            // Posiciona a câmera usando os valores iniciais de theta, phi e distance
            updateCamera()
        } catch {
            print("Erro ao carregar cena: \(error)")
        }
    }
    
    func rotate(dTheta: Float, dPhi: Float) {
        
        // MARK: - Controle de Rotação
        
        /// Rotaciona a câmera orbital baseado no movimento do dedo na tela
        ///
        /// **Parâmetros:**
        /// - `dPhi`: Delta dPhi (movimento horizontal em pixels)
        /// - `dTheta`: Delta dTheta (movimento vertical em pixels)
        ///
        /// **Comportamento (Drag Scene):**
        /// - Arrastar para Direita (dTheta > 0): A cena gira para direita (Câmera orbita para esquerda) -> Theta diminui
        /// - Arrastar para Baixo (dPhi > 0): A cena inclina para baixo (Câmera sobe para o topo) -> Phi diminui
        
        // Atualiza theta (rotação horizontal - Azimute)
        // Invertido (-=) para sensação de "pegar e arrastar" a cena
        theta -= dTheta * 0.01
        
        // Atualiza phi (rotação vertical - Elevação)
        // Invertido (-=) para que arrastar para baixo leve a câmera para o topo (phi -> 0)
        phi -= dPhi * 0.01
        
        // Limita phi entre pi/60 e 57pi/100
        // Phi = 0 é o Polo Norte (Topo)
        phi = max(Float.pi / 6, min(57 * Float.pi / 100, phi))
        
        // Recalcula e aplica a nova posição da câmera
        updateCamera()
    }
    
    func zoom(scale: Float) {
        
        /// Aplica zoom baseado na escala do gesto de pinch
        ///
        /// **Parâmetro:**
        /// - `scale`: Escala do gesto MagnificationGesture
        ///
        /// **Cálculo:**
        /// ```
        /// rho = baseRho / scale
        /// ```
        
        // Calcula novo raio inversamente proporcional à escala
        // Divisão por scale inverte o comportamento: afastar dedos = aproximar câmera
        rho = baseRho / scale
        
        // Limita entre 2 (muito perto) e 20 (muito longe)
        // Evita que a câmera atravesse o objeto ou fique distante demais
        rho = max(2, min(20, rho))
        
        // Recalcula e aplica a nova posição da câmera
        updateCamera()
    }
    
    private func updateCamera() {
            
            // MARK: - Atualização da Câmera
            
            /// **Mapeamento de Eixos:**
            /// - Math X  -> RealityKit X
            /// - Math Y  -> RealityKit Z (Profundidade)
            /// - Math Z  -> RealityKit Y (Altura)
            
            // Garante que a câmera existe antes de tentar atualizar
            guard let camera else { return }
            
            // 1. Cálculo Matemático (Convenção ISO: Z é altura)
            // x = ρ * sin(φ) * cos(θ)
            // y = ρ * sin(φ) * sin(θ)
            // z = ρ * cos(φ)
            
            if let tree {
                
                
                let mathX = rho * sin(phi) * cos(theta) + tree.position.x - 5
                let mathY = rho * sin(phi) * sin(theta) + tree.position.z
                let mathZ = rho * cos(phi) + tree.position.y
                
                
                // posição câmera  ( x  ,   z  ,   y)
                camera.position = [mathX, mathZ, mathY]
                
                // Faz a câmera sempre olhar para o centro da cena (origem 0,0,0)
                camera.look(at: [tree.position.x - 5, tree.position.y, tree.position.z], from: camera.position, relativeTo: nil)
            }
        }
    
    func loadPages() async {
        do {
            guard let scene else {
                print("Cena não carregada")
                return
            }
            
            // Only for placement test
            for i in 0..<positions.count {
                let obj = try await Entity(named: "crane", in: nikkiProjectBundle)
//                print(obj.debugDescription)
                print(obj.scale)
                obj.scale = [0.003,0.003, 0.003]
                obj.position = positions[i]
                scene.addChild(obj)
            }
        }
        catch {
            print("n peguei o obj")
        }
    }
    
    func loadPages2() async {
        do {
            guard let scene else {
                print("Cena não carregada")
                return
            }
            
            
            print(orderedPages.count)
            for i in 0..<orderedPages.count {
                if let page = orderedPages[i] {
                    let obj = try await Entity(named: "crane", in: nikkiProjectBundle)
                    obj.generateCollisionShapes(recursive: true)
                    obj.components[InputTargetComponent.self] = .init()
                    obj.scale = [0.003,0.003, 0.003]
                    obj.position = positions[i]
                    scene.addChild(obj)
                    dict.updateValue(page, forKey: obj)
                }
            }
            
            
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
//    func loadPages() async {
//        do {
//            guard let scene = self.scene else {
//                print("❌ Cena não carregada")
//                return
//            }
//
//
//                while count != 2 {
//                    // Tenta encontrar o marcador pelo nome
//                    guard let marker = scene.findEntity(named: "Slot" + "\(count+1)") else {
//                        print("❌ Marcador Slot1 não encontrado na cena")
//                        return
//                    }
//                    do {
//                        if let page = pages[count] {
//                            // Carrega o objeto (ajuste o nome conforme seu asset)
//                            let obj = try await Entity(named: "Earth", in: nikkiProjectBundle)
//
//                            obj.generateCollisionShapes(recursive: true)
//                            obj.components[InputTargetComponent.self] = .init()
//
//                            // 🟢 Opção 1: Adiciona como filho do marcador (recomendado)
//                            marker.addChild(obj)
//
//                            dic.updateValue(page, forKey: obj)
//
//                            // 🔴 Alternativa (caso prefira adicionar na cena diretamente com posição absoluta):
//                            // obj.transform = marker.transformMatrix(relativeTo: nil)
//                            // scene.addChild(obj)
//                        }
//                    } catch {
//                        print("❌ Erro ao carregar objeto 3D: \(error)")
//                    }
//                    count += 1
//                }
//
//
//
//        }
//    }
    
    func handleTap(on entity: Entity) {
            print("👉 Tocou na entidade: \(entity.name)")
            
            var current: Entity? = entity
            
            // Sobe pela hierarquia até encontrar uma entidade registrada no dicionário
            while let ent = current {
                if let page = dict[ent] {
                    print("✅ Encontrou entidade associada: \(ent.name)")
                    currentPage = page   // <- dispara navegação na View
                    return
                }
                current = ent.parent
            }
            
            print("❌ Nenhuma entidade registrada encontrada na hierarquia")
        }
    
//    func handleTap(on entity: Entity) {
//        print("👉 Tocou na entidade: \(entity.name)")
//
//        var current: Entity? = entity
//
//        // Sobe pela hierarquia até encontrar uma entidade registrada
//        while let ent = current {
//            if let page = dic[ent] {
//                print("✅ Encontrou entidade associada: \(ent.name)")
//                currentPage = nil
//                self.currentPage = page
//                return
//            }
//            current = ent.parent
//        }
//
//        print("❌ Nenhuma entidade registrada encontrada na hierarquia")
//    }

}
