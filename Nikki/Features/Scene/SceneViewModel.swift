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

#if os(iOS)
import UIKit
#endif

enum SceneImmersiveSpaceState {
    case closed
    case opening
    case open
}

@MainActor
@Observable
class SceneViewModel {

    // MARK: - MANAGER

    var cameraManager = CameraManager()
    var pageControlTsuru = PageControlTsurus()

    // MARK: - SERVICES

    var scrapService = ScrapService.shared
    var motivationService = MotivationService.shared

    // MARK: - CAMERA PROPERTIES

    var lastDragPosition: CGPoint = .zero
    /// Escala atual do gesto de zoom
    var currentScale: CGFloat = 1.0
    /// Última escala salva para cálculo relativo
    var lastScale: CGFloat = 1.0
    /// controla o foco no tsuru
    var isFocusedOnTsuru: Bool = false

    // MARK: - SCENE DATA

    var orderedPages: [Page?] = []
    var orderedEntities: [Entity] = []
    var dict: [Entity: Page] = [:]
    var lastAdded: Int = 0

    let tsuruPositions: [SIMD3<Float>] = TsuruPosition.allCases.map { tsuru in
        return tsuru.position
    }

    var currentPage: Page? = nil
    var selectedPage: Page?

    // MARK: - LOGIC VIEW PROPERTIES

    var openCanvasWithStyle: PaperStyles.RawValue?
    var isCamerMovingToTree: Bool = false
    var isCameraNotMoving: Bool = true
    var isFocusedOnBandstand = false
    var currentPageControl: Int { pageControlTsuru.currentPageControl }

    #if os(iOS)
    let generator = UIImpactFeedbackGenerator(style: .rigid)
    #endif

    // MARK: - PAGE CONTROL

    var thereIsTsuruAtRight: Bool {
        pageControlTsuru.currentPageControl != 0
    }

    var thereIsTsuruAtLeft: Bool {
        pageControlTsuru.currentPageControl != orderedPages.count - 1
    }

    var showCredits = false

    // MARK: - SCENE ENTITIES

    var scene: Entity?
    var tree: Entity?
    var tsuru: Entity?
    var newTsuru: Entity?

    // MARK: - IMMERSIVE / CANVAS STATE

    var immersiveSpaceState: SceneImmersiveSpaceState = .closed

    /// Indica que o canvas está aberto.
    /// No visionOS isso NÃO deve desligar a cena, apenas bloquear interação.
    var isCanvasPresented: Bool = false

    /// Mantido para compatibilidade com chamadas antigas.
    /// No visionOS, essa flag não deve desligar `scene?.isEnabled`.
    var isScenePaused: Bool = false

    /// Mantido para compatibilidade com `waitUntilSceneResumed()`.
    var finishingResumeScene: Bool = true

    var canInteractWithImmersiveScene: Bool {
        !isCanvasPresented && !isScenePaused
    }

    // MARK: - Motivation

    private var currentMotivation: Motivation?
    var motivationText: String = ""
    var dateMotivation: Date?

    // MARK: - Tips

    let newPageTip = NewPageTip()
    let focusTsuruTip = FocusTsuruTip()
    var showNewPageTip: Bool = false
    var showFocusTsuruTip: Bool = false
    private let hasSeenNewPageTipKey = "hasSeenNewPageTip"
    private let hasSeenFocusTsuruTipKey = "hasSeenFocusTsuruTip"

    // MARK: - LOAD SCENE

