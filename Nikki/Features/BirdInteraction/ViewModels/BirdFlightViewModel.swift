//
//  BirdFlightViewModel.swift
//  Nikki
//
//  Created by Alex Fraga on 30/06/26.
//

#if os(visionOS)
import Foundation
import RealityKit
import simd

/// Orquestra as animações de voo do pássaro (voo simples e pouso na mão),
/// coordenando pose da cabeça (`HeadPoseProvider`), carga/flap do modelo
/// (`BirdModelLoader`) e hand tracking (`HandTrackingManager`).
///
/// A matemática de trajetória e orientação vive aqui; a view apenas monta o
/// `RealityView` e dispara `runFlight`.
@MainActor
final class BirdFlightViewModel {

    private let handManager: HandTrackingManager
    private let birdLoader: BirdModelLoader
    private let headPose: HeadPoseProvider

    /// Raiz no espaço do mundo onde o pássaro voando é adicionado.
    let worldRoot = Entity()

    /// Evita disparar a mesma animação duas vezes para um único request.
    private var isFlying = false

    /// Correção da orientação do modelo em voo (setada em `prepareBird`).
    /// Necessária, pois às vezes o modelo vem olhando para o lado por padrão.
    private var currentForwardFix = simd_quatf(angle: 0, axis: [0, 1, 0])

    init() {
        let handManager = HandTrackingManager()
        self.handManager = handManager
        self.birdLoader = BirdModelLoader()
        self.headPose = HeadPoseProvider(handManager: handManager)
    }

    // MARK: - Disparo

    /// Roda a variação pedida e, ao final, sinaliza que o voo terminou.
    /// Retorna quando a animação completa acaba (a view fecha o space depois).
    func runFlight(_ kind: TsuruFlightKind) async {
        guard !isFlying else { return }
        isFlying = true

        switch kind {
        case .simpleFlight(let model):
            await runSimpleFlight(model)
        case .handLanding(let model):
            await runHandLanding(model)
        case .returnToScreen(let model):
            await runReturnToScreen(model)
        }

        isFlying = false
    }

    /// Libera a sessão de tracking (chamado quando a view desaparece).
    func stop() {
        handManager.stop()
    }

    // MARK: - Preparação do pássaro

    private func prepareBird(_ model: FlightModel, at spawn: SIMD3<Float>? = nil) async -> Entity? {
        currentForwardFix = BirdFlightConfig.forwardFix(for: model)
        return await birdLoader.prepareBird(
            model,
            at: spawn ?? headPose.portalWorldPosition(),
            in: worldRoot
        )
    }

    // MARK: - Orientação

    /// Orientação que faz o pássaro encarar `direction`: só yaw (giro em torno
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

    // MARK: - Movimento

    /// Voa suavemente do ponto atual até `target` seguindo uma curva Bézier
    /// com um leve arco e desvio lateral, atualizada a cada frame (~60 Hz).
    /// A orientação é interpolada (slerp) na direção do movimento, então o
    /// pássaro faz curvas suaves em vez de "teleportar" e girar de repente.
    ///
    /// - Parameters:
    ///   - target: destino final no espaço do mundo.
    ///   - duration: tempo total do trajeto.
    ///   - arcHeight: quanto a curva sobe no meio do caminho.
    ///   - lateralArc: desvio lateral máximo (sorteado) da curva.
    ///   - trackingTarget: se informado, o destino é reavaliado a cada frame
    ///     (ex.: segue a cabeça do usuário enquanto o pássaro se aproxima).
    ///     O desvio é aplicado com peso crescente, então o início da curva
    ///     não muda e a chegada acompanha o alvo atual.
    private func flySmooth(
        _ entity: Entity,
        to target: SIMD3<Float>,
        duration: TimeInterval,
        arcHeight: Float = 0.25,
        lateralArc: Float = 0.2,
        trackingTarget: (() -> SIMD3<Float>)? = nil
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
        let path = BezierPath(
            start: start,
            controlA: start + travel * 0.33 + up * arcHeight + right * side,
            controlB: start + travel * 0.66 + up * (arcHeight * 0.5) + right * (side * 0.5),
            end: target
        )

        let frameDT: TimeInterval = 1.0 / 60.0
        let steps = max(1, Int(duration / frameDT))
        var orientation = entity.orientation(relativeTo: nil)

        for i in 1...steps {
            let raw = Float(i) / Float(steps)
            let t = raw * raw * (3 - 2 * raw) // ease-in-out

            var position = path.point(at: t)
            // Balancinho vertical de voo, sumindo perto do destino.
            position.y += sinf(raw * .pi * 4) * 0.02 * (1 - raw)

            // Destino dinâmico: desloca a curva na direção do alvo atual.
            if let trackingTarget {
                position += (trackingTarget() - target) * t
            }

            let velocity = path.tangent(at: t)
            let desired = orientationFacing(velocity, fallback: orientation)
            orientation = simd_slerp(orientation, desired, 0.15)

            entity.setPosition(position, relativeTo: nil)
            entity.setOrientation(orientation, relativeTo: nil)
            try? await Task.sleep(for: .seconds(frameDT))
        }
        entity.setPosition(trackingTarget?() ?? target, relativeTo: nil)
    }

