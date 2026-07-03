//
//  TsuruPortalView.swift
//  Nikki
//
//  Created by Alex Fraga on 30/06/26.
//

#if os(visionOS)
import NikkiProject
import RealityKit
import SwiftUI

struct TsuruPortalView: View {
    @Environment(SceneViewModel.self) private var vm

    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openWindow) private var openWindow

    /// Sessão ARKit: pose da cabeça sempre; hand tracking só em `.handLanding`.
    @State private var handManager = HandTrackingManager()

    /// Âncora na cabeça, usada apenas para o portal visual seguir o usuário.
    /// IMPORTANTE: no visionOS o transform de `AnchorEntity(.head)` é opaco
    /// para o app (privacidade) — `convert(position:to:)` nela devolve a
    /// posição como se a cabeça estivesse na origem (no chão!). Toda a
    /// matemática do voo usa a pose real do device via `WorldTrackingProvider`.
    @State private var headAnchor = AnchorEntity(.head)

    /// Raiz no espaço do mundo onde o tsuru voando é adicionado.
    @State private var worldRoot = Entity()

    /// Entidades já carregadas, uma por modelo (sem clone), reusadas entre voos.
    @State private var loadedBirds: [FlightModel: Entity] = [:]

    /// Controller da animação de bater asas do voo atual — usado para pausar
    /// o flap quando o pássaro pousa na mão e retomar quando levanta voo.
    @State private var flapController: AnimationPlaybackController?

    /// Evita disparar a mesma animação duas vezes para um único request.
    @State private var isFlying = false

    /// Correção de "frente" do modelo em voo (setada em `prepareBird`).
    @State private var currentForwardFix = simd_quatf(angle: 0, axis: [0, 1, 0])

    // Distâncias e alturas (em metros) usadas pela POC, relativas aos olhos.
    private let portalDistance: Float = 2       // portal à frente da cabeça
    private let portalHeightOffset: Float = 0.35 // portal um pouco acima da linha dos olhos
    private let hoverDistance: Float = 0.9      // ponto onde o tsuru paira
    private let hoverHeightOffset: Float = -0.05 // praticamente na linha dos olhos
    private let tsuruScale: Float = 0.5         // tamanho do tsuru
    private let birdScale: Float = 0.0005         // tamanho do passaro

    // MARK: Se um modelo voar de costas ou de lado, ajuste o ângulo dele (0, .pi, .pi/2, -.pi/2).
    /// Correção do eixo "frente" de cada modelo, para o bico apontar na
    /// direção do voo (o "frente" do RealityKit é -Z).
    private func modelForwardFix(for model: FlightModel) -> simd_quatf {
        switch model {
        case .tsuru:
            return simd_quatf(angle: -.pi / 2, axis: [0, 1, 0])
        case .flatBird:
            return simd_quatf(angle: .pi/2, axis: [0, 1, 0])
        }
    }

    var body: some View {
        RealityView { content in
            content.add(worldRoot)

            // Portal/plano simples, semitransparente, à frente do usuário.
            let portal = makePortal()
            headAnchor.addChild(portal)
            content.add(headAnchor)
        }
        .onChange(of: vm.pocFlightRequest) { _, request in
            guard let request else { return }
            // Consome o request para não re-disparar em recomposições.
            vm.pocFlightRequest = nil
            Task { await runFlight(request) }
        }
        .onDisappear {
            handManager.stop()
        }
    }

    // MARK: - Cenário

    /// Plano semitransparente que representa a "tela"/portal de onde o tsuru sai.
    private func makePortal() -> ModelEntity {
        var material = SimpleMaterial()
        material.color = .init(tint: .white.withAlphaComponent(0.25))
        let portal = ModelEntity(
            mesh: .generatePlane(width: 1.0, height: 1.2, cornerRadius: 0.05),
            materials: [material]
        )
        // À frente do rosto (-z), um pouco acima da linha dos olhos.
        portal.position = [0, portalHeightOffset, -portalDistance]
        return portal
    }

    // MARK: - Disparo

    private func runFlight(_ kind: TsuruFlightKind) async {
        guard !isFlying else { return }
        isFlying = true

        switch kind {
        case .simpleFlight(let model):
            await runSimpleFlight(model)
        case .handLanding(let model):
            await runHandLanding(model)
        }

        isFlying = false
        // Voo terminou: fecha o portal e volta para a tela de botões.
        await dismissImmersiveSpace()
        openWindow(id: "Launcher")
    }

    // MARK: - Pose da cabeça (via WorldTrackingProvider)

    /// Posição dos olhos e direção horizontal do olhar, no mundo.
    /// Fallback (Simulador sem pose): olhos a 1.3 m do chão olhando para -z.
    private func headPose() -> (position: SIMD3<Float>, forward: SIMD3<Float>) {
        guard let m = handManager.deviceTransform else {
            return (SIMD3<Float>(0, 1.3, 0), SIMD3<Float>(0, 0, -1))
        }
        let position = SIMD3<Float>(m.columns.3.x, m.columns.3.y, m.columns.3.z)
        // -Z do device é a direção do olhar; achata para não apontar pro chão/teto.
        var forward = -SIMD3<Float>(m.columns.2.x, m.columns.2.y, m.columns.2.z)
        forward.y = 0
        forward = simd_length(forward) > 0.001
            ? simd_normalize(forward)
            : SIMD3<Float>(0, 0, -1)
        return (position, forward)
    }

    /// Espera a primeira pose válida do device (a sessão demora alguns frames).
    private func waitForHeadPose() async {
        for _ in 0..<30 where handManager.deviceTransform == nil {
            try? await Task.sleep(for: .milliseconds(50))
        }
    }

    /// Posição mundial do portal (origem do voo), um pouco acima da linha dos olhos.
    private func portalWorldPosition() -> SIMD3<Float> {
        let head = headPose()
        return head.position + head.forward * portalDistance
            + SIMD3<Float>(0, portalHeightOffset, 0)
    }

    /// Ponto ~`hoverDistance` à frente do rosto, na altura dos olhos, no mundo.
    private func hoverWorldPosition() -> SIMD3<Float> {
        let head = headPose()
        return head.position + head.forward * hoverDistance
            + SIMD3<Float>(0, hoverHeightOffset, 0)
    }

    /// Ponto distante à frente do usuário para o tsuru ir embora, subindo.
    private func awayWorldPosition() -> SIMD3<Float> {
        let head = headPose()
        return head.position + head.forward * 8 + SIMD3<Float>(0, 1.5, 0)
    }

    // MARK: - Pássaro (tsuru / FlatBird)

    /// Carrega o modelo direto do asset (sem cena da árvore, sem clone),
    /// reaproveitando a mesma entidade entre voos. O load acontece aqui (dentro do
    /// Task do voo) e não em `.task`, para não ser cancelado pela transição de
    /// janela/space — o que causava o `CancellationError`.
    private func loadBirdIfNeeded(_ model: FlightModel) async -> Entity? {
        if let cached = loadedBirds[model] { return cached }
        do {
            let entity: Entity
            switch model {
            case .tsuru:
                entity = try await Entity(named: "tsuru", in: nikkiProjectBundle)
            case .flatBird:
                // FlatBird.usdz fica em Features/3DModels, no bundle do app.
                entity = try await Entity(named: "FlatBird")
            }
            entity.isEnabled = false
            loadedBirds[model] = entity
            return entity
        } catch {
            print("[TsuruPOC] Falha ao carregar o asset de \(model): \(error)")
            return nil
        }
    }

    /// Prepara a entidade do modelo na origem do portal e inicia o flap.
    /// Retorna `nil` se o asset não pôde ser carregado.
    private func prepareBird(_ model: FlightModel) async -> Entity? {
        guard let bird = await loadBirdIfNeeded(model) else { return nil }
        currentForwardFix = modelForwardFix(for: model)
        bird.removeFromParent()
        switch model {
        case .tsuru:
            bird.scale = [tsuruScale, tsuruScale, tsuruScale]
        case .flatBird:
            bird.scale = [birdScale, birdScale, birdScale]
        }
        bird.position = portalWorldPosition()
        bird.isEnabled = true
        worldRoot.addChild(bird)
        playFlap(on: bird)
        return bird
    }

    /// Toca a animação de bater asas embutida no asset, em loop, guardando o
    /// controller para poder pausar/retomar durante o pouso na mão.
    private func playFlap(on entity: Entity) {
        if let anim = entity.availableAnimations.first {
            flapController = entity.playAnimation(
                anim.repeat(),
                transitionDuration: 0.3,
                startsPaused: false
            )
        }
    }

    /// Finaliza o voo: esconde o pássaro e o remove da cena.
    private func retireBird(_ entity: Entity) {
        entity.stopAllAnimations()
        flapController = nil
        entity.isEnabled = false
        entity.removeFromParent()
    }

    // MARK: - Movimento

    /// Orientação que faz o tsuru encarar `direction`: só yaw (giro em torno
    /// de Y) mais um leve pitch, para nunca rolar/inclinar de lado.
    private func orientationFacing(_ direction: SIMD3<Float>, fallback: simd_quatf) -> simd_quatf {
        let length = simd_length(direction)
        guard length > 0.0001 else { return fallback }
        let d = direction / length

        var flat = SIMD3<Float>(d.x, 0, d.z)
        guard simd_length(flat) > 0.001 else { return fallback }
        flat = simd_normalize(flat)

        // Ângulo que leva o "frente" do RealityKit (-Z) até `flat`.
        let yaw = simd_quatf(angle: atan2f(-flat.x, -flat.z), axis: [0, 1, 0])
        // Pitch suave (60% do real, limitado) — sobe/desce o bico sem cabrar.
        let pitchAngle = max(-0.5, min(0.5, asinf(max(-1, min(1, d.y))) * 0.6))
        let pitch = simd_quatf(angle: pitchAngle, axis: [1, 0, 0])
        return yaw * pitch * currentForwardFix
    }

    /// Ponto e tangente de uma Bézier cúbica.
    private func bezier(
        _ p0: SIMD3<Float>, _ p1: SIMD3<Float>,
        _ p2: SIMD3<Float>, _ p3: SIMD3<Float>, _ t: Float
    ) -> SIMD3<Float> {
        let u = 1 - t
        return u * u * u * p0 + 3 * u * u * t * p1 + 3 * u * t * t * p2 + t * t * t * p3
    }

    private func bezierTangent(
        _ p0: SIMD3<Float>, _ p1: SIMD3<Float>,
        _ p2: SIMD3<Float>, _ p3: SIMD3<Float>, _ t: Float
    ) -> SIMD3<Float> {
        let u = 1 - t
        return 3 * u * u * (p1 - p0) + 6 * u * t * (p2 - p1) + 3 * t * t * (p3 - p2)
    }

    /// Voa suavemente do ponto atual até `target` seguindo uma curva Bézier
    /// com um leve arco e desvio lateral, atualizada a cada frame (~60 Hz).
    /// A orientação é interpolada (slerp) na direção do movimento, então o
    /// tsuru faz curvas suaves em vez de "teleportar" e girar de repente.
    ///
    /// - Parameters:
    ///   - target: destino final no espaço do mundo.
    ///   - duration: tempo total do trajeto.
    ///   - arcHeight: quanto a curva sobe no meio do caminho.
    ///   - lateralArc: desvio lateral máximo (sorteado) da curva.
    private func flySmooth(
        _ entity: Entity,
        to target: SIMD3<Float>,
        duration: TimeInterval,
        arcHeight: Float = 0.25,
        lateralArc: Float = 0.2
    ) async {
        let start = entity.position(relativeTo: nil)
        let travel = target - start
        let distance = simd_length(travel)
        guard distance > 0.01 else { return }

        let up = SIMD3<Float>(0, 1, 0)
        var right = simd_cross(travel / distance, up)
        right = simd_length(right) > 0.001 ? simd_normalize(right) : SIMD3<Float>(1, 0, 0)

        // Pontos de controle: arco para cima com curvinha lateral aleatória.
        let side = Float.random(in: -lateralArc...lateralArc)
        let c1 = start + travel * 0.33 + up * arcHeight + right * side
        let c2 = start + travel * 0.66 + up * (arcHeight * 0.5) + right * (side * 0.5)

        let frameDT: TimeInterval = 1.0 / 60.0
        let steps = max(1, Int(duration / frameDT))
        var orientation = entity.orientation(relativeTo: nil)

        for i in 1...steps {
            let raw = Float(i) / Float(steps)
            let t = raw * raw * (3 - 2 * raw) // ease-in-out

            var position = bezier(start, c1, c2, target, t)
            // Balancinho vertical de voo, sumindo perto do destino.
            position.y += sinf(raw * .pi * 4) * 0.02 * (1 - raw)

            let velocity = bezierTangent(start, c1, c2, target, t)
            let desired = orientationFacing(velocity, fallback: orientation)
            orientation = simd_slerp(orientation, desired, 0.15)

            entity.setPosition(position, relativeTo: nil)
            entity.setOrientation(orientation, relativeTo: nil)
            try? await Task.sleep(for: .seconds(frameDT))
        }
        entity.setPosition(target, relativeTo: nil)
    }

    /// Mantém o tsuru "pairando" em torno do ponto à frente dos olhos com um
    /// flutuar suave, sempre encarando o usuário. O centro é recalculado a
    /// partir da pose da cabeça, então ele acompanha se o usuário se mover.
    private func hoverInPlace(_ entity: Entity, seconds: TimeInterval) async {
        let frameDT: TimeInterval = 1.0 / 60.0
        let steps = max(1, Int(seconds / frameDT))
        var position = entity.position(relativeTo: nil)
        var orientation = entity.orientation(relativeTo: nil)

        for i in 0..<steps {
            let time = Float(i) * Float(frameDT)
            var target = hoverWorldPosition()
            // Flutuar de "asa parada no ar": sobe/desce e balança de leve.
            target.y += sinf(time * 2.2) * 0.03
            target.x += sinf(time * 1.3) * 0.015

            position = simd_mix(position, target, SIMD3<Float>(repeating: 0.06))

            // Encara o usuário enquanto paira.
            let head = headPose()
            let desired = orientationFacing(head.position - position, fallback: orientation)
            orientation = simd_slerp(orientation, desired, 0.08)

            entity.setPosition(position, relativeTo: nil)
            entity.setOrientation(orientation, relativeTo: nil)
            try? await Task.sleep(for: .seconds(frameDT))
        }
    }

    // MARK: - Variação 1: voo simples

    private func runSimpleFlight(_ model: FlightModel) async {
        // Só a pose da cabeça — não requer permissão do usuário.
        _ = await handManager.start(hands: false)
        await waitForHeadPose()

        // O flap fica ligado (em loop) durante o voo simples inteiro.
        guard let bird = await prepareBird(model) else { return }

        // Portal -> frente do rosto (altura dos olhos), em curva suave.
        await flySmooth(bird, to: hoverWorldPosition(), duration: 4.0)

        // Paira por alguns segundos encarando o usuário.
        await hoverInPlace(bird, seconds: 3.0)

        // Voa para longe, subindo, e some.
        await flySmooth(bird, to: awayWorldPosition(), duration: 3.5, arcHeight: 0.6, lateralArc: 0.4)
        retireBird(bird)
        handManager.stop()
    }

    // MARK: - Variação 2: pouso na mão (hand tracking)

    private func runHandLanding(_ model: FlightModel) async {
        // Decisão da POC: sem hand tracking (Simulador), apenas loga e aborta.
        let available = await handManager.start(hands: true)
        guard available else {
            print("[TsuruPOC] Pouso na mão ignorado — rode no device.")
            return
        }
        await waitForHeadPose()

        guard let bird = await prepareBird(model) else { return }

        // Portal -> frente dos olhos, para o usuário ver o pássaro chegando.
        await flySmooth(bird, to: hoverWorldPosition(), duration: 4.0)

        // Paira na frente do rosto enquanto espera uma mão válida (timeout).
        var hand: SIMD3<Float>?
        for _ in 0..<10 {
            if let p = handManager.latestHandPosition {
                hand = p
                break
            }
            await hoverInPlace(bird, seconds: 0.6)
        }

        guard hand != nil else {
            print("[TsuruPOC] Nenhuma mão detectada a tempo — abortando.")
            await flySmooth(bird, to: awayWorldPosition(), duration: 3.0, arcHeight: 0.6)
            retireBird(bird)
            handManager.stop()
            return
        }

        // Desce suavemente até a palma (posição mais recente da mão).
        let landingTarget = (handManager.latestHandPosition ?? hand!) + SIMD3<Float>(0, 0.01, 0)
        await flySmooth(bird, to: landingTarget, duration: 2.0, arcHeight: 0.15, lateralArc: 0.1)

        // FlatBird pousado não bate asas; retoma quando levantar voo.
        if model == .flatBird {
            flapController?.pause()
        }

        // Pousado: segue a mão com interpolação (sem teleportar), encarando o usuário.
        let frameDT: TimeInterval = 1.0 / 60.0
        let landingSeconds: TimeInterval = 4
        var position = bird.position(relativeTo: nil)
        var orientation = bird.orientation(relativeTo: nil)
        for _ in 0..<Int(landingSeconds / frameDT) {
            if let palm = handManager.latestHandPosition {
                let target = palm + SIMD3<Float>(0, 0.01, 0)
                position = simd_mix(position, target, SIMD3<Float>(repeating: 0.25))
                let head = headPose()
                let desired = orientationFacing(head.position - position, fallback: orientation)
                orientation = simd_slerp(orientation, desired, 0.08)
                bird.setPosition(position, relativeTo: nil)
                bird.setOrientation(orientation, relativeTo: nil)
            }
            try? await Task.sleep(for: .seconds(frameDT))
        }

        // Levanta voo (voltando a bater asas) e some.
        if model == .flatBird {
            flapController?.resume()
        }
        await flySmooth(bird, to: awayWorldPosition(), duration: 3.0, arcHeight: 0.6, lateralArc: 0.4)
        retireBird(bird)
        handManager.stop()
    }
}
#endif
