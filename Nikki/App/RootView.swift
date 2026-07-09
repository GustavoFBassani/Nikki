//
//  RootView.swift
//  Nikki
//
//  Created by Rafael Toneto on 11/12/25.
//


import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    private let dataContainer = PersistenceController.shared.container
    var body: some View {
        Group {
            #if os(visionOS)
            VisionSplashView()
            #else
            if hasSeenOnboarding {
                SceneView()
            } else {
                NavigationStack {
                    #if os(visionOS)
                    VisionSplashView()
                    #else
                    OnboardingFirstView()
                    #endif
                }
            }
            #endif
        }
        .modelContainer(dataContainer)
    }
}
