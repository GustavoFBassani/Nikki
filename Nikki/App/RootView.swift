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
            if hasSeenOnboarding {
                #if os(visionOS)
                VisionOSLauncherView()
                #else
                SceneView()
                #endif
            } else {
                NavigationStack {
                    OnboardingFirstView()
                }
            }
        }
        .modelContainer(dataContainer)
    }
}

#if os(visionOS)
struct VisionOSLauncherView: View {
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        VStack {
            ProgressView("Carregando ambiente...")
        }
        .onAppear {
            Task {
                await openImmersiveSpace(id: "TreeView")
                dismissWindow()
            }
        }
    }
}
#endif
