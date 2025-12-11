//
//  OnboardingThirdView.swift
//  Nikki
//
//  Created by Rafael Toneto on 10/12/25.
//

import SwiftUI
import SDWebImage
import SDWebImageSwiftUI

struct OnboardingThirdView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    @State private var goToNext = false
    @State private var goToScene = false
    
    var body: some View {
        VStack(spacing: 0){
            Text("Colecione origamis")
                .font(.custom("CaveatBrush-Regular", size: 38))
                .foregroundStyle(.blueNikki)
            
            AnimatedImage(name: "tsuruanimation.gif")
                .resizable()
                .scaledToFit()
                .frame(width: 320, height: 320)
                .padding(.top, 63)
                .padding(.bottom, 50)
            
            Text("Seus scraps se transformam em origamis, simbolizando suas memórias")
                .font(Font.custom("CaveatBrush-Regular", size: 32))
                .foregroundStyle(.blueNikki)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 315)
            
            OnboardingPageControl(totalPages: 4, currentPage: 2)
            
            OnboardingButtons(
                primaryTitle: "Próximo",
                secondaryTitle: "Pular",
                isSecondHidden: false,
                onPrimaryTap: {
                    goToNext = true
                },
                onSecondaryTap: {
                    goToScene = true
                }
            )
            .padding(.top, 40)
            .navigationBarBackButtonHidden(true)
            .navigationDestination(isPresented: $goToNext) {
                OnboardingFourthView()
            }
            .navigationDestination(isPresented: $goToScene) {
                OnboardingFourthView()
            }
        }
    }
}

#Preview {
    OnboardingThirdView()
}
