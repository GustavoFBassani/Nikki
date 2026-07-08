//
//  BonsaiAppModel.swift
//  Nikki
//
//  Created by Anthony Antonelli Andrade on 22/06/26.
//

#if os(visionOS)
import SwiftUI

@MainActor
@Observable
class BonsaiAppModel {
    let immersiveSpaceID = "ImmersiveSpace"

    enum ImmersiveSpaceState {
        case closed
        case inTransition
        case open
    }

    enum PlacementTarget: Equatable {
        case bonsai
        case scene
    }

    enum WindowScreen {
        case environmentSelection
        case bonsaiControl
    }

    var immersiveSpaceState = ImmersiveSpaceState.closed
    var placementTarget: PlacementTarget = .bonsai
    var isTreePlaced = false
    var windowScreen: WindowScreen = .environmentSelection

    /// Quando a janela principal e reaberta (ex.: ao sair do imersivo),
    /// a splash nao roda de novo.
    var hasCompletedSplash = false
}
#endif
