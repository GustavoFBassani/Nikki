import Foundation
import RealityKit

@MainActor
class VisionCameraManager: CameraManaging {
    
    // The camera is not used in Vision Pro, but we need to conform to the protocol
    var camera: PerspectiveCamera?
    
    // Stores the original position of the Tsuru on the tree to return it later
    private var originalTsuruTransforms: [Entity: Transform] = [:]
    private var currentlyFocusedTsuru: Entity?
    
    func rotate(dTheta: Float, dPhi: Float) {
        // No-op for Vision Pro.
    }
    
    func zoom(scale: Float) {
        // No-op for Vision Pro.
    }
    
    func repositioningCameraNewToTsuru(animated: Bool, tsuruToFocus: Entity?) {
        // O Tsuru que você passa aqui geralmente é a malha "flappingBird" que tem a animação de bater asas.
        // Em RealityKit, se você tentar dar um `move(to:)` numa entidade que já está rodando 
        // outra animação no Transform (bater as asas), a engine ignora o seu movimento e ele trava no lugar!
        // A solução é mover o "Container" dele (o pai)! Assim ele viaja pela sala enquanto bate as asas lá dentro.
        guard let flapBirdMesh = tsuruToFocus, 
              let tsuruContainer = flapBirdMesh.parent, 
              let sceneRoot = tsuruContainer.parent else { return }
        
        // If there was already a tsuru flying in front of the user, return it to the tree
        flyBackCurrentlyFocusedTsuru(animated: animated)
        
        // Save the original position of this tsuru on the tree (if we haven't already)
        if originalTsuruTransforms[tsuruContainer] == nil {
            originalTsuruTransforms[tsuruContainer] = tsuruContainer.transform
        }
        currentlyFocusedTsuru = tsuruContainer
        
        // 1. Ideal world point where the Tsuru will stop (in front of the face)
        let idealWorldFocusPoint = SIMD3<Float>(0, 1.2, -0.6)
        
        // 2. Convert this world coordinate to the local coordinate of the tree branch
        let localTargetPosition = sceneRoot.convert(position: idealWorldFocusPoint, from: nil)
        
        var newTransform = tsuruContainer.transform
        newTransform.translation = localTargetPosition
        
        if animated {
            tsuruContainer.move(to: newTransform, relativeTo: sceneRoot, duration: 1.0, timingFunction: .easeInOut)
        } else {
            tsuruContainer.transform = newTransform
        }
    }
    
    func repositioningCameraToTree(animated: Bool, tree: Entity?) {
        // First, if there's a Tsuru flying in front of the user, send it back to its branch
        flyBackCurrentlyFocusedTsuru(animated: animated)
        
        guard let tree = tree else { return }
        
        var rootEntity = tree
        while let parent = rootEntity.parent {
            rootEntity = parent
        }
        
        // THIS is your perfectly adjusted position for the tree!
        let newWorldPosition = SIMD3<Float>(1.5, 1.3, -7)
        
        if animated {
            var newTransform = rootEntity.transform
            newTransform.translation = newWorldPosition
            rootEntity.move(to: newTransform, relativeTo: nil, duration: 1.0, timingFunction: .easeInOut)
        } else {
            rootEntity.position = newWorldPosition
        }
    }
    
    private func flyBackCurrentlyFocusedTsuru(animated: Bool) {
        guard let tsuruContainer = currentlyFocusedTsuru, 
              let parent = tsuruContainer.parent,
              let originalTransform = originalTsuruTransforms[tsuruContainer] else {
            return } // se nao tem nenhum focado, ele vai sair aqui pq nao vai ter originalTransform
        if animated {
            tsuruContainer.move(to: originalTransform, relativeTo: parent, duration: 1.0, timingFunction: .easeInOut)
        } else {
            tsuruContainer.transform = originalTransform
        }
        currentlyFocusedTsuru = nil
        
        print("tsuru: \(tsuruContainer.name)")
        print("parent: \(parent.name)")
    }
    
    func updateCamera() {
        // No-op. The physical camera (head tracking) updates itself.
    }
    
    func focusOnBandstand() {
        // TODO: Implement the same logic to bring the bandstand closer.
    }
}
