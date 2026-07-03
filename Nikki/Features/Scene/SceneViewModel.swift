//
//  SceneViewModel.swift
//  Nikki
//
//  Created by Gustavo Ferreira bassani on 17/11/25.
//

import NikkiProject
import RealityKit
import SwiftUI
import TipKit

@MainActor
@Observable
class SceneViewModel {
    
    //MARK: - MANAGER
    var cameraManager = CameraManager()
    var pageControlTsuru = PageControlTsurus()
    
    //MARK: - SERVICES
    var scrapService = ScrapService.shared
    var motivationService = MotivationService.shared
    
    //MARK: - CAMERA PROPERTIES
    var lastDragPosition: CGPoint = .zero
    /// Escala atual do gesto de zoom
    var currentScale: CGFloat = 1.0
    /// Última escala salva para cálculo relativo
    var lastScale: CGFloat = 1.0
    /// controla o foco no tsuru
    var isFocusedOnTsuru: Bool = false
    
    //MARK: - SCENE DATA
    var orderedPages: [Page?] = [] // pra descarregar
    var orderedEntities: [Entity] = [] // pra ordenar as chaves ( entidades )
    var dict: [Entity:Page] = [:] // dicionario que contem a parada toda
    var lastAdded: Int = 0
    let tsuruPositions: [SIMD3<Float>] = TsuruPosition.allCases.map { tsuru in
        return tsuru.position
    }  // posicao dos tsurus
    var currentPage: Page? = nil
    var selectedPage: Page?
    
    //MARK: - LOGIC VIEW PROPERTIES
    var openCanvasWithStyle: PaperStyles.RawValue?
    var isCamerMovingToTree: Bool = false
    var isCameraNotMoving: Bool = true
    var isFocusedOnBandstand = false //Bool pra controlar o foco da camera
    var currentPageControl: Int { pageControlTsuru.currentPageControl }
    #if !os(visionOS)
    let generator = UIImpactFeedbackGenerator(style: .rigid)
    #endif
    
    //MARK: - PAGE CONTROL
    var thereIsTsuruAtRight: Bool  {pageControlTsuru.currentPageControl != 0  }
    var thereIsTsuruAtLeft: Bool { pageControlTsuru.currentPageControl != orderedPages.count - 1 }
    var showCredits = false
    
    //MARK: -SCENE ENTITIES
    var scene: Entity?
    var tree: Entity?
    var tsuru: Entity?
    var newTsuru: Entity?
    var isScenePaused: Bool = false
    var finishingResumeScene: Bool = false

    //MARK: - POC Tsuru Flight
    /// Sinaliza para a `TsuruPortalView` qual animação da POC deve rodar.
    /// Os botões da `VisionOSLauncherView` setam isso após abrir o space "TsuruPOC".
    var pocFlightRequest: TsuruFlightKind?

    //MARK: - Splash Flight (intro)
    /// `true` quando o pássaro da intro voltou para a tela. A `VisionSplashView`
    /// observa isso para fechar o space do voo e começar a animação da splash.
    var splashFlightDidReturn: Bool = false
    
    // MARK: - Motivation
    private var currentMotivation: Motivation?
    var motivationText: String = ""
    var dateMotivation: Date?
    
    
    //MARK: - Tips
    let newPageTip = NewPageTip()
    let focusTsuruTip = FocusTsuruTip()
    var showNewPageTip: Bool = false
    var showFocusTsuruTip: Bool = false
    private let hasSeenNewPageTipKey = "hasSeenNewPageTip"
    private let hasSeenFocusTsuruTipKey = "hasSeenFocusTsuruTip"
    
