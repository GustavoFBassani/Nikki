import Foundation
import RealityKit

@MainActor
class VisionCameraManager: CameraManaging {
    
    // The camera is not used in Vision Pro, but we need to conform to the protocol
    var camera: PerspectiveCamera?
    
    func rotate(dTheta: Float, dPhi: Float) {
        // No-op for Vision Pro.
        // The user simply turns their head, so swipe gestures are ignored.
    }
    
    func zoom(scale: Float) {
        // No-op for Vision Pro.
        // The user walks closer or moves their head closer to the object.
    }
    
    func repositioningCameraNewToTsuru(animated: Bool, tsuruToFocus: Entity?) {
        guard let tsuru = tsuruToFocus else { return }
        
        // Get the root of the entire scene to move the whole world together
        var rootEntity = tsuru
        while let parent = rootEntity.parent {
            rootEntity = parent
        }
        
        // INITIAL GUESS: Position the world so the tsuru is right in front of the user
        // Z: negative = in front of the user. X = left/right. Y = up/down
        let newWorldPosition = tsuru.position
        
        if animated {
            var newTransform = rootEntity.transform
            newTransform.translation = newWorldPosition
            rootEntity.move(to: newTransform, relativeTo: nil, duration: 1.0, timingFunction: .easeInOut)
        } else {
            rootEntity.position = newWorldPosition
        }
    }
    
    func repositioningCameraToTree(animated: Bool, tree: Entity?) {
        guard let tree = tree else { return }
        
        var rootEntity = tree
        while let parent = rootEntity.parent {
            rootEntity = parent
        }
        

        let newWorldPosition = SIMD3<Float>(2, 0.5, -6)

        if animated {
            var newTransform = rootEntity.transform
            newTransform.translation = newWorldPosition
            rootEntity.move(to: newTransform, relativeTo: nil, duration: 1.0, timingFunction: .easeInOut)
        } else {
            rootEntity.position = newWorldPosition
        }
    }
    
    func updateCamera() {

    }
    
    func focusOnBandstand() {

    }
}
