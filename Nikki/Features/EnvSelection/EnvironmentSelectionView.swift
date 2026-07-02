//
//  EnvironmentSelectionView.swift
//  Nikki
//
//  Created by Alex Fraga on 01/07/26.
//

import SwiftUI

struct EnvironmentSelectionView: View {
    var body: some View {
        HStack(spacing: 32) {
            EnvironmentCard(
                imageName: "bonsai3d",
                title: StringCatalog.experienceTitle3D,
                description: StringCatalog.experienceDescription3D,
                buttonLabel: StringCatalog.experienceStart3D,
                action: { /* TODO */ }
            )
            EnvironmentCard(
                imageName: "immersiveGarden",
                title: StringCatalog.experienceTitleImmersive,
                description: StringCatalog.experienceDescriptionImmersive,
                buttonLabel: StringCatalog.experienceBeginImmersive,
                action: { /* TODO */ }
            )
        }
        .padding(.horizontal, 60)
        .padding(.vertical, 42)
    }
}


#Preview {
    EnvironmentSelectionView()
        .nikkiGradientBackground()
}
