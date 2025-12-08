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
    
    
    
    //MARK: - DATA
    var orderedPages: [Page?] = [] // pega todas as Pages carregadas ...
    var openCanvasWithStyle: PaperStyles.RawValue? // paperstyle para abrir a pagina
    var dict: [Entity:Page] = [:]  //atribui tudo a uma dicionario pra relacionar com entidade.
    var lastAdded: Int = 0
    let tsuruPositions: [SIMD3<Float>] = TsuruPosition.allCases.map { tsuru in
        return tsuru.position
    }
    var currentPage: Page? = nil
    var selectedPage: Page?
    
    //MARK: -SCENE ENTITIES
    var scene: Entity?
    var tree: Entity?
    var tsuru: Entity?
    var newTsuru: Entity?
    
    
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
            
            scene.addChild(camera)
            self.cameraManager.camera = camera
            
            try orderedPages = scrapService.fetchAllPages()
            await lodaTsurusAtScene()
            
            lastAdded = orderedPages.count // pega a proxima pra adicionar
            // Posiciona a câmera usando os valores iniciais de theta, phi e distance
            updateCamera()
        } catch {
            print("Erro ao carregar cena: \(error)")
        }
    }
    
    //MARK: PERSISTENCE FUNCTIONS
    
    func addNewTsuru() async {
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
        lastAdded += 1
        repositioningCameraToTsuru(newTsuru)
        playTsuruAnimation(tsuruToAnimate: newTsuru)
    } //adicionar o tsuru a cena
    
    func lodaTsurusAtScene() async {
        do {
            guard let scene else {
                print("Cena não carregada")
                return
            }
            
            //            print("Scraps count", orderedPages.count)
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
                        //                        debugTsuruComponents(obj)
                    }
                }
            }
        }
        //        print(" Total de tsuris no dicionário: \(dict.count)")
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
//        if entity.name == "flappingBird___0PercentFolded" {
//            print("entrou no flapbird")
//            repositioningCameraToTsuru(entity)
//            currentPage = dict[entity]
//        } else {
//            print("entrou no toque da arvore")
//            let allEntities = Array(dict.keys)
//            let lastEntity = allEntities.last
//            repositioningCameraToTsuru(lastEntity)
//        }
        
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
        cameraManager.repositioningCameraToTree(tree)
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
}
