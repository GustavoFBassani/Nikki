//
//  BirdModelLoader.swift
//  Nikki
//
//  Created by Alex Fraga on 30/06/26.
//

#if os(visionOS)
import Foundation
import NikkiProject
import RealityKit
import simd

/// Carrega, prepara e controla o flap (bater de asas) das entidades dos
/// pássaros. Mantém um cache por modelo para reusar a mesma entidade entre
/// voos e o controller da animação atual (para pausar/retomar no pouso).
@MainActor
final class BirdModelLoader {

    /// Entidades já carregadas, uma por modelo, reusadas entre voos.
    private var loadedBirds: [FlightModel: Entity] = [:]

    /// Controller da animação de bater asas do voo atual, usado para pausar
    /// o flap quando o pássaro pousa na mão e retomar quando levanta voo.
    private var flapController: AnimationPlaybackController?

    /// Carrega o modelo direto do asset reaproveitando a mesma entidade entre voos.
    /// O load acontece dentro do Task do voo (e não em `.task`), para não ser
    /// cancelado pela transição de janela/space.
    private func loadBirdIfNeeded(_ model: FlightModel) async -> Entity? {
        if let cached = loadedBirds[model] { return cached }
        do {
            let entity: Entity
            switch model {
            case .tsuru:
                entity = try await Entity(named: "tsuru", in: nikkiProjectBundle)
            case .flatBird:
                // Model fica em Features/BirdInteraction/3DModels, no bundle do app.
                entity = try await Entity(named: "BlueFlatBird")
            }
            entity.isEnabled = false
            loadedBirds[model] = entity
            return entity
        } catch {
            print("Falha ao carregar o asset de \(model): \(error)")
            return nil
        }
    }

    /// Prepara a entidade do modelo na origem do portal e inicia o flap.
    /// Retorna `nil` se o asset não pôde ser carregado.
    func prepareBird(_ model: FlightModel, at position: SIMD3<Float>, in worldRoot: Entity) async -> Entity? {
        guard let bird = await loadBirdIfNeeded(model) else { return nil }
        bird.removeFromParent()
        let scale = BirdFlightConfig.scale(for: model)
        bird.scale = [scale, scale, scale]
        bird.position = position
        bird.isEnabled = true
        worldRoot.addChild(bird)
        playFlap(on: bird)
        return bird
    }

    /// Toca a animação de bater asas embutida no asset, em loop, guardando o
    /// controller para poder pausar/retomar durante o pouso na mão.
    func playFlap(on entity: Entity) {
        if let anim = entity.availableAnimations.first {
            flapController = entity.playAnimation(
                anim.repeat(),
                transitionDuration: 0.3,
                startsPaused: false
            )
        }
    }

    /// Pausa o flap (pássaro pousado na mão).
    func pauseFlap() {
        flapController?.pause()
    }

    /// Retoma o flap (pássaro levantando voo).
    func resumeFlap() {
        flapController?.resume()
    }

    /// Finaliza o voo: esconde o pássaro e o remove da cena.
    func retireBird(_ entity: Entity) {
        entity.stopAllAnimations()
        flapController = nil
        entity.isEnabled = false
        entity.removeFromParent()
    }
}
#endif
