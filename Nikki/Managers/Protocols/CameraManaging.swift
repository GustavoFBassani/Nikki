import Foundation
import RealityKit

@MainActor
protocol CameraManaging {
    var camera: PerspectiveCamera? { get set }
    
    func rotate(dTheta: Float, dPhi: Float)
    func zoom(scale: Float)
    func repositioningCameraNewToTsuru(animated: Bool, tsuruToFocus: Entity?)
    func repositioningCameraToTree(animated: Bool, tree: Entity?)
    func updateCamera()
    func focusOnBandstand()
}
