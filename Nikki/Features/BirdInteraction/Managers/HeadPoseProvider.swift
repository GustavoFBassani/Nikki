//
//  HeadPoseProvider.swift
//  Nikki
//
//  Created by Alex Fraga on 30/06/26.
//

#if os(visionOS)
import RealityKit
import simd

/// Pose da cabeça (via `WorldTrackingProvider`, exposto pelo
/// `HandTrackingManager`) e os pontos de mundo derivados dela usados pelo voo:
/// origem do portal, ponto de hover e ponto de saída.
///
/// IMPORTANTE: no visionOS o transform de `AnchorEntity(.head)` é opaco para
/// privacidade — `convert(position:to:)` nela devolve a posição como se a
/// cabeça estivesse na origem (no chão). Por isso toda a matemática do voo usa
/// a pose real do device via `WorldTrackingProvider`.
struct HeadPoseProvider {
    let handManager: HandTrackingManager

    /// Posição dos olhos e direção horizontal do olhar, no mundo.
    /// Fallback (Simulador sem pose): olhos a 1.3 m do chão olhando para -z.
    func headPose() -> (position: SIMD3<Float>, forward: SIMD3<Float>) {
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
    func waitForHeadPose() async {
        for _ in 0..<30 where handManager.deviceTransform == nil {
            try? await Task.sleep(for: .milliseconds(50))
        }
    }

    /// Posição no mundo do portal (origem do voo), um pouco acima da linha dos olhos.
    func portalWorldPosition() -> SIMD3<Float> {
        let head = headPose()
        return head.position + head.forward * BirdFlightConfig.portalDistance
            + SIMD3<Float>(0, BirdFlightConfig.portalHeightOffset, 0)
    }

    /// Ponto ~`hoverDistance` à frente do rosto, na altura dos olhos, no mundo.
    func hoverWorldPosition() -> SIMD3<Float> {
        let head = headPose()
        return head.position + head.forward * BirdFlightConfig.hoverDistance
            + SIMD3<Float>(0, BirdFlightConfig.hoverHeightOffset, 0)
    }

    /// Ponto distante à frente do usuário para o pássaro ir embora, subindo.
    func awayWorldPosition() -> SIMD3<Float> {
        let head = headPose()
        return head.position + head.forward * 8 + SIMD3<Float>(0, 1.5, 0)
    }
}
#endif
