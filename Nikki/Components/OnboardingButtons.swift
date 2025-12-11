//
//  OnboardingButtons.swift
//  Nikki
//
//  Created by Rafael Toneto on 10/12/25.
//

import SwiftUI

struct OnboardingButtons: View {
    // texts
    let primaryTitle: String
    let secondaryTitle: String
    
    // variable for second button to appear
    let isSecondHidden: Bool
    
    // actions
    let onPrimaryTap: () -> Void
    let onSecondaryTap: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            
            // main button
            Button(action: onPrimaryTap) {
                Text(primaryTitle)
                    // aqui você pode trocar para o seu Fonts.Button
                    .font(.custom("CaveatBrush-Regular", size: 24))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .background(
                Capsule()
                    .fill(.blueNikki)
            )
            
            // second button
            if !isSecondHidden {
                Button(action: onSecondaryTap) {
                    Text(secondaryTitle)
                        .font(.custom("CaveatBrush-Regular", size: 20))
                        .foregroundColor(.blueNikki)
                }
            }
        }
        // margem lateral parecida com o layout do screenshot
        .padding(.horizontal, 62)
    }
}
