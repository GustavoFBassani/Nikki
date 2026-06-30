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

    var body: some Scene {

        // MARK: - Main Window

        WindowGroup {
            RootView()
                .environment(sceneVM)
        }
        .modelContainer(dataContainer)

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
        .windowResizability(.contentSize)

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

        #endif
    }
}
