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

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    private let dataScrapsContainer = ScrapService.shared.container

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // configures TipKit on app launch
        do {
            try Tips.configure()
        } catch {
            print("Failed to configure TipKit: \(error)")
        }

        // check if user has seen onboarding
        let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")

        let rootView = NavigationStack {
            if hasSeenOnboarding {
                SceneView()
            } else {
                OnboardingFirstView()
            }
        }
        .modelContainer(dataScrapsContainer)

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