    /// Mantém o pássaro "pairando" com um flutuar suave em torno do ponto
    /// onde ele chegou, FIXO no mundo: depois da chegada ele não segue mais
    /// o usuário nem fica se reorientando, dá pra andar em volta e olhar o
    /// origami de qualquer ângulo. Ele encara o usuário uma única vez (na
    /// chegada) e mantém essa orientação.
    private func hoverInPlace(_ entity: Entity, seconds: TimeInterval) async {
        let frameDT: TimeInterval = 1.0 / 60.0
        let steps = max(1, Int(seconds / frameDT))
        var position = entity.position(relativeTo: nil)
        var orientation = entity.orientation(relativeTo: nil)

        let center = position
        let facingUser = orientationFacing(
            headPose.headPose().position - center,
            fallback: orientation
        )

        for i in 0..<steps {
            let time = Float(i) * Float(frameDT)
            var target = center
            // Flutuar de "asa parada no ar": sobe/desce e balança de leve.
            target.y += sinf(time * 2.2) * 0.03
            target.x += sinf(time * 1.3) * 0.015

            position = simd_mix(position, target, SIMD3<Float>(repeating: 0.06))
            orientation = simd_slerp(orientation, facingUser, 0.08)

            entity.setPosition(position, relativeTo: nil)
            entity.setOrientation(orientation, relativeTo: nil)
            try? await Task.sleep(for: .seconds(frameDT))
        }
    }

    // MARK: - Variação 1: voo simples

    private func runSimpleFlight(_ model: FlightModel) async {
        // Só a pose da cabeça — não requer permissão do usuário.
        _ = await handManager.start(hands: false)
        await headPose.waitForHeadPose()

        // O flap fica ligado (em loop) durante o voo simples inteiro.
        guard let bird = await prepareBird(model) else { return }

        // Portal -> frente do rosto (altura dos olhos), em curva suave,
        // trackeando o usuário durante a aproximação.
        await flySmooth(bird, to: headPose.hoverWorldPosition(), duration: 4.0, trackingTarget: headPose.hoverWorldPosition)

        // Paira por alguns segundos num ponto fixo do mundo (não segue mais).
        await hoverInPlace(bird, seconds: 3.0)

        // Voa para longe, subindo, e some.
        await flySmooth(bird, to: headPose.awayWorldPosition(), duration: 3.5, arcHeight: 0.6, lateralArc: 0.4)
        birdLoader.retireBird(bird)
        handManager.stop()
    }

    // MARK: - Variação 3: intro da splash (volta pra tela)

