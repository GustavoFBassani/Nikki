//
//  BonsaiPlacementManager.swift
//  Nikki
//
//  Created by Anthony Antonelli Andrade on 22/06/26.
//

#if os(visionOS)
import ARKit
import RealityKit
import SwiftUI
import NikkiProject

@MainActor
@Observable
class BonsaiPlacementManager {

    // MARK: - Loading State

    enum LoadState: Equatable {
        case loading
        case ready
        case failed(String)
    }

    private(set) var loadState: LoadState = .loading

    // MARK: - ARKit Session

    private let session = ARKitSession()
    private var planeDetection: PlaneDetectionProvider?

    // Escuta os planos numa task própria; o stream é infinito e não pode ser
    // aguardado inline, senão trava a make closure da RealityView.
    private var monitorTask: Task<Void, Never>?

    private(set) var detectedPlanes: [UUID: PlaneAnchor] = [:]
    private(set) var isDetecting = false
    private(set) var isSimulatorMode = false

    var hasDetectedSurface: Bool { isSimulatorMode || !detectedPlanes.isEmpty }

    // MARK: - Model

    private(set) var placementTemplate: Entity?
    var placedTree: Entity?

    private let tsuruDecorator = BonsaiTsuruDecorator()

    // MARK: - Plane Visualization

    var planeEntities: [UUID: ModelEntity] = [:]

    // MARK: - Loading

    func loadModel(for target: BonsaiAppModel.PlacementTarget) async {
        guard placementTemplate == nil else {
            loadState = .ready
            return
        }

        loadState = .loading
        do {
            let entity: Entity
            switch target {
            case .bonsai:
                entity = try await Entity(named: "Cherry_Tree-2", in: nikkiProjectBundle)
                entity.scale = SIMD3<Float>(repeating: 0.003)
                await tsuruDecorator.loadTemplate()

            case .scene:
                entity = try await Entity(named: "Scene", in: nikkiProjectBundle)
                entity.scale = SIMD3<Float>(repeating: 0.02)
            }

            configureForInteraction(entity)

            placementTemplate = entity
            loadState = .ready
        } catch {
            loadState = .failed(StringCatalog.bonsaiModelLoadError)
            print("Falha ao carregar modelo de placement para \(target): \(error)")
        }
    }

    // MARK: - Plane Detection

    func startPlaneDetection() async {
        guard !isDetecting else { return }

        // PlaneDetectionProvider não existe no simulador.
        guard PlaneDetectionProvider.isSupported else {
            isSimulatorMode = true
            isDetecting = true
            return
        }

        do {
            let provider = PlaneDetectionProvider(alignments: [.horizontal])
            planeDetection = provider
            try await session.run([provider])
            isDetecting = true

            monitorTask = Task { [weak self] in
                await self?.monitorPlaneUpdates()
            }
        } catch {
            loadState = .failed(StringCatalog.bonsaiTrackingError)
            print("Falha ao iniciar sessão ARKit: \(error)")
        }
    }

    func stopPlaneDetection() {
        monitorTask?.cancel()
        monitorTask = nil
        session.stop()
        planeDetection = nil
        isDetecting = false
        isSimulatorMode = false
        detectedPlanes.removeAll()
        planeEntities.removeAll()
        placedTree = nil
    }

    // MARK: - Plane Monitoring

    private func monitorPlaneUpdates() async {
        guard let planeDetection else { return }

        for await update in planeDetection.anchorUpdates {
            let anchor = update.anchor

            switch update.event {
            case .added, .updated:
                detectedPlanes[anchor.id] = anchor

            case .removed:
                detectedPlanes.removeValue(forKey: anchor.id)
                planeEntities.removeValue(forKey: anchor.id)
            }
        }
    }

    // MARK: - Simulator Fallback

    // Plano simulado para testar no simulador (1.5m à frente, altura de mesa).
    func createSimulatorPlane() -> Entity {
        let container = Entity()
        container.position = SIMD3<Float>(0, 1, -1.5)
        container.name = "simulator-plane"

        container.addChild(makeDashedBorder(width: 1.0, depth: 1.0))

        let shape = ShapeResource.generateBox(size: SIMD3(1.0, 0.001, 1.0))
        container.components.set(CollisionComponent(shapes: [shape]))
        container.components.set(InputTargetComponent(allowedInputTypes: .indirect))

        return container
    }

    // MARK: - Plane Visualization

    func planeVisualizationEntity(for anchor: PlaneAnchor) -> Entity {
        let extent = anchor.geometry.extent
        let container = Entity()
        container.transform = Transform(matrix: anchor.originFromAnchorTransform)

        container.addChild(makeDashedBorder(width: extent.width, depth: extent.height))

        let shape = ShapeResource.generateBox(size: SIMD3(extent.width, 0.001, extent.height))
        container.components.set(CollisionComponent(shapes: [shape]))
        container.components.set(InputTargetComponent(allowedInputTypes: .indirect))

        return container
    }

    // MARK: - Dashed Border

    private func makeDashedBorder(width: Float, depth: Float) -> Entity {
        let border = Entity()

        let dashLength: Float = 0.04
        let dashGap: Float = 0.025
        let dashHeight: Float = 0.001
        let dashThickness: Float = 0.004

        var material = UnlitMaterial()
        material.color = .init(tint: .white)

        let halfW = width / 2
        let halfD = depth / 2

        let hMesh = MeshResource.generateBox(size: SIMD3(dashLength, dashHeight, dashThickness))
        let vMesh = MeshResource.generateBox(size: SIMD3(dashThickness, dashHeight, dashLength))

        // Bordas horizontais (topo e base)
        let hCycle = dashLength + dashGap
        let hCount = max(1, Int(width / hCycle))
        let hTotal = Float(hCount) * hCycle - dashGap
        let hStart = -hTotal / 2

        for i in 0..<hCount {
            let x = hStart + Float(i) * hCycle + dashLength / 2
            for z in [-halfD, halfD] {
                let dash = ModelEntity(mesh: hMesh, materials: [material])
                dash.position = SIMD3(x, 0, z)
                border.addChild(dash)
            }
        }

        // Bordas verticais (esquerda e direita)
        let vCycle = dashLength + dashGap
        let vCount = max(1, Int(depth / vCycle))
        let vTotal = Float(vCount) * vCycle - dashGap
        let vStart = -vTotal / 2

        for i in 0..<vCount {
            let z = vStart + Float(i) * vCycle + dashLength / 2
            for x in [-halfW, halfW] {
                let dash = ModelEntity(mesh: vMesh, materials: [material])
                dash.position = SIMD3(x, 0, z)
                border.addChild(dash)
            }
        }

        return border
    }

    // MARK: - Placement

    func placeTree(position: SIMD3<Float>) -> Entity? {
        guard let template = placementTemplate else { return nil }

        let clone = template.clone(recursive: true)
        clone.position = position

        configureForInteraction(clone)

        placedTree = clone
        return clone
    }

    func decorateWithTsurus(on tree: Entity) async {
        await tsuruDecorator.decorate(tree: tree)
    }

    // MARK: - Helpers

    private func configureForInteraction(_ entity: Entity) {
        entity.generateCollisionShapes(recursive: true)
        entity.components.set(InputTargetComponent(allowedInputTypes: .indirect))
    }
}
#endif
