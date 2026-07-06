//
//  BonsaiImmersiveView.swift
//  Nikki
//
//  Created by Anthony Antonelli Andrade on 22/06/26.
//

#if os(visionOS)
import SwiftUI
import RealityKit
import ARKit

struct BonsaiImmersiveView: View {
    
    @Environment(BonsaiAppModel.self) private var appModel
    @State private var placementManager = BonsaiPlacementManager()

    @State private var rootEntity = Entity()
    @State private var planeVisualizationRoot = Entity()
    @State private var dragOffset: SIMD3<Float>? = nil
    
    var body: some View {
        RealityView { content, attachments in
            content.add(rootEntity)
            rootEntity.addChild(planeVisualizationRoot)

            if let statusPanel = attachments.entity(for: "status") {
                statusPanel.position = SIMD3<Float>(0, 1.3, -1.2)
                rootEntity.addChild(statusPanel)
            }

            await placementManager.loadModel(for: appModel.placementTarget)
            await placementManager.startPlaneDetection()

            if placementManager.isSimulatorMode {
                let simulatorPlane = placementManager.createSimulatorPlane()
                planeVisualizationRoot.addChild(simulatorPlane)
            }
        } update: { content, attachments in
            if !placementManager.isSimulatorMode {
                updatePlaneVisualizations()
            }
        } attachments: {
            Attachment(id: "status") {
                BonsaiPlacementStatusView(
                    loadState: placementManager.loadState,
                    isTreePlaced: appModel.isTreePlaced,
                    hasSurface: placementManager.hasDetectedSurface,
                    target: appModel.placementTarget
                )
            }
        }
        .gesture(
            SpatialTapGesture()
                .targetedToAnyEntity()
                .onEnded { value in
                    handleTapToPlace(value)
                }
        )
        .gesture(
            DragGesture()
                .targetedToAnyEntity()
                .onChanged { value in
                    handleDrag(value)
                }
                .onEnded { _ in
                    dragOffset = nil
                }
        )
        .onDisappear {
            placementManager.stopPlaneDetection()
            appModel.isTreePlaced = false
        }
    }
    
    private func handleTapToPlace(_ value: EntityTargetValue<SpatialTapGesture.Value>) {
        guard !appModel.isTreePlaced else { return }

        // Só posiciona quando o toque acerta um plano detectado;
        // ignora toques no painel de status e em outras entidades.
        guard isEntity(value.entity, descendantOf: planeVisualizationRoot) else { return }

        let tapPosition = value.convert(value.location3D, from: .local, to: .scene)

        if let treeEntity = placementManager.placeTree(position: tapPosition) {
            rootEntity.addChild(treeEntity)
            appModel.isTreePlaced = true
            animateTreeAppearance(treeEntity)
            planeVisualizationRoot.children.removeAll()
            if appModel.placementTarget == .bonsai {
                Task { await placementManager.decorateWithTsurus(on: treeEntity) }
            }
        }
    }

    private func handleDrag(_ value: EntityTargetValue<DragGesture.Value>) {
        guard appModel.isTreePlaced,
              let placedTree = placementManager.placedTree,
              isEntity(value.entity, descendantOf: placedTree) else { return }

        let handPosition = value.convert(value.gestureValue.location3D, from: .local, to: .scene)

        if dragOffset == nil {
            dragOffset = placedTree.position - SIMD3<Float>(handPosition.x, placedTree.position.y, handPosition.z)
        }

        let offset = dragOffset ?? .zero
        placedTree.position = SIMD3<Float>(
            handPosition.x + offset.x,
            placedTree.position.y,
            handPosition.z + offset.z
        )
    }

    private func isEntity(_ entity: Entity, descendantOf root: Entity) -> Bool {
        var current: Entity? = entity
        while let node = current {
            if node == root { return true }
            current = node.parent
        }
        return false
    }
    
    private func updatePlaneVisualizations() {
        guard !appModel.isTreePlaced else {
            planeVisualizationRoot.children.removeAll()
            return
        }
        
        var activePlaneIDs = Set<UUID>()
        
        for (id, anchor) in placementManager.detectedPlanes {
            activePlaneIDs.insert(id)

            if let existing = planeVisualizationRoot.children.first(where: { $0.name == id.uuidString }) {
                existing.transform = Transform(matrix: anchor.originFromAnchorTransform)
                continue
            }

            let visualEntity = placementManager.planeVisualizationEntity(for: anchor)
            visualEntity.name = id.uuidString
            planeVisualizationRoot.addChild(visualEntity)
        }
        
        for child in planeVisualizationRoot.children {
            if let childID = UUID(uuidString: child.name),
               !activePlaneIDs.contains(childID) {
                child.removeFromParent()
            }
        }
    }
    
    private func animateTreeAppearance(_ entity: Entity) {
        let finalScale = entity.scale
        entity.scale = SIMD3<Float>(repeating: 0.0)
        entity.move(
            to: Transform(
                scale: finalScale,
                rotation: entity.orientation,
                translation: entity.position
            ),
            relativeTo: entity.parent,
            duration: 0.6,
            timingFunction: .easeInOut
        )
    }
}

#Preview {
    BonsaiImmersiveView()
        .environment(BonsaiAppModel())
}
#endif
