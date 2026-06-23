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

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?
    ) -> Bool {

        do {
            try Tips.configure()
        } catch {
            print("Failed to configure TipKit: \(error)")
        }

        let rootView = RootView()

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return false
        }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: rootView)
        self.window = window
        window.makeKeyAndVisible()

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
        WindowGroup {
            RootView()
                .environment(sceneVM)
        }
        .modelContainer(dataContainer)
        
        #if os(visionOS)
        WindowGroup(id: "CanvasWindow", for: String.self) { $style in
            if let style = style {
                CanvasWindowWrapper(style: style)
                    .environment(sceneVM)
            }
        }
        .modelContainer(dataContainer)
        
        ImmersiveSpace(id: "TreeView") {
            SceneView()
                .environment(sceneVM)
        }
        .modelContainer(dataContainer)
        .immersionStyle(selection: .constant(.full), in: .mixed, .full)
        #endif
    }
}
