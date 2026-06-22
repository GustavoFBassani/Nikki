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
    
    var body: some Scene {
        #if os(visionOS)
        // O ImmersiveSpace PRECISA ser a raiz do app (Scene) e não uma View comum.
        ImmersiveSpace(id: "TreeView") {
            RootView()
        }
        .modelContainer(dataContainer)
        .immersionStyle(selection: .constant(.full), in: .mixed, .full)
        #else
        WindowGroup {
            RootView()
        }
        .modelContainer(dataContainer)
        #endif
    }
}
