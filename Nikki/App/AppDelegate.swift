//
//  AppDelegate.swift
//  Nikki
//
//  Created by Gustavo Ferreira bassani on 17/11/25.
//

import UIKit
import SwiftUI
import SwiftData
import TipKit

class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        do {
            try Tips.configure()
        } catch {
            print("Failed to configure TipKit: \(error)")
        }

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) { }
    func applicationDidEnterBackground(_ application: UIApplication) { }
    func applicationWillEnterForeground(_ application: UIApplication) { }
    func applicationDidBecomeActive(_ application: UIApplication) { }
}

@main
struct NikkiApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    private let dataContainer = PersistenceController.shared.container

    @State private var sceneVM = SceneViewModel()

    #if os(visionOS)
    @State private var bonsaiAppModel = BonsaiAppModel()
    #endif

    // O 'body' do App sempre retorna uma 'Scene' (Cena).
    // É aqui que dizemos ao iOS/visionOS quais tipos de janelas ou ambientes nosso app tem.
    var body: some Scene {
        // MARK: - Main Window

        // Janela principal e padrão do app (sem `id`). No iOS é a tela inteira;
        // no visionOS é a janela 2D de vidro que abre ao iniciar o app.
        // Precisa do `id: "Launcher"` porque a POC do tsuru reabre esta janela
        // via `openWindow(id: "Launcher")` ao terminar o voo.
        WindowGroup(id: "Launcher") {
            RootView()
                .environment(sceneVM)
            #if os(visionOS)
                .environment(bonsaiAppModel)
            #endif
        }
        .modelContainer(dataContainer)
        #if os(visionOS)
        // .plain remove o vidro padrão do sistema, para que a própria view controle o
        // vidro colorido via .background(Color...opacity) + .glassBackgroundEffect().
        // .contentSize faz a janela física acompanhar o tamanho do conteúdo: quando a
        // VisionSplashView anima a largura do frame, a janela do visionOS abre lateralmente.
        .windowStyle(.plain)
        .defaultSize(width: 1280, height: 720)
        .windowResizability(.contentSize)
        #endif

        #if os(visionOS)

        // MARK: - Canvas Window

        WindowGroup(id: "CanvasWindow", for: String.self) { $style in
            if let style {
                CanvasWindowWrapper(style: style)
                    .environment(sceneVM)
                    .onAppear {
                        sceneVM.setCanvasPresented(true)
                    }
                    .onDisappear {
                        sceneVM.setCanvasPresented(false)
                    }
            } else {
                EmptyView()
            }
        }
        .modelContainer(dataContainer)
        .defaultSize(width: 1280, height: 720)
        .windowResizability(.automatic)

        // MARK: - Immersive Space

        ImmersiveSpace(id: "TreeView") {
            SceneView()
                .environment(sceneVM)
                .onAppear {
                    sceneVM.markImmersiveOpened()
                }
                .onDisappear {
                    sceneVM.markImmersiveClosed()
                }
        }
        .modelContainer(dataContainer)
        .immersionStyle(selection: .constant(.mixed), in: .mixed, .full)

        // Portal do tsuru. Space de debug das duas animações do pássaro
        // (voo simples e pouso na mão). A view observa `sceneVM.pocFlightRequest`.
        ImmersiveSpace(id: "TsuruPortal") {
            TsuruPortalView()
                .environment(sceneVM)
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed, .full)

        // Intro da splash: voo do pássaro. O pássaro sai da "tela", paira e volta,
        // e a `VisionSplashView` assume a partir daí (portal do tamanho da tela,
        // disparo automático via isSplashIntro).
        ImmersiveSpace(id: "SplashIntro") {
            TsuruPortalView(isSplashIntro: true)
                .environment(sceneVM)
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed, .full)

        // Espaço imersivo de posicionamento do bonsai em superfície real.
        ImmersiveSpace(id: bonsaiAppModel.immersiveSpaceID) {
            BonsaiImmersiveView()
                .environment(bonsaiAppModel)
                .onAppear { bonsaiAppModel.immersiveSpaceState = .open }
                .onDisappear { bonsaiAppModel.immersiveSpaceState = .closed }
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
        #endif
    }
}
