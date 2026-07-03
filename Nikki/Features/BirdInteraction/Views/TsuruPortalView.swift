//
//  TsuruPortalView.swift
//  Nikki
//
//  Created by Alex Fraga on 30/06/26.
//

#if os(visionOS)
import RealityKit
import SwiftUI

/// Space imersivo do voo do pássaro. Monta o `RealityView` (portal + raiz do
/// mundo) e delega toda a lógica de voo ao `BirdFlightViewModel`.
///
/// Usado em dois contextos:
/// - POC (botões da `VisionOSLauncherView`): dispara via `vm.pocFlightRequest`.
/// - Intro da splash (`VisionSplashView`): dispara via `vm.splashFlightRequest`
///   com um portal do tamanho da "tela" da splash; ao voltar, sinaliza
///   `vm.splashFlightDidReturn` para a splash assumir.
struct TsuruPortalView: View {
    @Environment(SceneViewModel.self) private var vm

    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openWindow) private var openWindow

    /// Quando `true`, é a intro da splash: portal do tamanho da tela, dispara
    /// automaticamente e sinaliza a volta em vez de abrir a janela "Launcher".
    var isSplashIntro: Bool = false

    @State private var flightVM = BirdFlightViewModel()

    /// Âncora na cabeça, usada apenas para o portal visual seguir o usuário.
    /// (A matemática do voo usa a pose real do device — ver `HeadPoseProvider`.)
    @State private var headAnchor = AnchorEntity(.head)

    var body: some View {
        RealityView { content in
            content.add(flightVM.worldRoot)

            let portal = isSplashIntro ? makeSplashScreen() : makePortal()
            headAnchor.addChild(portal)
            content.add(headAnchor)
        }
        .onAppear {
            // Na intro da splash o voo começa sozinho assim que o space aparece.
            if isSplashIntro {
                Task { await runSplashIntro() }
            }
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

    /// Roda a animação da POC e, ao terminar, fecha o portal e volta aos botões.
    private func runFlight(_ request: TsuruFlightKind) async {
        await flightVM.runFlight(request)
        await dismissImmersiveSpace()
        openWindow(id: "Launcher")
    }

    /// Intro da splash: roda o voo de "volta pra tela" e, ao terminar (pássaro
    /// de volta na tela), sinaliza para a `VisionSplashView` seguir com a splash.
    private func runSplashIntro() async {
        await flightVM.runFlight(SplashFlightConfig.flightKind)
        vm.splashFlightDidReturn = true
    }

    /// Plano semitransparente que representa a tela/portal de onde o pássaro sai
    /// (versão pequena da POC).
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

    /// Plano do tamanho da "tela" da splash (intro): o pássaro sai e volta pra cá.
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
