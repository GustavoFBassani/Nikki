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

    /// Hand tracking só é usado na variação `.handLanding`.
    @State private var handManager = HandTrackingManager()

    /// Âncora na cabeça: serve de referência tanto para posicionar o portal
    /// quanto para calcular o ponto-alvo "à frente do rosto".
    @State private var headAnchor = AnchorEntity(.head)

    /// Raiz no espaço do mundo onde o tsuru voando é adicionado.
    @State private var worldRoot = Entity()

    /// A única entidade do tsuru desta POC (carregada do asset, sem clone).
    @State private var tsuru: Entity?

    /// Evita disparar a mesma animação duas vezes para um único request.
    @State private var isFlying = false

    // Distâncias e alturas (em metros) usadas pela POC, relativas à cabeça.
    private let portalDistance: Float = 2   // portal à frente da cabeça (-z)
    private let hoverDistance: Float = 0.6     // ponto onde o tsuru paira
    private let spawnHeight: Float = 2      // altura onde o tsuru nasce (acima da linha dos olhos)
    private let hoverHeight: Float = 0.4      // altura onde o tsuru paira na sua frente
    private let tsuruScale: Float = 0.5       // tamanho do tsuru

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
        portal.position = [0, spawnHeight, -portalDistance]
        return portal
    }

    // MARK: - Disparo

    private func runFlight(_ kind: TsuruFlightKind) async {
        guard !isFlying else { return }
        isFlying = true

        switch kind {
        case .simpleFlight:
            await runSimpleFlight()
        case .handLanding:
            await runHandLanding()
        }

        isFlying = false
        // Voo terminou: fecha o portal e volta para a tela de botões.
        await dismissImmersiveSpace()
        openWindow(id: "Launcher")
    }

    /// Posição mundial do portal (origem do voo), um pouco acima da linha dos olhos.
    private func portalWorldPosition() -> SIMD3<Float> {
        let local = SIMD3<Float>(0, spawnHeight, -portalDistance)
        return headAnchor.convert(position: local, to: nil)
    }

    /// Ponto ~`hoverDistance` à frente do rosto (na sua direção), no mundo.
    private func hoverWorldPosition() -> SIMD3<Float> {
        let local = SIMD3<Float>(0, hoverHeight, -hoverDistance)
        return headAnchor.convert(position: local, to: nil)
    }

    /// Carrega o modelo do tsuru direto do asset (sem cena da árvore, sem clone),
    /// reaproveitando a mesma entidade entre voos. O load acontece aqui (dentro do
    /// Task do voo) e não em `.task`, para não ser cancelado pela transição de
    /// janela/space — o que causava o `CancellationError`.
    private func loadTsuruIfNeeded() async -> Entity? {
        if let tsuru { return tsuru }
        do {
            let entity = try await Entity(named: "tsuru", in: nikkiProjectBundle)
            entity.isEnabled = false
            tsuru = entity
            return entity
        } catch {
            print("[TsuruPOC] Falha ao carregar o asset 'tsuru': \(error)")
            return nil
        }
    }

    /// Prepara a única entidade do tsuru na origem do portal e inicia o flap.
    /// Retorna `nil` se o asset não pôde ser carregado.
    private func prepareTsuru() async -> Entity? {
        guard let tsuru = await loadTsuruIfNeeded() else { return nil }
        tsuru.removeFromParent()
        tsuru.scale = [tsuruScale, tsuruScale, tsuruScale]
        tsuru.position = portalWorldPosition()
        tsuru.isEnabled = true
        worldRoot.addChild(tsuru)
        playFlap(on: tsuru)
        return tsuru
    }

    /// Toca a animação de bater asas embutida no asset.
    private func playFlap(on entity: Entity) {
        if let anim = entity.availableAnimations.first {
            entity.playAnimation(anim.repeat(), transitionDuration: 0.3, startsPaused: false)
        }
    }

    /// Move o tsuru até `target`, orientando-o para encarar essa posição.
    private func fly(_ entity: Entity, to target: SIMD3<Float>, duration: TimeInterval) {
        let from = entity.position(relativeTo: nil)
        entity.look(at: target, from: from, relativeTo: nil)
        var transform = entity.transform
        transform.translation = target
        entity.move(to: transform, relativeTo: worldRoot, duration: duration, timingFunction: .easeInOut)
    }

    /// Voa do ponto atual até `target` de forma "tremulada", como um objeto real:
    /// o trajeto é quebrado em vários segmentos curtos, cada um com um pequeno
    /// desvio aleatório de altura e lateral (jitter). Em cada segmento o tsuru é
    /// reorientado para encarar o próximo ponto, dando a sensação de voo errático.
    ///
    /// - Parameters:
    ///   - target: destino final no espaço do mundo.
    ///   - totalDuration: tempo total aproximado do trajeto.
    ///   - segments: em quantos pedaços o caminho é dividido (mais = mais tremido).
    ///   - wobble: amplitude máxima (em metros) do desvio lateral/vertical.
    private func flyWobbly(
        _ entity: Entity,
        to target: SIMD3<Float>,
        totalDuration: TimeInterval,
        segments: Int = 6,
        wobble: Float = 0.18
    ) async {
        let start = entity.position(relativeTo: nil)
        let segDuration = totalDuration / TimeInterval(segments)

        // Vetor "direita" relativo à direção do voo, para desviar lateralmente.
        let forward = simd_normalize(target - start)
        let worldUp = SIMD3<Float>(0, 1, 0)
        let right = simd_length(simd_cross(forward, worldUp)) > 0.001
            ? simd_normalize(simd_cross(forward, worldUp))
            : SIMD3<Float>(1, 0, 0)

        for i in 1...segments {
            let t = Float(i) / Float(segments)
            // Ponto base interpolado linearmente em direção ao alvo.
            let base = simd_mix(start, target, SIMD3<Float>(repeating: t))

            // Desvio aleatório, que diminui conforme chega perto do alvo (chega suave).
            let damping = 1.0 - t
            let lateral = Float.random(in: -wobble...wobble) * damping
            let vertical = Float.random(in: -wobble...wobble) * damping

            let waypoint = (i == segments)
                ? target  // último segmento aterrissa exatamente no alvo
                : base + right * lateral + worldUp * vertical

            fly(entity, to: waypoint, duration: segDuration)
            try? await Task.sleep(for: .seconds(segDuration))
        }
    }

    /// Finaliza o voo: esconde o tsuru e o remove da cena.
    private func retireTsuru(_ entity: Entity) {
        entity.stopAllAnimations()
        entity.isEnabled = false
        entity.removeFromParent()
    }

    // MARK: - Variação 1: voo simples

    private func runSimpleFlight() async {
        guard let tsuru = await prepareTsuru() else { return }

        // Portal -> frente do rosto, voando de forma tremulada (não em linha reta).
        await flyWobbly(tsuru, to: hoverWorldPosition(), totalDuration: 3.5)

        // Paira por alguns segundos, com um leve flutuar no lugar.
        await hoverInPlace(tsuru, around: hoverWorldPosition(), seconds: 3.0)

        // Voa para longe (-z, bem à frente) e some — também tremulado.
        let away = headAnchor.convert(position: SIMD3<Float>(0, 0.6, -8), to: nil)
        await flyWobbly(tsuru, to: away, totalDuration: 3.0, wobble: 0.25)
        retireTsuru(tsuru)
    }

    /// Mantém o tsuru "pairando" em torno de `center` com pequenas oscilações,
    /// para não ficar congelado no ar enquanto espera.
    private func hoverInPlace(_ entity: Entity, around center: SIMD3<Float>, seconds: TimeInterval) async {
        let steps = max(1, Int(seconds / 0.6))
        for _ in 0..<steps {
            let jitter = SIMD3<Float>(
                Float.random(in: -0.05...0.05),
                Float.random(in: -0.04...0.04),
                Float.random(in: -0.05...0.05)
            )
            // Só translada (mantém a orientação atual) para não girar enquanto paira.
            var transform = entity.transform
            transform.translation = center + jitter
            entity.move(to: transform, relativeTo: worldRoot, duration: 0.6, timingFunction: .easeInOut)
            try? await Task.sleep(for: .seconds(0.6))
        }
    }

    // MARK: - Variação 2: pouso na mão (hand tracking)

    private func runHandLanding() async {
        // Decisão da POC: sem hand tracking (Simulador), apenas loga e aborta.
        let available = await handManager.start()
        guard available else {
            print("[TsuruPOC] Pouso na mão ignorado — rode no device.")
            return
        }

        guard let tsuru = await prepareTsuru() else { return }

        // Aguarda uma posição de mão válida (com timeout curto).
        var hand: SIMD3<Float>?
        for _ in 0..<60 {
            if let p = handManager.latestHandPosition {
                hand = p
                break
            }
            try? await Task.sleep(for: .milliseconds(100))
        }

        guard let handPosition = hand else {
            print("[TsuruPOC] Nenhuma mão detectada a tempo — abortando.")
            retireTsuru(tsuru)
            handManager.stop()
            return
        }

        // Portal -> mão.
        fly(tsuru, to: handPosition, duration: 2.0)
        try? await Task.sleep(for: .seconds(2.0))

        // Pousa: segue a mão por alguns segundos.
        let landingSeconds = 4
        for _ in 0..<(landingSeconds * 10) {
            if let p = handManager.latestHandPosition {
                tsuru.position = p
            }
            try? await Task.sleep(for: .milliseconds(100))
        }

        // Levanta voo e some.
        let away = headAnchor.convert(position: SIMD3<Float>(0, 0.4, -8), to: nil)
        fly(tsuru, to: away, duration: 2.0)
        try? await Task.sleep(for: .seconds(2.0))
        retireTsuru(tsuru)
        handManager.stop()
    }
}
#endif
