//
//  EnvironmentSelectionView.swift
//  Nikki
//
//  Created by Alex Fraga on 01/07/26.
//

import SwiftUI

struct EnvironmentSelectionView: View {
    #if os(visionOS)
    @Environment(BonsaiAppModel.self) private var appModel
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissWindow) private var dismissWindow
    #endif

    var body: some View {
        HStack(spacing: 32) {
            EnvironmentCard(
                imageName: "bonsai3d",
                title: StringCatalog.experienceTitle3D,
                description: StringCatalog.experienceDescription3D,
                buttonLabel: StringCatalog.experienceStart3D,
                action: {
                    #if os(visionOS)
                    withAnimation { appModel.windowScreen = .bonsaiControl }
                    #endif
                }
            )
            EnvironmentCard(
                imageName: "immersiveGarden",
                title: StringCatalog.experienceTitleImmersive,
                description: StringCatalog.experienceDescriptionImmersive,
                buttonLabel: StringCatalog.experienceBeginImmersive,
                action: {
                    #if os(visionOS)
                    Task { @MainActor in
                        if case .opened = await openImmersiveSpace(id: "TreeView") {
                            dismissWindow()
                        }
                    }
                    #endif
                }
            )
        }
        .padding(.horizontal, 130)
        .padding(.vertical, 42)
    }
}


#Preview {
    EnvironmentSelectionView()
        .nikkiGradientBackground()
    #if os(visionOS)
        .environment(BonsaiAppModel())
    #endif
}
