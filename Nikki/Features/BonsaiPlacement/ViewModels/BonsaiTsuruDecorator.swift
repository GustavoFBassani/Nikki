//
//  BonsaiTsuruDecorator.swift
//  Nikki
//
//  Created by Anthony Antonelli Andrade on 22/06/26.
//

#if os(visionOS)
import RealityKit
import SwiftUI
import NikkiProject

@MainActor
final class BonsaiTsuruDecorator {

    private let flappingBirdName = "flappingBird___0PercentFolded"
    private var template: Entity?

    func loadTemplate() async {
        guard template == nil else { return }
        do {
            let scene = try await Entity(named: "Scene", in: nikkiProjectBundle)
            template = scene.findEntity(named: "tsuru")
        } catch {
            print("Falha ao carregar template do tsuru: \(error)")
        }
    }

    func decorate(tree: Entity) async {
        guard let template else { return }

        let pages: [Page]
        do {
            pages = try ScrapService.shared.fetchAllPages()
        } catch {
            print("Falha ao buscar páginas para os tsurus: \(error)")
            return
        }

        let positions = BonsaiTsuruLayout.positions
        let limited = Array(pages.prefix(positions.count))
        guard !limited.isEmpty else { return }

        let bounds = tree.visualBounds(relativeTo: tree)

        for (index, page) in limited.enumerated() {
            let tsuru = template.clone(recursive: true)
            fixTsuruPos(tsuru)
            await applyTexture(to: tsuru, texture: page.markupImage)
            let nativeExtents = tsuru.visualBounds(relativeTo: tsuru).extents
            tsuru.scale = SIMD3<Float>(repeating: BonsaiTsuruLayout.tsuruScale(
                canopyExtents: bounds.extents,
                tsuruNativeExtents: nativeExtents
            ))
            tsuru.position = positions[index]
            tsuru.orientation = simd_quatf(angle: BonsaiTsuruLayout.yaw(at: index), axis: [0, 1, 0])
            tree.addChild(tsuru)
            playAnimation(tsuru)
        }
    }

    private func fixTsuruPos(_ entity: Entity) {
        guard let bird = entity.findEntity(named: flappingBirdName) else { return }
        bird.scale = [1, 1, 1]
        bird.position = [0, 0, 0]
    }

    private func applyTexture(to tsuru: Entity, texture image: UIImage?) async {
        let source = image ?? UIImage(named: "teste")
        guard let cgImage = source?.cgImage,
              let bird = tsuru.findEntity(named: flappingBirdName) else { return }
        do {
            let texture = try await TextureResource(
                image: cgImage,
                options: .init(semantic: .color)
            )
            var material = PhysicallyBasedMaterial()
            material.textureCoordinateTransform = .init(
                scale: SIMD2<Float>(x: 1, y: -1),
                rotation: .pi / 180
            )
            material.baseColor = .init(tint: .white, texture: .init(texture))
            material.metallic = 0.0
            material.roughness = 0.7
            material.specular = 0.3
            if var modelComponent = bird.components[ModelComponent.self] {
                modelComponent.materials = [material]
                bird.components[ModelComponent.self] = modelComponent
            }
        } catch {
            print("Falha ao texturizar tsuru: \(error)")
        }
    }

    private func playAnimation(_ tsuru: Entity) {
        guard let animation = tsuru.availableAnimations.first else { return }
        tsuru.playAnimation(animation.repeat(), transitionDuration: 0.3, startsPaused: false)
    }
}
#endif
