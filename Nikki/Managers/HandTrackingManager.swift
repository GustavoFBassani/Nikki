//
//  HandTrackingManager.swift
//  Nikki
//
//  Created by Alex Fraga on 30/06/26.
//

#if os(visionOS)
import ARKit
import QuartzCore
import RealityKit
import simd

@MainActor
@Observable
final class HandTrackingManager {

    private var session = ARKitSession()
    private var handProvider: HandTrackingProvider?
    private var worldProvider: WorldTrackingProvider?

    /// Última transform mundial conhecida da palma da mão acompanhada.
    /// `nil` enquanto nenhuma mão válida foi detectada.
    private(set) var latestHandTransform: simd_float4x4?

    private var updatesTask: Task<Void, Never>?

    /// Inicia a sessão ARKit.
    ///
    /// - Parameter hands: se `true`, além da pose do device (cabeça) também
    ///   pede autorização e inicia o hand tracking.
    /// - Returns: `false` se `hands == true` e o hand tracking está
    ///   indisponível (Simulador) ou foi negado, o chamador decide
    ///   o fallback do voo.
    ///   
    func start(hands: Bool) async -> Bool {
        stop()
        session = ARKitSession()

        let world = WorldTrackingProvider()
        var providers: [any DataProvider] = [world]
        var hand: HandTrackingProvider?

        if hands {
            guard HandTrackingProvider.isSupported else {
                print("[HandTracking] Indisponível — rode no device. Nada será animado.")
                return false
            }
            let authorization = await session.requestAuthorization(for: [.handTracking])
            guard authorization[.handTracking] == .allowed else {
                print("[HandTracking] Autorização negada/indisponível. Nada será animado.")
                return false
            }
            hand = HandTrackingProvider()
            providers.append(hand!)
        }

        do {
            try await session.run(providers)
        } catch {
            print("[HandTracking] Falha ao iniciar ARKitSession: \(error).")
            return false
        }

        worldProvider = world
        handProvider = hand
        if let hand { startConsumingUpdates(from: hand) }
        return true
    }

    /// Encerra o acompanhamento e libera a sessão.
    func stop() {
        updatesTask?.cancel()
        updatesTask = nil
        latestHandTransform = nil
        if handProvider != nil || worldProvider != nil {
            session.stop()
        }
        handProvider = nil
        worldProvider = nil
    }

    /// Transform mundial atual do device (cabeça/olhos), se disponível.
    /// Não requer autorização do usuário.
    var deviceTransform: simd_float4x4? {
        guard let worldProvider, worldProvider.state == .running else { return nil }
        let anchor = worldProvider.queryDeviceAnchor(atTimestamp: CACurrentMediaTime())
        guard let anchor, anchor.isTracked else { return nil }
        return anchor.originFromAnchorTransform
    }

    /// Posição mundial atual da palma da mão acompanhada, se houver.
    var latestHandPosition: SIMD3<Float>? {
        guard let m = latestHandTransform else { return nil }
        return SIMD3<Float>(m.columns.3.x, m.columns.3.y, m.columns.3.z)
    }

    private func startConsumingUpdates(from provider: HandTrackingProvider) {
        updatesTask?.cancel()
        updatesTask = Task { [weak self] in
            for await update in provider.anchorUpdates {
                guard let self else { return }
                let anchor = update.anchor
                // Acompanha a mão direita; cai para qualquer mão rastreada se preciso.
                guard anchor.isTracked else { continue }
                if anchor.chirality == .right || self.latestHandTransform == nil {
                    self.latestHandTransform = Self.palmTransform(of: anchor)
                }
            }
        }
    }

    /// Centro da palma (base do dedo médio) em coordenadas de mundo.
    /// O origin do `HandAnchor` fica no punho, o que faria o tsuru pousar
    /// no pulso em vez da mão.
    private static func palmTransform(of anchor: HandAnchor) -> simd_float4x4 {
        guard
            let joint = anchor.handSkeleton?.joint(.middleFingerKnuckle),
            joint.isTracked
        else { return anchor.originFromAnchorTransform }
        return anchor.originFromAnchorTransform * joint.anchorFromJointTransform
    }
}
#endif
