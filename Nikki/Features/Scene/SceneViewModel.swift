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
    
    //MARK: - MANAGER
    var cameraManager = CameraManager()
    
    //MARK: - SERVICES
    var scrapService = ScrapService.shared
    
    //MARK: - CAMERA PROPERTIES
    /*
     OBS: Estas propriedades devem permanecer na ViewModel, não no CameraManager.
     Razão: Representam estado temporário dos gestos de UI (touch/drag tracking),
     não estado da câmera orbital 3D. Manter aqui preserva a separação de
     responsabilidades:
     - ViewModel: interpreta gestos do usuário e orquestra comandos
     - CameraManager: gerencia matemática e posicionamento da câmera 3D
     */
    var lastDragPosition: CGPoint = .zero
    /// Escala atual do gesto de zoom
    var currentScale: CGFloat = 1.0
    /// Última escala salva para cálculo relativo
    var lastScale: CGFloat = 1.0
    /// controla o foco no tsuru
    var isFocusedOnTsuru: Bool = false
    
    
    
    //MARK: - SCENE DATA
    var orderedPages: [Page?] = []
    var dict: [Entity:Page] = [:]
    var lastAdded: Int = 0
    let tsuruPositions: [SIMD3<Float>] = TsuruPosition.allCases.map { tsuru in
        return tsuru.position
    }
    var openCanvasWithStyle: PaperStyles.RawValue?
    var selectedEntityName: Entity? = nil
    var currentPage: Page? = nil
    var selectedPage: Page?
    
    //MARK: -SCENE ENTITIES
    var scene: Entity?
    var tree: Entity?
    var tsuru: Entity?
    var newTsuru: Entity?
    
    // MARK: - Motivation
    private var currentMotivation: Motivation?
    var motivationText: String = ""
    var datadamotivacaodosguri: Date = Date()
    /// Entidade que controla para onde a camera está olhando
    /// Deve estar atualizando para mudar o foco da camera
    private var cameraLook: SIMD3<Float>?
    ///Bool pra controlar o foco da camera
    var isFocusedOnBandstand = false
    
    
    //MARK: - LOAD SCENE
    func loadScene() async {
        do {
            let scene = try await Entity(named: "Scene", in: nikkiProjectBundle) // Carrega a cena do arquivo Reality Composer Pro ou bundle
            self.scene = scene
            let camera = PerspectiveCamera()
            
            tree = scene.findEntity(named: "Cherry_Tree_2")
            tree?.generateCollisionShapes(recursive: true)
            tree?.components[InputTargetComponent.self] = .init()
            
            tsuru = scene.findEntity(named: "tsuru")
            
            
            if let bandstand = scene.findEntity(named: "Japan_HW") {
                bandstand.generateCollisionShapes(recursive: true)
                bandstand.components[InputTargetComponent.self] = .init()
            }
            
            //            await appliyngTextureToTsuru(scrapImage: nil)
            // Cria uma nova câmera perspectiva
            // PerspectiveCamera simula visão humana com perspectiva realista
            
            scene.addChild(camera)
            self.cameraManager.camera = camera
            
            try orderedPages = scrapService.fetchAllPages()
            await loadTsurusAtScene()
            
            lastAdded = orderedPages.count
            
            updateCamera()
        } catch {
            print("Erro ao carregar cena: \(error)")
        }
    }
    
    //MARK: PERSISTENCE FUNCTIONS
    
    func addNewTsuru() async {
        print("entrou aqui")
        newTsuru = tsuru?.clone(recursive: true) // clona o tsuru
        if let newTsuru {
            fixTsuruPos(newTsuru) //arruma a posicao do tsuru
            newTsuru.position = tsuruPositions[lastAdded] // coloca o tsuru na posicao certa...
            do {
                let newPage = try scrapService.fetchLastPage() //recupera a ultima page salva
                dict[newTsuru] = newPage //coloca no dicionario
                await appliyngTextureToTsuru(scrapImage: newPage?.markupImage, tsuru: newTsuru)
                scene?.addChild(newTsuru)
            } catch {
                print("erro ao adicionar novo tsuru: ", error.localizedDescription)
            }
        }
        cameraManager.repositioningCameraNewToTsuru(newTsuru)
    }//ok
    
    
    //MARK: - CAMERA FUNCTIONS
    
    
    func loadTsurusAtScene() async {
        do {
            guard let scene else {
                print("Cena não carregada")
                return
            }
            
            for i in 0..<orderedPages.count {
                if orderedPages.count < 30 {
                    
                    if let page = orderedPages[i] {
                        
                        guard let tsuru else { return }
                        
                        let obj = tsuru.clone(recursive: true)
                        fixTsuruPos(obj)
                        obj.transform.rotation = simd_quatf(angle: .pi, axis: [0, 1, 0])
                        obj.position = tsuruPositions[i]
                        
                        
                        await appliyngTextureToTsuru(scrapImage: page.markupImage, tsuru: obj)
                        scene.addChild(obj)
                        playTsuruAnimation(tsuruToAnimate: obj)
                        if let newFlapBird = obj.children.first(where: { $0.name == "flappingBird___0PercentFolded" }) {
                            dict.updateValue(page, forKey: newFlapBird)
                        }
                    }
                }
            }
            print("scraps adicionados: ", orderedPages.count)
        }
    }
    
    //MARK: - TSURU FUNCTIONS
    func playTsuruAnimation(tsuruToAnimate: Entity?) {
        
        if let tsuruAnimation = tsuruToAnimate?.availableAnimations.first {
            tsuruToAnimate?.playAnimation(tsuruAnimation, transitionDuration: 0.3, startsPaused: false)
        }
        
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
        
    }
    
    func appliyngTextureToTsuru(scrapImage: UIImage?, tsuru: Entity?) async {
        
        let sourceImage: UIImage? = scrapImage ?? UIImage(named: "teste")
        guard let cgImage = sourceImage?.cgImage else { return }
        guard let tsuru else { return }
        guard let newFlapBird = tsuru.children.first(where: { $0.name == "flappingBird___0PercentFolded" }) else { return }
        
        
        // Create material with the texture
        do {
            let texture = try await TextureResource(image: cgImage, options: .init(semantic: .color))
            var material = PhysicallyBasedMaterial()
            
            let rotationRadians =  Float.pi / 180
            material.textureCoordinateTransform = .init(scale: SIMD2<Float>(x:1, y: -1), rotation: rotationRadians)
            material.baseColor = .init(tint: .white, texture: .init(texture))
            material.metallic = 0.0      // Paper is not metallic
            material.roughness = 0.7     // Paper is somewhat matte (0.6-0.8)
            material.specular = 0.3      // Low specular reflection
            
            if var modelComponent = newFlapBird.components[ModelComponent.self] {
                modelComponent.materials = [material]
                newFlapBird.components[ModelComponent.self] = modelComponent
                
            }
        } catch {
        }
    }
    
    func handleTap(on entity: Entity) { // toca só na arvore, pelo menos pra MVP
        
        if entity.name == "Japan_HW" && !isFocusedOnBandstand {
            cameraManager.focusOnBandstand()
            isFocusedOnBandstand = true
            return
        }
        
        if !(entity.name == "flappingBird___0PercentFolded") && !isFocusedOnTsuru  {
            selectedPage = dict[entity]
            let allEntities = Array(dict.keys)
            let lastEntity = allEntities.last
            repositioningCameraToTsuru(lastEntity)
            
        }
    }
    
    func openTsuru() {
        
        currentPage = selectedPage
        openCanvasWithStyle = currentPage?.paperStyle
        
    }
    
    //MARK: - CAMERA FUNCTIONS
    func rotate(dTheta: Float, dPhi: Float) {
        cameraManager.rotate(dTheta: dTheta, dPhi: dPhi)
    }
    
    func zoom(scale: Float) {
        cameraManager.zoom(scale: scale)
    }
    
    func repositioningCameraToTsuru(_ newTsuru: Entity?) {
        cameraManager.repositioningCameraNewToTsuru(newTsuru)
        isFocusedOnTsuru = true
    }
    
    func repositioningCameraToTree() {
        cameraManager.repositioningCameraToTree(tree: tree)
        isFocusedOnTsuru = false
        currentPage = nil
    }
    
    func updateCamera() {
        cameraManager.updateCamera()
    }
    
    //MARK: - DEBUG FUNCTIONS
    
    func debugTsuruComponents(_ obj: Entity) {
        print("=== DEBUG TSURU ===")
        print("Objeto pai: \(obj.name)")
        
        if let bird = obj.children.first(where: { $0.name == "flappingBird___0PercentFolded" }) {
            print("Bird encontrado: \(bird.name)")
            print("Tem InputTarget? \(bird.components[InputTargetComponent.self] != nil)")
            print("Tem Collision? \(bird.components[CollisionComponent.self] != nil)")
            print("Posição: \(bird.position)")
            print("Escala: \(bird.scale)")
            print("Está no dicionário? \(dict[bird] != nil)")
            
            if let collision = bird.components[CollisionComponent.self] {
                print("Collision shapes: \(collision.shapes.count) shapes")
                // Mostra detalhes de cada shape
                for (index, shape) in collision.shapes.enumerated() {
                    print("Shape \(index): \(shape)")
                }
            }
        } else {
            print("✗ Bird NÃO encontrado!")
        }
        print("==================")
        
    }
    
    
    // MARK: - Motivation Methods
    
    func loadMotivation() {
        do {
            if let motivation = try scrapService.fetchMotivation() {
                currentMotivation = motivation
                motivationText = motivation.text ?? ""
                datadamotivacaodosguri = motivation.updatedAt ?? Date()
            } else {
                currentMotivation = nil
                motivationText = ""
                datadamotivacaodosguri = .now
            }
        } catch {
            print("Erro ao carregar motivação: \(error)")
        }
    }
    
    func saveMotivation() {
        do {
            if let motivation = currentMotivation {
                motivation.text = motivationText
                motivation.updatedAt = Date()
                try scrapService.updateMotivation(motivation)
            } else {
                let newMotivation = Motivation(text: motivationText)
                try scrapService.saveMotivation(newMotivation)
                currentMotivation = newMotivation
            }
        } catch {
            print("Erro ao salvar motivação: \(error)")
        }
    }
}


//    func handleTap(on entity: Entity) {
//        print(" Tocou na entidade: \(entity.name)")
//
//        var current: Entity? = entity
//
//        // Sobe pela hierarquia até encontrar uma entidade registrada no dicionário
//        while let ent = current {
//            print("Encontrou entidade associada: \(ent.name)")
//            if let page = dict[ent] {
//                currentPage = page
//                return
//            }
//
//            // Coreto. O && serve pra ele nao ficar animando posicao estatica caso o usuario fique clicando varias vezes no coreto, ai da uma travada (melhor previnir vai saber)
//            if ent.name == "Japan_HW" && !isFocusedOnBandstand {
//                focusOnBandstand()
//                isFocusedOnBandstand = true
//                return
//            }
//            current = ent.parent
//        }
//
//        print("Nenhuma entidade registrada encontrada na hierarquia")
//    }

