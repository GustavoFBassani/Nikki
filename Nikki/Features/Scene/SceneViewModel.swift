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
    
    //MARK: - MANAGER
    #if os(visionOS)
    var cameraManager: CameraManaging = VisionCameraManager()
    #else
    var cameraManager: CameraManaging = CameraManager()
    #endif

    var pageControlTsuru = PageControlTsurus()

    // MARK: - SERVICES

    var scrapService = ScrapService.shared
    var motivationService = MotivationService.shared
    let environmentManager = EnvironmentManager.shared

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

    let tsuruPositions: [SIMD3<Float>] = TsuruPosition.allCases.map { tsuru in
        return tsuru.position
    }

    /// Quantos tsurus a árvore comporta. É o número de posições modeladas na cena
    /// (`TsuruPosition`), não um número solto: passar disso não tem onde pendurar.
    var maxTsurus: Int { tsuruPositions.count }

    /// Índice da posição livre para o próximo tsuru. Deriva de `orderedPages`, que é
    /// recarregado do SwiftData ao criar e ao deletar — então apagar um scrap libera
    /// a vaga sozinho. Era um contador à parte (`lastAdded`) que só crescia, e por
    /// isso descolava da contagem real e travava o botão de criar.
    var nextTsuruIndex: Int { orderedPages.count }

    /// `false` quando a árvore já está cheia. A UI usa isso para esconder o botão de
    /// criar página, já que uma página a mais não teria posição no galho.
    var canAddNewPage: Bool { nextTsuruIndex < maxTsurus }

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

    #if os(visionOS)
    var isLookingAtTree: Bool = false
    #endif

    // MARK: - SCENE ENTITIES

    var scene: Entity?
    var tree: Entity?
    var tsuru: Entity?
    var newTsuru: Entity?

    private var scenarioTask: Task<Void, Never>?

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

    //MARK: - Splash Flight (intro)
    /// `true` quando o pássaro da intro voltou para a tela. A `VisionSplashView`
    /// observa isso para fechar o space do voo e começar a animação da splash.
    var splashFlightDidReturn: Bool = false

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
            
            environmentManager.refreshDayPeriod()
            await applyScenarioTexture(environmentManager.dayPeriod.scenarioTextureName, in: scene)

            #if os(visionOS)
            // No visionOS, ajustamos a posição inicial do mundo ANTES de ele ser adicionado
            // na view (antes do self.scene = scene), para que o primeiro frame já nasça
            // no lugar certo e não pule.
            self.cameraManager.repositioningCameraToTree(animated: false, tree: tree)

            tree?.generateCollisionShapes(recursive: true)
            tree?.components[InputTargetComponent.self] = .init(allowedInputTypes: .indirect)
            tree?.components.set(CollisionComponent(shapes: [.generateBox(size: [0.5, 0.5, 0.5])]))
            #endif
            
            // Só agora liberamos a cena para a View desenhar!
            self.scene = scene
            
            // Cria uma nova câmera perspectiva
            // PerspectiveCamera simula visão humana com perspectiva realista

            scene.addChild(camera)
            self.cameraManager.camera = camera

            try orderedPages = scrapService.fetchAllPages()
            await loadTsurusAtScene()

            updateCamera()
        } catch {
            print("Erro ao carregar cena: \(error)")
        }
    }

    // MARK: - IMMERSIVE / CANVAS CONTROL

    func setCanvasPresented(_ isPresented: Bool) {
        isCanvasPresented = isPresented

        // Esconde ou mostra o tsuru atual
        if let page = currentPage,
           let entity = dict.first(where: { $0.value.id == page.id })?.key {
            
            if entity.name == "flappingBird___0PercentFolded" {
                // entity é a malha "newFlapBird". O seu "parent" é o contêiner "obj" do tsuru.
                entity.parent?.isEnabled = !isPresented
            } else {
                // entity já é o contêiner principal (caso do tsuru recém criado)
                entity.isEnabled = !isPresented
            }
        }

        scene?.isEnabled = true

        // Para/retoma o áudio ambiente junto com o canvas.
        if isPresented {
            environmentManager.pauseEnvironmentAudio()
        } else {
            environmentManager.resumeEnvironmentAudio()
        }

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

        // Para/retoma o áudio ambiente junto com a pausa da cena.
        if paused {
            environmentManager.pauseEnvironmentAudio()
        } else {
            environmentManager.resumeEnvironmentAudio()
        }

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
        // Rede de segurança: a UI já esconde o botão de criar quando a árvore lota,
        // mas a página é salva antes deste método rodar. Sem esta guarda, indexar
        // `tsuruPositions` fora do range derrubaria o app.
        guard canAddNewPage else {
            print("Árvore cheia: o limite é \(maxTsurus) tsurus")
            fetchUpdatedTsurusAtOrderedPages()
            return
        }

        newTsuru = tsuru?.clone(recursive: true)

        if let newTsuru {
            // Ainda com `orderedPages` anterior ao refetch abaixo, então a contagem
            // aqui é justamente o índice da primeira posição livre.
            newTsuru.position = tsuruPositions[nextTsuruIndex]

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

        #if os(visionOS)
        cameraManager.repositioningCameraNewToTsuru(
            animated: false,
            tsuruToFocus: newTsuru?.children.first
        )
        #else
        cameraManager.repositioningCameraNewToTsuru(
            animated: false,
            tsuruToFocus: newTsuru
        )

        #endif

        playTsuruAnimation(tsuruToAnimate: newTsuru)

        isFocusedOnTsuru = true
        orderedEntities = orderedEntitiesByPageCreationDate()
    }

    func deleteTsurusAtScene() async {
        for tsuru in orderedEntities {
            tsuru.removeFromParent()
        }

        orderedEntities.removeAll()
        dict.removeAll()

        fetchUpdatedTsurusAtOrderedPages()

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

            // Uma página por posição modelada. A condição antiga (`orderedPages.count < 30`)
            // era invariante no loop: a partir de 30 páginas ela zerava a renderização
            // inteira e a árvore aparecia vazia, sem erro nenhum.
            for i in 0..<min(orderedPages.count, maxTsurus) {
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
        newFlapBird.components.set(CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.15])]))
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

    // MARK: - ENVIRONMENT (PERÍODO, CLIMA e ÁUDIO)

    func startEnvironment() {
        // Chamado com a cena já montada: é aqui que o áudio ambiente é liberado,
        // para o app não tocar nada durante splash/onboarding. Toca já a trilha do
        // clima conhecido para não abrir em silêncio, e em seguida consulta o clima
        // real: se tiver mudado, a faixa é trocada.
        environmentManager.activateEnvironmentAudio()

        Task {
            if await environmentManager.refreshWeather() {
                environmentManager.updateAudioForWeather()
            }
        }
    }

    func refreshEnvironmentOnActive() async {
        environmentManager.refreshDayPeriod()
        // No-op enquanto a cena não liberou o áudio (splash / onboarding).
        environmentManager.updateAudioForWeather()

        // O cenário só pode ser aplicado depois que a cena carregou. No cold launch
        // esse método roda antes do loadScene(), e o startEnvironment() do onAppear
        // cuida da textura inicial.
        if scene != nil {
            applyScenario(environmentManager.dayPeriod.scenarioTextureName)
        }

        if await environmentManager.refreshWeather() {
            environmentManager.updateAudioForWeather()
        }
    }

    // MARK: - SCENARIO (DIA / NOITE)

    func applyScenario(_ textureName: String) {
        scenarioTask?.cancel()
        scenarioTask = Task { [weak self] in
            guard let self, let scene = self.scene else { return }
            await self.applyScenarioTexture(textureName, in: scene)
        }
    }

    private func applyScenarioTexture(_ textureName: String, in root: Entity) async {
        guard let domeModel = skyDomeMesh(in: root),
              var modelComponent = domeModel.components[ModelComponent.self]
        else {
            print("Dome_01 não encontrado para trocar cenário")
            return
        }

        guard let cgImage = UIImage(named: textureName)?.cgImage else {
            print("Imagem de cenário '\(textureName)' não encontrada")
            return
        }

        do {
            let texture = try await TextureResource(
                image: cgImage,
                options: .init(semantic: .color)
            )

            if Task.isCancelled { return }

            var material = UnlitMaterial()
            material.color = .init(tint: .white, texture: .init(texture))

            modelComponent.materials = [material]
            domeModel.components.set(modelComponent)
        } catch {
            print("Erro ao aplicar cenário: \(error)")
        }
    }

    private func skyDomeMesh(in root: Entity) -> Entity? {
        guard let skyDome = root.findEntity(named: "SkyDome") else { return nil }

        return skyDome.findEntity(named: "Dome_01") ?? firstModelEntity(in: skyDome)
    }

    private func firstModelEntity(in entity: Entity) -> Entity? {
        if entity.components[ModelComponent.self] != nil {
            return entity
        }
        for child in entity.children {
            if let found = firstModelEntity(in: child) {
                return found
            }
        }
        return nil
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

        var target = newTsuru
        #if os(visionOS)
        if target?.name != "flappingBird___0PercentFolded" {
            target = target?.children.first(where: { $0.name == "flappingBird___0PercentFolded" }) ?? target?.children.first ?? target
        }
        #endif

        cameraManager.repositioningCameraNewToTsuru(
            animated: true,
            tsuruToFocus: target
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

}
