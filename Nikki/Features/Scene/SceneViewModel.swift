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
    
    //MARK: -SCENE ENTITIES
    var scene: Entity?
    var tree: Entity?
    var scrapImage: UIImage?
    var paperStyle: String?
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
    
    // MARK: - Motivation
    private let dataManager = SwiftDataManager.shared
    private var currentMotivation: Motivation?
    var motivationText: String = ""
    var datadamotivacaodosguri: Date = Date()
    /// Entidade que controla para onde a camera está olhando
    /// Deve estar atualizando para mudar o foco da camera
    private var cameraLook: SIMD3<Float>?
    ///Bool pra controlar o foco da camera
    var isFocusedOnTsuru = false
    var isFocusedOnBandstand = false
    
    var tsurus: [Entity] = [] //provisorio
    var count: Float = 1.0 // provisorio
    // Objects positions
    var obj: Entity?
    
    var data = SwiftDataManager.shared
    var orderedPages: [Page?] = []
    var positions: [SIMD3<Float>] = [
        SIMD3<Float>(-3.77,  0.19, 1.87),
        SIMD3<Float>(-3.54, 0.05, 2.026),
        SIMD3<Float>(-3.06, 0.13, 1.85),
        SIMD3<Float>(-3.12, 0.17, 1.39),
        SIMD3<Float>(-2.53, -0.396, 2.2),
        SIMD3<Float>(-2.26, -0.54, 1.999),
        SIMD3<Float>(-1.93, -0.786, 1.88),
        SIMD3<Float>(-3.03, 0.199, 1.052),
        SIMD3<Float>(-0.976, 0.44, 1.153),
        SIMD3<Float>(-0.879,  0.53, 0.856),
        SIMD3<Float>(-2.53,  -0.52, 4.97),
        SIMD3<Float>(-2.2,  -0.37, 4.998),
        SIMD3<Float>(-1.878,  -0.25, 5.12),
        SIMD3<Float>(-1.17,  0.27, 5.398),
        SIMD3<Float>(-1.45,  -0.26, 5.24),
        SIMD3<Float>(-0.85,  0.55, 5.398),
        SIMD3<Float>(-4.198, 0.27, 3.91),
        SIMD3<Float>(-4.34, 0.56, 4.14),
        SIMD3<Float>(-4.53, 1.03, 4.48),
        SIMD3<Float>(-4.75, 1.199, 4.767),
        SIMD3<Float>(-5.05, 1.577, 4.767),
        SIMD3<Float>(-2.44, -0.516, 3.694),
        SIMD3<Float>(-2.308, -0.327, 3.325),
        SIMD3<Float>(-3.44, -0.12, 4.908),
        SIMD3<Float>(-3.34, 0.29, 5.22),
        SIMD3<Float>(-2.32, 0.14, 1.856),
        SIMD3<Float>(0.465, 0.17, 3.51),
        SIMD3<Float>(-3.73, 0.72, 5.769),
        SIMD3<Float>(-3.84, 0.84, 6.21),
        SIMD3<Float>(-3.565, 1.017, 5.55)
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
            tsuru = scene.findEntity(named: "tsuru")
          
            if let bandstand = scene.findEntity(named: "Japan_HW") {
                bandstand.generateCollisionShapes(recursive: true)
                bandstand.components[InputTargetComponent.self] = .init()
            }

            //            await appliyngTextureToTsuru(scrapImage: nil)
            // Cria uma nova câmera perspectiva
            // PerspectiveCamera simula visão humana com perspectiva realista
            let camera = PerspectiveCamera()
            scene.addChild(camera)
            self.camera = camera
            
            try orderedPages = data.fetchAllPages()
            await loadPages()
            
            // Posiciona a câmera usando os valores iniciais de theta, phi e distance
            updateCamera()
        } catch {
            print("Erro ao carregar cena: \(error)")
        }
    }
    
    //MARK: - TSURU FUNCTIONS
    func playTsuruAnimation() {
        guard let lastTsuru = tsurus.last else { return } // ve o ultimo tsuru adicionado
        
        if let tsuruAnimation = lastTsuru.availableAnimations.first {
            lastTsuru.playAnimation(tsuruAnimation, transitionDuration: 0.3, startsPaused: false)
        }
        
    }
    
    func addNewTsuru() {
        let newTsuru = tsuru?.clone(recursive: true)
        count += 1
        if let newTsuru {
            fixTsuruPos(newTsuru)
            newTsuru.position = [0.5, 0.5 + count, 0.5] // mexe no tsuru
            
            tsurus.append(newTsuru)
            scene?.addChild(newTsuru)
        }
        repositioningCameraNewToTsuru()
    } //ok
    
    func fixTsuruPos(_ e: Entity) {
        guard let newFlapBird = e.children.first(where: { $0.name == "flappingBird___0PercentFolded" }) else { return } // acessa o flabird do tsuru
        newFlapBird.scale = [0.0005,0.0005,0.0005] // corrige a escala do flabird
        newFlapBird.position  = [0,0,0] // relativa ao modelo pai (tsuru)
    } // ok
    
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
            
            
            guard let tsuru = tsurus.last?.children.first(where: { $0.name == "flappingBird___0PercentFolded" }) else {
                return
            }
            
            if var modelComponent = tsuru.components[ModelComponent.self] {
                modelComponent.materials = [material]
                tsuru.components[ModelComponent.self] = modelComponent
                
            }
        } catch {
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
        theta += dTheta * 0.0005
        
        // Atualiza phi (rotação vertical - Elevação)
        // Invertido (-=) para que arrastar para baixo leve a câmera para o topo (phi -> 0)
        phi -= dPhi * 0.0005
        
        // Limita phi entre pi/60 e 57pi/100
        // Phi = 0 é o Polo Norte (Topo)
        phi = max(Float.pi / 6, min(51 * Float.pi / 100, phi))
        
        // Recalcula e aplica a nova posição da câmera
        updateCamera()
    } //ok
    
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
    } // ok
    
    func repositioningCameraNewToTsuru(animated: Bool = true) {
        guard let tsuruToFocus = tsurus.last else { return }
        
        // Foca lookAt no tsuru que vai olhar
        let look = tsuruToFocus.position(relativeTo: nil)
        
        let targetRho:   Float = 0.5
        let targetTheta: Float = self.theta
        let targetPhi:   Float = self.phi
        
        if animated {
            animateCamera(
                toRho: targetRho,
                toTheta: targetTheta,
                toPhi: targetPhi,
                toLookAt: look,
                duration: 1.2
            )
        } else {
            cameraLook = look
            rho = targetRho
            theta = targetTheta
            phi = targetPhi
            updateCamera()
        }
        
        isFocusedOnTsuru = true
    }
    
    func repositioningCameraToTree(animated: Bool = true) {
        guard let tree else { return }
        
        //Posicao da arvore e para onde olhar, que nem antes
        let treePos = tree.position
        let look = SIMD3<Float>(
            treePos.x - 4,
            treePos.y,
            treePos.z
        )
        
        // Define angulos especificos
        let targetTheta: Float = -4.776666
        let targetPhi:   Float = self.phi
        let targetRho:   Float = 21.0
        
        if animated {
            animateCamera(
                toRho: targetRho,
                toTheta: targetTheta,
                toPhi: targetPhi,
                toLookAt: look,
                duration: 1.5
            )
        } else {
            self.cameraLook = look
            self.rho = targetRho
            self.theta = targetTheta
            self.phi = targetPhi
            updateCamera()
        }
        
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
            // Faz a câmera sempre olhar para o centro da cena (origem 0,0,0)
            camera.look(at: cameraLook, from: camera.position, relativeTo: nil)
            
        }
    } //ok
    
    func focusOnBandstand() {
        // Posicao do coreto
        let look = SIMD3<Float>(-7.3, -0.3, -8.2)
        
        // Posicao da camera
        let desiredPos = SIMD3<Float>(-3.5, -0.3, -8.2)
        
        // Vetor do centro (look) até a câmera
        let distance = desiredPos - look
        let x = distance.x
        let y = distance.y
        let z = distance.z
        
        // Converte pra coordenadas esfericas
        let rho   = simd_length(distance)
        let phi   = acosf(y / rho)
        let theta = atan2f(z, x)
        
        animateCamera(
            toRho: rho,
            toTheta: theta,
            toPhi: phi,
            toLookAt: look,
            duration: 1.5
        )
    }
    
    func animateCamera(
        toRho: Float? = nil,
        toTheta: Float? = nil,
        toPhi: Float? = nil,
        toLookAt: SIMD3<Float>? = nil,
        duration: TimeInterval = 1.5
    ) {
        guard let camera else { return }
        
        // Estado atual
        let currentRho   = self.rho
        let currentTheta = self.theta
        let currentPhi   = self.phi
        let currentLook  = self.cameraLook ?? toLookAt ?? .zero
        
        // Valor passado ou mantem atual em caso de nil
        let targetRho   = toRho   ?? currentRho
        let targetTheta = toTheta ?? currentTheta
        let targetPhi   = toPhi   ?? currentPhi
        let targetLook  = toLookAt ?? currentLook
        
        // Calcula a posição final da câmera em volta do lookAt(target look)
        let targetPos = cameraPosition(
            rho: targetRho,
            theta: targetTheta,
            phi: targetPhi,
            center: targetLook
        )
        
        // Mexe com transform (matriz de transformacao)
        // onde a câmera está agora
        let startTransform = camera.transform
        
        // Aqui atribui na camera a posicao final, onde ela deve parar ao final da animacao.
        // Isso e feito pq assim o reality kit calcula a matriz de transformacao final, sem precisar fazer esse calculo na mao
        camera.position = targetPos
        camera.look(at: targetLook, from: targetPos, relativeTo: nil)
        let targetTransform = camera.transform
        
        // Aqui volta a camera pra posicao inicial, uma vez que ja calculamos a matriz final e queremos animar ela ate la
        camera.transform = startTransform
        
        // Atualiza as variaveis de controle pros gestures nao ficarem desatualizados
        self.rho        = targetRho
        self.theta      = targetTheta
        self.phi        = targetPhi
        self.cameraLook = targetLook
        
        // Realiza a animacao com interpolacao nativa do framework
        camera.move(
            to: targetTransform,
            relativeTo: nil,
            duration: duration,
            timingFunction: .easeInOut
        )
    }
    
    private func cameraPosition(
        rho: Float,
        theta: Float,
        phi: Float,
        center: SIMD3<Float> //Center é o lookAt, o objeto que queremos focar
    ) -> SIMD3<Float> {
        let x = rho * sin(phi) * cos(theta) + center.x
        let y = rho * cos(phi)               + center.y
        let z = rho * sin(phi) * sin(theta) + center.z
        return [x, y, z]
    }
    
    
    func loadPages() async {
        do {
            guard let scene else {
                print("Cena não carregada")
                return
            }
            
            print("Scraps count", orderedPages.count)
            for i in 0..<orderedPages.count {
                if orderedPages.count < 30 {
                    
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
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    func handleTap(on entity: Entity) {
        print(" Tocou na entidade: \(entity.name)")
        
        var current: Entity? = entity
        
        // Sobe pela hierarquia até encontrar uma entidade registrada no dicionário
        while let ent = current {
            print("Encontrou entidade associada: \(ent.name)")
            if let page = dict[ent] {
                currentPage = page
                return
            }
            
            // Coreto. O && serve pra ele nao ficar animando posicao estatica caso o usuario fique clicando varias vezes no coreto, ai da uma travada (melhor previnir vai saber)
            if ent.name == "Japan_HW" && !isFocusedOnBandstand {
                focusOnBandstand()
                isFocusedOnBandstand = true
                return
            }
            current = ent.parent
        }
        
        print("Nenhuma entidade registrada encontrada na hierarquia")
    }
    
    

    // MARK: - Motivation Methods
    
    func loadMotivation() {
        do {
            if let motivation = try dataManager.fetchMotivation() {
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
                try dataManager.updateMotivation(motivation)
            } else {
                let newMotivation = Motivation(text: motivationText)
                try dataManager.saveMotivation(newMotivation)
                currentMotivation = newMotivation
            }
        } catch {
            print("Erro ao salvar motivação: \(error)")
        }
    }
}


