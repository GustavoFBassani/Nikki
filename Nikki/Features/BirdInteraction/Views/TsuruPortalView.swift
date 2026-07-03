//
//  TsuruPortalView.swift
//  Nikki
//
//  Created by Alex Fraga on 30/06/26.
//

#if os(visionOS)
import RealityKit
import SwiftUI

/// Space imersivo da POC do voo do pássaro. Monta o `RealityView` (portal +
/// raiz do mundo) e delega toda a lógica de voo ao `BirdFlightViewModel`.
struct TsuruPortalView: View {
    @Environment(SceneViewModel.self) private var vm

    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openWindow) private var openWindow

    @State private var flightVM = BirdFlightViewModel()

    /// Âncora na cabeça, usada apenas para o portal visual seguir o usuário.
    /// (A matemática do voo usa a pose real do device — ver `HeadPoseProvider`.)
    @State private var headAnchor = AnchorEntity(.head)

    var body: some View {
        RealityView { content in
            content.add(flightVM.worldRoot)

            // Portal/plano simples, semitransparente, à frente do usuário.
            let portal = makePortal()
            headAnchor.addChild(portal)
            content.add(headAnchor)
        }
        .onChange(of: vm.pocFlightRequest) { _, request in
            guard let request else { return }
            // Consome o request para não re-disparar em recomposições.
            vm.pocFlightRequest = nil
            Task { await runFlight(request) }
        }
        .onDisappear {
            flightVM.stop()
        }
    }

    /// Roda a animação e, ao terminar, fecha o portal e volta aos botões.
    private func runFlight(_ request: TsuruFlightKind) async {
        await flightVM.runFlight(request)
        await dismissImmersiveSpace()
        openWindow(id: "Launcher")
    }

    /// Plano semitransparente que representa a tela/portal de onde o pássaro sai.
    private func makePortal() -> ModelEntity {
        var material = SimpleMaterial()
        material.color = .init(tint: .white.withAlphaComponent(0.25))
        let portal = ModelEntity(
            mesh: .generatePlane(width: 1.0, height: 1.2, cornerRadius: 0.05),
            materials: [material]
        )
        // À frente do rosto (-z), um pouco acima da linha dos olhos.
        portal.position = [0, BirdFlightConfig.portalHeightOffset, -BirdFlightConfig.portalDistance]
        return portal
    }
}
#endif