    /// O pássaro sai da "tela" da splash, vem pairar na frente do rosto e VOLTA
    /// para a tela. Quando `runFlight` retorna, a view sabe que ele chegou de
    /// volta e dispara a animação da splash.
    private func runReturnToScreen(_ model: FlightModel) async {
        // Só a pose da cabeça — não requer permissão do usuário.
        _ = await handManager.start(hands: false)
        await headPose.waitForHeadPose()

        // Nasce no plano da tela da splash.
        let screen = headPose.splashScreenWorldPosition()
        guard let bird = await prepareBird(model, at: screen) else { return }

        // Tela -> frente do rosto, em curva suave, trackeando o usuário.
        await flySmooth(
            bird,
            to: headPose.hoverWorldPosition(),
            duration: SplashFlightConfig.approachDuration,
            trackingTarget: headPose.hoverWorldPosition
        )

        // Paira brevemente na frente do rosto.
        await hoverInPlace(bird, seconds: SplashFlightConfig.hoverSeconds)

        // Volta para a tela (destino reavaliado a cada frame, caso a cabeça mexa).
        await flySmooth(
            bird,
            to: headPose.splashScreenWorldPosition(),
            duration: SplashFlightConfig.returnDuration,
            arcHeight: 0.15,
            lateralArc: 0.1,
            trackingTarget: headPose.splashScreenWorldPosition
        )

        // Chegou de volta na tela: some e libera o tracking. A view assume daqui.
        birdLoader.retireBird(bird)
        handManager.stop()
    }

    // MARK: - Variação 2: pouso na mão (hand tracking)

    private func runHandLanding(_ model: FlightModel) async {
        let available = await handManager.start(hands: true)
        // Sem hand tracking não aborta, faz o voo `returnToScreen`
        guard available else {
            print("[TsuruPortal] Sem hand tracking — fallback para voo simples (volta pra tela).")
            await runReturnToScreen(model)
            return
        }
        await headPose.waitForHeadPose()

        guard let bird = await prepareBird(model) else { return }

        // Portal -> frente dos olhos, trackeando o usuário na aproximação.
        await flySmooth(bird, to: headPose.hoverWorldPosition(), duration: 4.0, trackingTarget: headPose.hoverWorldPosition)

        // Paira na frente do rosto enquanto espera uma mão válida (timeout).
        var hand: SIMD3<Float>?
        for _ in 0..<10 {
            if let p = handManager.latestHandPosition {
                hand = p
                break
            }
            await hoverInPlace(bird, seconds: 0.6)
        }

        guard let hand else {
            print("Nenhuma mão detectada a tempo — abortando.")
            await flySmooth(bird, to: headPose.awayWorldPosition(), duration: 3.0, arcHeight: 0.6)
            birdLoader.retireBird(bird)
            handManager.stop()
            return
        }

        let scaledHeight = bird.visualBounds(relativeTo: nil).extents.y
        let landingLift = SIMD3<Float>(
            0,
            BirdFlightConfig.landingHeightOffset(for: model, scaledHeight: scaledHeight),
            0
        )

        // Desce suavemente até a palma (posição mais recente da mão).
        let landingTarget = (handManager.latestHandPosition ?? hand) + landingLift
        await flySmooth(bird, to: landingTarget, duration: 2.0, arcHeight: 0.15, lateralArc: 0.1)

        // FlatBird pousado não bate asas; retoma quando levantar voo.
        if model == .flatBird {
            birdLoader.pauseFlap()
        }

        // Pousado: segue a mão com interpolação, encarando o usuário.
        let frameDT: TimeInterval = 1.0 / 60.0
        let landingSeconds = BirdFlightConfig.handLandingSeconds
        var position = bird.position(relativeTo: nil)
        var orientation = bird.orientation(relativeTo: nil)
        for _ in 0..<Int(landingSeconds / frameDT) {
            if let palm = handManager.latestHandPosition {
                let target = palm + landingLift
                position = simd_mix(position, target, SIMD3<Float>(repeating: 0.25))
                let head = headPose.headPose()
                let desired = orientationFacing(head.position - position, fallback: orientation)
                orientation = simd_slerp(orientation, desired, 0.08)
                bird.setPosition(position, relativeTo: nil)
                bird.setOrientation(orientation, relativeTo: nil)
            }
            try? await Task.sleep(for: .seconds(frameDT))
        }

        // Levanta voo (voltando a bater asas) e some.
        if model == .flatBird {
            birdLoader.resumeFlap()
        }
        await flySmooth(bird, to: headPose.awayWorldPosition(), duration: 3.0, arcHeight: 0.6, lateralArc: 0.4)
        birdLoader.retireBird(bird)
        handManager.stop()
    }
}
#endif