    func loadScene() async {
        do {
            let scene = try await Entity(named: "Scene", in: nikkiProjectBundle)
            self.scene = scene
            scene.isEnabled = true

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

    // MARK: - IMMERSIVE / CANVAS CONTROL

    func setCanvasPresented(_ isPresented: Bool) {
        isCanvasPresented = isPresented

        // No visionOS, o canvas deve abrir por cima da experiência.
        // A cena precisa continuar viva e habilitada.
        scene?.isEnabled = true

        if isPresented {
            isScenePaused = false
            finishingResumeScene = true
            return
        }

        isScenePaused = false
        finishingResumeScene = true
        updateCamera()
    }

    func setImmersiveSpaceState(_ state: SceneImmersiveSpaceState) {
        immersiveSpaceState = state
    }

    func markImmersiveOpened() {
        immersiveSpaceState = .open
        scene?.isEnabled = true
    }

    func markImmersiveClosed() {
        immersiveSpaceState = .closed
    }

    func markImmersiveOpening() {
        immersiveSpaceState = .opening
    }

    func setScenePaused(_ paused: Bool) {
        #if os(visionOS)
        // No visionOS, NÃO desligue a Entity raiz.
        // Desligar a cena pode fazer o usuário ver o ambiente default do sistema.
        // Para o canvas, tratamos "paused" como "canvas apresentado".
        setCanvasPresented(paused)
        #else
        isScenePaused = paused
        finishingResumeScene = false

        scene?.isEnabled = !paused

        if !paused {
            finishingResumeScene = true
            updateCamera()
        }
        #endif
    }

    func waitUntilSceneResumed() async {
        while !finishingResumeScene {
            await Task.yield()
        }
    }

    // MARK: - PERSISTENCE FUNCTIONS

    func parseCanvasDateAndAddNewTsuruAtScene() async {
        newTsuru = tsuru?.clone(recursive: true)

        if let newTsuru {
            newTsuru.position = tsuruPositions[lastAdded]

            do {
                let newPage = try scrapService.fetchLastPage()
                dict[newTsuru] = newPage

                try orderedPages = scrapService.fetchAllPages()

                await applyTexture(to: newTsuru, texture: newPage?.markupImage)
                fixTsuruPos(newTsuru)

                scene?.isEnabled = true
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
    }

    func deleteTsurusAtScene() async {
        for tsuru in orderedEntities {
            tsuru.removeFromParent()
        }

        orderedEntities.removeAll()
        dict.removeAll()

        fetchUpdatedTsurusAtOrderedPages()

        lastAdded = orderedPages.count

        await loadTsurusAtScene()

        repositioningCameraToTree(animated: false)
    }

    func fetchUpdatedTsurusAtOrderedPages() {
        do {
            try orderedPages = scrapService.fetchAllPages()
        } catch {
            print("erro ao achar tsurus: ", error.localizedDescription)
        }

        orderedEntities = orderedEntitiesByPageCreationDate()
    }

    func loadTsurusAtScene() async {
        do {
            guard let scene else {
                print("Cena não carregada")
                return
            }

            scene.isEnabled = true

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

                        await applyTexture(to: obj, texture: page.markupImage)

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

            orderedEntities = orderedEntitiesByPageCreationDate()
        }
    }

    // MARK: - TSURU FUNCTIONS

    func playTsuruAnimation(tsuruToAnimate: Entity?) {
        if let tsuruAnimation = tsuruToAnimate?.availableAnimations.first {
            tsuruToAnimate?.playAnimation(
                tsuruAnimation,
                transitionDuration: 0.3,
                startsPaused: false
            )
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
            material.metallic = 0.0
            material.roughness = 0.7
            material.specular = 0.3

            if var modelComponent = newFlapBird.components[ModelComponent.self] {
                modelComponent.materials = [material]
                newFlapBird.components[ModelComponent.self] = modelComponent
            }
        } catch {
            print("Erro ao aplicar textura no tsuru: \(error)")
        }
    }

    func handleTap(on entity: Entity) {
        guard canInteractWithImmersiveScene else { return }

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
        guard !isCanvasPresented else { return }

        currentPage = selectedPage
        openCanvasWithStyle = currentPage?.paperStyle
    }

    // MARK: - TSURU CONTROLS

    func orderedEntitiesByPageCreationDate() -> [Entity] {
        let arrayEntities = Array(dict.keys)

        let orderedEntities = arrayEntities.sorted { ent1, ent2 in
            guard let page1 = dict[ent1], let page2 = dict[ent2] else {
                return false
            }

            return page1.createdAt ?? Date() > page2.createdAt ?? Date()
        }

        return orderedEntities
    }

    func pickLastTsuru() -> Entity? {
        guard let lastTsuru = orderedEntities.first else { return nil }

        selectedPage = dict[lastTsuru]
        return lastTsuru
    }

    func navigateToTsuru(at side: String) {
        guard canInteractWithImmersiveScene else { return }

        pageControlTsuru.navigateToTsuru(
            at: side,
            orderedEntities: orderedEntities,
            selectedPage: &selectedPage,
            dict: &dict,
            repositioningCameraToTsuru: repositioningCameraToTsuru(_:)
        )

        #if os(iOS)
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

    // MARK: - CAMERA FUNCTIONS

    func rotate(dTheta: Float, dPhi: Float) {
        guard canInteractWithImmersiveScene else { return }

        if isCameraNotMoving {
            cameraManager.rotate(dTheta: dTheta, dPhi: dPhi)
        }
    }

    func zoom(scale: Float) {
        guard canInteractWithImmersiveScene else { return }

        if isCameraNotMoving {
            cameraManager.zoom(scale: scale)
        }
    }

    func repositioningCameraToTsuru(_ newTsuru: Entity?) {
        guard canInteractWithImmersiveScene else { return }

        cameraManager.repositioningCameraNewToTsuru(
            animated: true,
            tsuruToFocus: newTsuru
        )

        isFocusedOnTsuru = true
    }

    func repositioningCameraToTree(animated: Bool = true) {
        cameraManager.repositioningCameraToTree(
            animated: animated,
            tree: tree
        )

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
                let newMotivation = Motivation(
                    text: motivationText,
                    updatedAt: Date()
                )

                try motivationService.saveMotivation(newMotivation)
                currentMotivation = newMotivation
            }
        } catch {
            print("Erro ao salvar motivação: \(error)")
        }
    }

    // MARK: - TipKit Helpers

    func evaluateTipsVisibility() {
        showNewPageTip = !UserDefaults.standard.bool(
            forKey: hasSeenNewPageTipKey
        )

        showFocusTsuruTip = !UserDefaults.standard.bool(
            forKey: hasSeenFocusTsuruTipKey
        )
    }

    func dismissNewPageTip() {
        showNewPageTip = false
        UserDefaults.standard.set(true, forKey: hasSeenNewPageTipKey)
    }

    func dismissFocusTsuruTip() {
        showFocusTsuruTip = false
        UserDefaults.standard.set(true, forKey: hasSeenFocusTsuruTipKey)
    }

    // MARK: - DEBUG FUNCTIONS

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