    //MARK: - LOAD SCENE
    func loadScene() async {
        do {
            let scene = try await Entity(named: "Scene", in: nikkiProjectBundle)
            self.scene = scene
            let camera = PerspectiveCamera()
            tree = scene.findEntity(named: "Cherry_Tree_2")
            tsuru = scene.findEntity(named: "tsuru")
            
            if let bandstand = scene.findEntity(named: "Japan_HW") {
                bandstand.generateCollisionShapes(recursive: true)
                bandstand.components[InputTargetComponent.self] = .init()
            }
            
            if let credits = scene.findEntity(named: "creditsHitbox") {
                credits.generateCollisionShapes(recursive: true)
                credits.components[InputTargetComponent.self] = .init()
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
    
    func parseCanvasDateAndAddNewTsuruAtScene() async {
        newTsuru = tsuru?.clone(recursive: true) // clona o tsuru
        
        if let newTsuru {
            newTsuru.position = tsuruPositions[lastAdded]  // coloca o tsuru na posicao certa...
            do {
                let newPage = try scrapService.fetchLastPage() //recupera a ultima page salva
                dict[newTsuru] = newPage //coloca no dicionario
                try orderedPages = scrapService.fetchAllPages() // atualiza no array de pages todas as paginas
                await applyTexture(to: newTsuru, texture: newPage?.markupImage) // aplica textura
                fixTsuruPos(newTsuru)  //arruma a posicao do tsuru

                scene?.addChild(newTsuru)
            } catch {
                print(
                    "erro ao adicionar novo tsuru: ",
                    error.localizedDescription
                )
            }
            
            selectedPage = dict[newTsuru]
            
        }
        lastAdded += 1
        cameraManager.repositioningCameraNewToTsuru(
            animated: false,
            tsuruToFocus: newTsuru
        )
        playTsuruAnimation(tsuruToAnimate: newTsuru)
        isFocusedOnTsuru = true
        orderedEntities = orderedEntitiesByPageCreationDate()
        debugPageControl()
    }//ok
    
    func deleteTsurusAtScene() async {
        
        // 1. Remove todas as entidades da cena
        for tsuru in orderedEntities {
            tsuru.removeFromParent()
        }
        
        // 2. LIMPA TODOS OS ARRAYS E DICIONÁRIOS
        orderedEntities.removeAll()
        dict.removeAll()
        
        // 3. Atualiza a lista de páginas do banco
        fetchUpdatedTsurusAtOrderedPages()
        
        // 4. Atualiza o lastAdded baseado nas páginas atuais
        lastAdded = orderedPages.count
        
        // 5. Recarrega os tsurus na cena
        await loadTsurusAtScene()
        
        // 6. Reseta a câmera para a árvore sem animação para evitar estado intermediário
        repositioningCameraToTree(animated: false)
        
    }
    
    func fetchUpdatedTsurusAtOrderedPages() {
        do {
            try orderedPages = scrapService.fetchAllPages()
        } catch {
            print("erro ao achar tsurus: ", error.localizedDescription)
        }
        orderedEntities = orderedEntitiesByPageCreationDate()
        
        return
    }
    
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
                        obj.transform.rotation = simd_quatf(
                            angle: .pi,
                            axis: [0, 1, 0]
                        )
                        obj.position = tsuruPositions[i]
                        
                        
                        await applyTexture(to: obj, texture: page.markupImage )
                        
                        scene.addChild(obj)
                        playTsuruAnimation(tsuruToAnimate: obj)
                        if let newFlapBird = obj.children.first(where: {
                            $0.name == "flappingBird___0PercentFolded"
                        }) {
                            dict.updateValue(page, forKey: newFlapBird)
                        }
                    }
                }
            }
            orderedEntities = orderedEntitiesByPageCreationDate() // ordena na hora da criacao
        }
    }
    
    //MARK: - TSURU FUNCTIONS
    func playTsuruAnimation(tsuruToAnimate: Entity?) {
        
        if let tsuruAnimation = tsuruToAnimate?.availableAnimations.first {
            tsuruToAnimate?.playAnimation(
                tsuruAnimation,
                transitionDuration: 0.3,
                startsPaused: false
            )
        }
        
    }

    func setScenePaused(_ paused: Bool) {
        isScenePaused = paused
        finishingResumeScene = false

        scene?.isEnabled = !paused

        if !paused {
            updateCamera()
        }
    }

    func waitUntilSceneResumed() async {
        while !finishingResumeScene {
            await Task.yield()
        }
    }
    
    func fixTsuruPos(_ e: Entity) {
        
        guard
            let newFlapBird = e.children.first(where: {
                $0.name == "flappingBird___0PercentFolded"
            })
        else {
            print("flappingBird não encontrado em: \(e.name)")
            return
        }
        
        newFlapBird.scale = [1, 1, 1]
        newFlapBird.position = [0, 0, 0]
        // Gera collision shapes apenas uma vez
        newFlapBird.generateCollisionShapes(recursive: true)
        newFlapBird.components[InputTargetComponent.self] = .init()
        
    }
    
    func applyTexture(to tsuru: Entity?, texture scrapImage: UIImage?) async {
        
        let sourceImage: UIImage? = scrapImage ?? UIImage(named: "teste")
        guard let cgImage = sourceImage?.cgImage else { return }
        guard let tsuru else { return }
        guard
            let newFlapBird = tsuru.children.first(where: {
                $0.name == "flappingBird___0PercentFolded"
            })
        else { return }
        
        // Create material with the texture
        do {
            let texture = try await TextureResource(
                image: cgImage,
                options: .init(semantic: .color)
            )
            var material = PhysicallyBasedMaterial()
            
            let rotationRadians = Float.pi / 180
            material.textureCoordinateTransform = .init(
                scale: SIMD2<Float>(x: 1, y: -1),
                rotation: rotationRadians
            )
            material.baseColor = .init(tint: .white, texture: .init(texture))
            material.metallic = 0.0  // Paper is not metallic
            material.roughness = 0.7  // Paper is somewhat matte (0.6-0.8)
            material.specular = 0.3  // Low specular reflection
            
            if var modelComponent = newFlapBird.components[ModelComponent.self]
            {
                modelComponent.materials = [material]
                newFlapBird.components[ModelComponent.self] = modelComponent
                
            }
        } catch {
        }
    }
    
    func handleTap(on entity: Entity) {
        
        var current: Entity? = entity
        
        while let ent = current {
            if ent.name == "Japan_HW" && !isFocusedOnBandstand {
                cameraManager.focusOnBandstand()
                isFocusedOnBandstand = true
                return
            }
            
            if ent.name == "creditsHitbox" {
                showCredits = true
                return
            }
            current = ent.parent
        }
        
    }
    
    func openTsuru() {
        
        currentPage = selectedPage // isso aqui eu poderia simplesmente passar o selectedpage direto ?
        openCanvasWithStyle = currentPage?.paperStyle
        
    }
    
    //MARK: - TSURU CONTROLS
    
    func orderedEntitiesByPageCreationDate() -> [Entity] {
        let arrayEntities = Array(dict.keys)
        
        let orderedEntities = arrayEntities.sorted { ent1, ent2 in
            guard let page1 = dict[ent1], let page2 = dict[ent2] else {
                return false
            }
            // Páginas mais novas primeiro (ordem decrescente)
            return page1.createdAt ?? Date() > page2.createdAt ?? Date()
        }
        
        return orderedEntities
    }
    
    func pickLastTsuru() -> Entity? {
        guard let lastTsuru = orderedEntities.first else { return nil }
        selectedPage = dict[lastTsuru] // se isso aqui estiver no repositioningcameratotsuru talvez nem precise estar no navigate to tsuru.. ai centraliza o lugar onde atualiza o selectedPage
        return lastTsuru
    }
    
    //MARK: - TSURU CONTROLS
    
    func navigateToTsuru(at side: String) {
        pageControlTsuru.navigateToTsuru(at: side, orderedEntities: orderedEntities, selectedPage: &selectedPage, dict: &dict, repositioningCameraToTsuru: repositioningCameraToTsuru(_:))
        #if !os(visionOS)
        generator.impactOccurred()
        #endif
        

        Task {
            isCameraNotMoving = false
            try? await Task.sleep(nanoseconds: 500_000_000)
            isCameraNotMoving = true
        }

    }
    
    func resetPageControl() {
        pageControlTsuru.resetPageControl()
    }
    
    //MARK: - CAMERA FUNCTIONS
    func rotate(dTheta: Float, dPhi: Float) {
        if isCameraNotMoving {
            cameraManager.rotate(dTheta: dTheta, dPhi: dPhi)
        }
    }
    
    func zoom(scale: Float) {
        if isCameraNotMoving {
            cameraManager.zoom(scale: scale)
        }
    }
    
    func repositioningCameraToTsuru(_ newTsuru: Entity?) {
        
        cameraManager.repositioningCameraNewToTsuru(animated: true, tsuruToFocus: newTsuru)
        isFocusedOnTsuru = true
    }
    
    func repositioningCameraToTree(animated: Bool = true) {
        cameraManager.repositioningCameraToTree(animated: animated, tree: tree)
        isFocusedOnTsuru = false
        resetPageControl()
        currentPage = nil
    }
    
    func updateCamera() {
        cameraManager.updateCamera()
    }
    
    // MARK: - Motivation Methods
    
    func loadMotivation() {
        do {
            if let motivation = try motivationService.fetchMotivation() {
                currentMotivation = motivation
                motivationText = motivation.text ?? ""
                dateMotivation = motivation.updatedAt ?? Date()
            } else {
                currentMotivation = nil
                motivationText = ""
                dateMotivation = .now
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
                try motivationService.updateMotivation(motivation)
            } else {
                let newMotivation = Motivation(text: motivationText, updatedAt: Date())
                try motivationService.saveMotivation(newMotivation)
                currentMotivation = newMotivation
            }
        } catch {
            print("Erro ao salvar motivação: \(error)")
        }
    }
    
    // MARK: - TipKit Helpers
    
    func evaluateTipsVisibility() {
        showNewPageTip = !UserDefaults.standard.bool(forKey: hasSeenNewPageTipKey)
        showFocusTsuruTip = !UserDefaults.standard.bool(forKey: hasSeenFocusTsuruTipKey)
    }
    
    func dismissNewPageTip() {
        showNewPageTip = false
        UserDefaults.standard.set(true, forKey: hasSeenNewPageTipKey)
    }
    
    func dismissFocusTsuruTip() {
        showFocusTsuruTip = false
        UserDefaults.standard.set(true, forKey: hasSeenFocusTsuruTipKey)
    }
    
    //MARK: - DEBUG FUNCTIONS
    
    func debugTsuruComponents(_ obj: Entity) {
        print("=== DEBUG TSURU ===")
        print("Objeto pai: \(obj.name)")
        
        if let bird = obj.children.first(where: {
            $0.name == "flappingBird___0PercentFolded"
        }) {
            print("Bird encontrado: \(bird.name)")
            print(
                "Tem InputTarget? \(bird.components[InputTargetComponent.self] != nil)"
            )
            print(
                "Tem Collision? \(bird.components[CollisionComponent.self] != nil)"
            )
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
    
    func debugPageControl() {
        print("pageControl: ", pageControlTsuru.currentPageControl)
        print("numero de scraps: ", orderedEntities.count)
    }
}


