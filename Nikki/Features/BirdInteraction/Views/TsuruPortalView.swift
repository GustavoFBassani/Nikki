//
//  TsuruPortalView.swift
//  Nikki
//
//  Created by Alex Fraga on 30/06/26.
//

#if os(visionOS)
import RealityKit
import SwiftUI

/// Space imersivo do voo de intro da splash. Monta o portal e delega toda a lógica de voo ao
/// `BirdFlightViewModel`.
///

struct TsuruPortalView: View {
    @Environment(SceneViewModel.self) private var vm

    @State private var flightVM = BirdFlightViewModel()

    /// Âncora na cabeça, usada apenas para o portal visual seguir o usuário.
    /// (A matemática do voo usa a pose real do device — ver `HeadPoseProvider`.)
    @State private var headAnchor = AnchorEntity(.head)

    var body: some View {
        RealityView { content in
            content.add(flightVM.worldRoot)

            headAnchor.addChild(makeSplashScreen())
            content.add(headAnchor)
        }
        .onAppear {
            Task { await runSplashIntro() }
        }
        .onDisappear {
            flightVM.stop()
        }
    }

    /// Roda o voo de intro e, ao terminar, sinaliza para a `VisionSplashView`
    /// seguir com a animação da splash.
    private func runSplashIntro() async {
        await flightVM.runFlight(SplashFlightConfig.flightKind)
        vm.splashFlightDidReturn = true
    }

    /// Plano do tamanho da tela da splash: o pássaro sai daqui e volta pra cá.
    private func makeSplashScreen() -> ModelEntity {
        var material = SimpleMaterial()
        material.color = .init(tint: .white.withAlphaComponent(SplashFlightConfig.screenOpacity))
        let screen = ModelEntity(
            mesh: .generatePlane(
                width: SplashFlightConfig.screenWidth,
                height: SplashFlightConfig.screenHeight,
                cornerRadius: 0.05
            ),
            materials: [material]
        )
        screen.position = [0, SplashFlightConfig.screenHeightOffset, -SplashFlightConfig.screenDistance]
        return screen
    }
}
#endif
