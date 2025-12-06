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
    
    //MARK: SERVICES
    var scrapService = ScrapService.shared
    
    
    var orderedPages: [Page?] = [] // pega todas as Pages carregadas ...
    var dict: [Entity:Page] = [:]  //atribui tudo a uma dicionario pra relacionar com entidade.
    var currentPage: Page? = nil
    var lastAdded: Int = 0
    let tsuruPositions: [SIMD3<Float>] = TsuruPosition.allCases.map { tsuru in
        return tsuru.position
    }
    
    //MARK: -SCENE ENTITIES
    var scene: Entity?
    var tree: Entity?
    var scrapImage: UIImage?
    var paperStyle: String?
    var tsuru: Entity?
    var newTsuru: Entity?
    var showCanvas: Bool = false
    
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
    /// Entidade que controla para onde a camera está olhando
    /// Deve estar atualizando para mudar o foco da camera
    private var cameraLook: SIMD3<Float>?
    ///Bool pra controlar o foco da camera
    var isFocusedOnTsuru = false
        


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
            
            try orderedPages = scrapService.fetchAllPages()
            await lodaTsurusAtScene()
            
            lastAdded = orderedPages.count // pega a proxima pra adicionar
            // Posiciona a câmera usando os valores iniciais de theta, phi e distance
            updateCamera()
        } catch {
            print("Erro ao carregar cena: \(error)")
        }
    }
    
    //MARK: - TSURU FUNCTIONS
    func playTsuruAnimation(tsuruToAnimate: Entity?) {
        
        if let tsuruAnimation = tsuruToAnimate?.availableAnimations.first {
            tsuruToAnimate?.playAnimation(tsuruAnimation, transitionDuration: 0.3, startsPaused: false)
        }
        
    }
    
    func addNewTsuru() {
        newTsuru = tsuru?.clone(recursive: true)
        if let newTsuru {
            fixTsuruPos(newTsuru)
            newTsuru.position = tsuruPositions[lastAdded] // coloca o tsuru na posicao certa...
            scene?.addChild(newTsuru)
            dict[newTsuru] = currentPage
        }
        lastAdded += 1
        repositioningCameraNewToTsuru()
    } //aqui vai ser necessário salvar a entidade relacionada com a página
    
    func lodaTsurusAtScene() async {
        do {
            guard let scene else {
                print("Cena não carregada")
                return
            }
            
            print("Scraps count", orderedPages.count)
            for i in 0..<orderedPages.count {
                if orderedPages.count < 30 {
                    
                    if let page = orderedPages[i] {
                        
                        guard let tsuru else { return }
                        
                        let obj = tsuru.clone(recursive: true)
                        fixTsuruPos(obj)
                        obj.transform.rotation = simd_quatf(angle: .pi, axis: [0, 1, 0])
                        obj.position = tsuruPositions[i]
                        
                        print("Criando tsuru \(i) na posição: \(tsuruPositions[i])")

                        await appliyngTextureToTsuru(scrapImage: page.markupImage, tsuru: obj)
                        scene.addChild(obj)
                        playTsuruAnimation(tsuruToAnimate: obj)
                        if let newFlapBird = obj.children.first(where: { $0.name == "flappingBird___0PercentFolded" }) {
                            dict.updateValue(page, forKey: newFlapBird)
                            print("✅ Tsuru \(i) adicionado ao dicionário - Page ID: \(page.id)")
                        }
//                        debugTsuruComponents(obj)
                    }
                }
            }
        }
        print("📊 Total de tsuris no dicionário: \(dict.count)")

    }
    
    func fixTsuruPos(_ e: Entity) {

        guard let newFlapBird = e.children.first(where: { $0.name == "flappingBird___0PercentFolded" }) else {
            print("flappingBird não encontrado em: \(e.name)")
            return 
        }
        
        newFlapBird.scale = [1,1,1]
        newFlapBird.position  = [0,0,0]
        // Gera collision shapes apenas uma vez
        newFlapBird.generateCollisionShapes(recursive: true)
        newFlapBird.components[InputTargetComponent.self] = .init()
        
        
        print("Collision shapes e InputTarget configurados para: \(newFlapBird.name)")
    }
    
    func appliyngTextureToTsuru(scrapImage: UIImage?, tsuru: Entity?) async {
        
        let sourceImage: UIImage? = scrapImage ?? UIImage(named: "teste")
        guard let cgImage = sourceImage?.cgImage else {
            print("[SceneViewModel] No image available to create texture.")
            return
        }
        guard let tsuru else { return }
        guard let newFlapBird = tsuru.children.first(where: { $0.name == "flappingBird___0PercentFolded" }) else { return }


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
            
            
            if var modelComponent = newFlapBird.components[ModelComponent.self] {
                modelComponent.materials = [material]
                newFlapBird.components[ModelComponent.self] = modelComponent
                
            }
        } catch {
            print("[SceneViewModel] Failed to create TextureResource: \(error)")
        }
    }
    
    func handleTap(on entity: Entity) {
        print("========================================")
        print("HANDLE TAP CHAMADO!")
        print("Tocou na entidade: \(entity.name)")
        print("Hierarquia: \(entity.parent?.name ?? "nil") -> \(entity.name)")
        print("Total de entidades no dicionário: \(dict.count)")
        print("========================================")
        
        var current: Entity? = entity
        
        while let ent = current {
            print("Verificando: \(ent.name)")
            if let page = dict[ent] {
                print("Encontrou entidade associada: \(ent.name)")
                currentPage = page
                showCanvas.toggle()
                return
            }
            current = ent.parent
        }
        
        print("Nenhuma entidade registrada encontrada na hierarquia")
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
        // Invertido (+=) para sensação de "pegar e arrastar" a cena
        theta += dTheta * 0.0005
        
        // Atualiza phi (rotação vertical - Elevação)
        // Invertido (-=) para que arrastar para baixo leve a câmera para o topo (phi -> 0)
        phi -= dPhi * 0.0005
        
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
    
    func repositioningCameraNewToTsuru() {
        
        if let tsuruToFocus = newTsuru {
            let tsuruposition = tsuruToFocus.position(relativeTo: nil)
            cameraLook = tsuruposition
            rho = 0.5
            updateCamera()
            isFocusedOnTsuru = true
        }
        
    }
    
    func repositioningCameraToTree() {
        cameraLook = tree?.position
        cameraLook?.x -= 4
        theta =  -4.776666
        rho =  21.0
        updateCamera()
        isFocusedOnTsuru = false
    }
    
    func updateCamera() {
        
        // Garante que a câmera existe antes de tentar atualizar
        guard let camera else { return }
        
        if let cameraLook {
            let x = rho * sin(phi) * cos(theta) + cameraLook.x
            let y = rho * cos(phi) +  cameraLook.y
            let z = rho * sin(phi) * sin(theta) + cameraLook.z
            //            print("theta: ", theta)
            //            print("rho: ", rho)
            camera.position = [x, y, z]
            camera.look(at: cameraLook, from: camera.position, relativeTo: nil)
            
        }
    }
        

    func debugTsuruComponents(_ obj: Entity) {
        print("=== DEBUG TSURU ===")
        print("Objeto pai: \(obj.name)")
        
        if let bird = obj.children.first(where: { $0.name == "flappingBird___0PercentFolded" }) {
            print("✓ Bird encontrado: \(bird.name)")
            print("  - Tem InputTarget? \(bird.components[InputTargetComponent.self] != nil)")
            print("  - Tem Collision? \(bird.components[CollisionComponent.self] != nil)")
            print("  - Posição: \(bird.position)")
            print("  - Escala: \(bird.scale)")
            print("  - Está no dicionário? \(dict[bird] != nil)")
            
            if let collision = bird.components[CollisionComponent.self] {
                print("  - Collision shapes: \(collision.shapes.count) shapes")
                // Mostra detalhes de cada shape
                for (index, shape) in collision.shapes.enumerated() {
                    print("    Shape \(index): \(shape)")
                }
            }
        } else {
            print("✗ Bird NÃO encontrado!")
        }
        print("==================")
    }
}
