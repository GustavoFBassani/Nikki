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
    
    //MARK: -SCENE ENTITIES
    var scene: Entity?
    var tree: Entity?
    var scrapImage: UIImage?
    var PaperStyle: String?
    var tsuru: Entity?
    
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
    
    var tsurus: [Entity] = []
    var count: Float = 1.0
    func loadScene() async {
        do {
            // Carrega a cena do arquivo Reality Composer Pro ou bundle
            let scene = try await Entity(named: "Scene", in: nikkiProjectBundle)
            self.scene = scene
            
            tree = scene.findEntity(named: "Cherry_Tree_2")
            tsuru = scene.findEntity(named: "tsuru")
            
//            await appliyngTextureToTsuru(scrapImage: nil)
            // Cria uma nova câmera perspectiva
            // PerspectiveCamera simula visão humana com perspectiva realista
            let camera = PerspectiveCamera()
            scene.addChild(camera)
            self.camera = camera
            
            // Posiciona a câmera usando os valores iniciais de theta, phi e distance
            updateCamera()
        } catch {
            print("Erro ao carregar cena: \(error)")
        }
    }
    
    //MARK: - ENTITIES ANIMATIONS
    func playTsuruAnimation() {
        if let tsuruAnimation = tsuru?.availableAnimations.first {
            
            tsuru?.playAnimation(tsuruAnimation, transitionDuration: 0.3, startsPaused: false)
        }
    }
    
    
    func addNewTsuru() {
        guard let  flapBird = tsuru?.children.first(where: { $0.name == "flappingBird___0PercentFolded" }),
              let scene = scene else { return }
        
        flapBird.scale = [0.0005,0.0005,0.0005]
        
        let newTsuru = flapBird.clone(recursive: true)
        count += 1
        newTsuru.position.z += count  // Simplesmente ajusta o Z


        tsurus.append(newTsuru)
        
        tsurus.forEach { ent in
            scene.addChild(ent)
        }
        
        print("flapBird position: ", flapBird.position)
        print("new tsuru position: ", newTsuru.position)
        print("is enabled: ",newTsuru.isEnabled)
        print("is active: ", newTsuru.isActive)
    }
    
    func appliyngTextureToTsuru(scrapImage: UIImage?) async {
        
        let sourceImage: UIImage? = scrapImage ?? UIImage(named: "teste")
        guard let cgImage = sourceImage?.cgImage else {
            print("[SceneViewModel] No image available to create texture.")
            return
        }

        // Create material with the texture
        do {
            let texture = try await TextureResource(image: cgImage, options: .init(semantic: .color))
            var material = PhysicallyBasedMaterial()
            
            
            let rotationRadians =   Float.pi // 180 degrees converted to radians.
            material.textureCoordinateTransform = .init(rotation: rotationRadians)
            material.baseColor = .init(tint: .white, texture: .init(texture))
            material.metallic = 0.0      // Paper is not metallic
            material.roughness = 0.7     // Paper is somewhat matte (0.6-0.8)
            material.specular = 0.3      // Low specular reflection
            

            // Apply the texture to tsuru
            guard let tsuru = tsuru else {
                return
            }

            if let flappingBird = tsuru.children.first(where: { $0.name == "flappingBird___0PercentFolded" }) {
                if var modelComponent = flappingBird.components[ModelComponent.self] {
                    modelComponent.materials = [material]
                    flappingBird.components[ModelComponent.self] = modelComponent
                } else {
                }
            } else {
            }
        } catch {
            // Properly handle the thrown error from TextureResource initializer
            print("[SceneViewModel] Failed to create TextureResource: \(error)")
        }
    }
    
    //MARK: - CAMERA FUNCTIONS
    func rotate(dTheta: Float, dPhi: Float) {
        /// Rotaciona a câmera orbital em torno da cena com base no gesto de arrastar.
        ///
        /// Use esta função para atualizar os ângulos esféricos da câmera e, em seguida,
        /// recalcular sua posição olhando para a origem (0, 0, 0). Os deltas recebidos
        /// normalmente vêm de um `DragGesture` na tela e são convertidos em variações
        /// nos ângulos azimutal (θ) e polar (φ).
        ///
        /// Comportamento (arrastar a cena):
        /// - Arrastar para a direita (dTheta > 0): a cena parece girar para a direita
        ///   (a câmera orbita para a esquerda) → `theta` diminui.
        /// - Arrastar para baixo (dPhi > 0): a cena inclina para baixo
        ///   (a câmera sobe em direção ao topo) → `phi` diminui.
        ///
        /// A função também limita `phi` para evitar que a câmera ultrapasse os polos,
        /// garantindo um intervalo confortável de visualização.
        ///
        /// - Parameters:
        ///   - dTheta: Delta horizontal do gesto (em pixels ou pontos), aplicado ao azimute (θ).
        ///   - dPhi: Delta vertical do gesto (em pixels ou pontos), aplicado à elevação (φ).
        ///
        /// - Note: Após ajustar `theta` e `phi`, a função chama `updateCamera()`
        ///   para aplicar imediatamente a nova posição/olhar da câmera.
        // Atualiza theta (rotação horizontal - Azimute)
        // Invertido (-=) para sensação de "pegar e arrastar" a cena
        theta -= dTheta * 0.005
        
        // Atualiza phi (rotação vertical - Elevação)
        // Invertido (-=) para que arrastar para baixo leve a câmera para o topo (phi -> 0)
        phi -= dPhi * 0.005
        
        // Limita phi entre pi/60 e 57pi/100
        // Phi = 0 é o Polo Norte (Topo)
        phi = max(Float.pi / 6, min(51 * Float.pi / 100, phi))
        
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
        rho = max(0.5, min(21, rho))
        
        // Recalcula e aplica a nova posição da câmera
        updateCamera()
    }
    
    private func updateCamera() {
        
        // MARK: - Atualização da Câmera
 
        // Garante que a câmera existe antes de tentar atualizar
        guard let camera else { return }
        

        if let flappingBird = tsuru?.children.first(where: { $0.name == "flappingBird___0PercentFolded" }) {
            let globalPosition = flappingBird.position(relativeTo: nil)
            let x = rho * sin(phi) * cos(theta) + globalPosition.x
            let y = rho * cos(phi) +  globalPosition.y
            let z = rho * sin(phi) * sin(theta) + globalPosition.z
            
            camera.position = [x, y, z]
            
            print("flapping bird position: ", flappingBird.position)
            print("camera position: ", camera.position)
            
            // Faz a câmera sempre olhar para o centro da cena (origem 0,0,0)
            camera.look(at: globalPosition, from: camera.position, relativeTo: nil)
            
        }
    }
}

