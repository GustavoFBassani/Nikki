//
//  HandTrackingManager.swift
//  Nikki
//
//  Wrapper sobre ARKit/RealityKit hand tracking para a POC do tsuru.
//  Em device, fornece a posição mundial de uma das mãos para o tsuru pousar.
//  No Simulador (sem mãos), `start()` apenas loga e retorna `false` — nada anima.
//

#if os(visionOS)
import ARKit
import RealityKit
import simd

@MainActor
@Observable
final class HandTrackingManager {

    private let session = ARKitSession()
    private let handProvider = HandTrackingProvider()

    /// Última transform mundial conhecida da mão acompanhada (palma).
    /// `nil` enquanto nenhuma mão válida foi detectada.
    private(set) var latestHandTransform: simd_float4x4?

    private var updatesTask: Task<Void, Never>?

    /// Inicia a sessão de hand tracking.
    ///
    /// - Returns: `true` se o hand tracking está disponível e autorizado
    ///   (device real); `false` no Simulador ou se a autorização for negada —
    ///   nesse caso o chamador deve abortar a animação (decisão da POC).
    func start() async -> Bool {
        guard HandTrackingProvider.isSupported else {
            print("[HandTracking] Indisponível — rode no device. Nada será animado.")
            return false
        }

        let authorization = await session.requestAuthorization(for: [.handTracking])
        guard authorization[.handTracking] == .allowed else {
            print("[HandTracking] Autorização negada/indisponível. Nada será animado.")
            return false
        }

        do {
            try await session.run([handProvider])
        } catch {
            print("[HandTracking] Falha ao iniciar ARKitSession: \(error). Nada será animado.")
            return false
        }

        startConsumingUpdates()
        return true
    }

    /// Encerra o acompanhamento e libera a sessão.
    func stop() {
        updatesTask?.cancel()
        updatesTask = nil
        latestHandTransform = nil
    }

    /// Posição mundial atual da mão acompanhada, se houver.
    var latestHandPosition: SIMD3<Float>? {
        guard let m = latestHandTransform else { return nil }
        return SIMD3<Float>(m.columns.3.x, m.columns.3.y, m.columns.3.z)
    }

    private func startConsumingUpdates() {
        updatesTask?.cancel()
        updatesTask = Task { [weak self] in
            guard let self else { return }
            for await update in self.handProvider.anchorUpdates {
                let anchor = update.anchor
                // Acompanha a mão direita; cai para qualquer mão rastreada se preciso.
                guard anchor.isTracked else { continue }
                if anchor.chirality == .right || self.latestHandTransform == nil {
                    self.latestHandTransform = anchor.originFromAnchorTransform
                }
            }
        }
    }
}
#endif
