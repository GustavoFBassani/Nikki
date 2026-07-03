//
//  NikkiGradientBackground.swift
//  Nikki
//
//  Created by Alex Fraga on 01/07/26.
//

import SwiftUI

/// Gradiente da splash screen
extension View {
    func nikkiGradientBackground() -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(
                    stops: [
                        .init(color: Color("bottomGradient").opacity(0.8), location: 0.0), // #D9E2E1
                        .init(color: Color("middleGradient"), location: 0.5),              // #A7C4C9
                        .init(color: Color("topGradient"), location: 1.0)                  // #50B3AA
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .nikkiGlassBackground()
            .ignoresSafeArea()
    }
    
    func buttonEnvSelectionBackground() -> some View {
        self
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(
                    stops: [
                        .init(color: Color("bottomButtonGradientEnv"), location: 0.0), // #BCA7B1
                        .init(color: Color("topButtonGradientEnv"), location: 1.0)     // #5589A2
                    ],
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .nikkiGlassBackground()
            .ignoresSafeArea()
    }

    /// `glassBackgroundEffect` só existe no visionOS; no-op no iOS.
    @ViewBuilder
    func nikkiGlassBackground() -> some View {
        #if os(visionOS)
        self.glassBackgroundEffect()
        #else
        self
        #endif
    }
}
