//
//  OnboardingSecond.swift
//  Nikki
//
//  Created by Alex Fraga on 10/12/25.
//

import SwiftUI

struct OnboardingSecondView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    @State private var goToNext = false
    @State private var goToScene = false
    
    var body: some View {
        ZStack{
            Color.background
            .ignoresSafeArea()
            
            VStack(alignment: .center, spacing: 50){
                VStack(spacing: 64){
                    Text("Registre seus momentos")
                        .font(.custom("CaveatBrush-Regular", size: 38))
                        .foregroundStyle(.blueNikki)
                    
                    Image("scrapExample")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 320, height: 320)
                    
                }
                
                Text("Transforme seus momentos \n em registros personalizados")
                    .font(.custom("CaveatBrush-Regular", size: 32))
                    .foregroundStyle(.blueNikki)
                    .multilineTextAlignment(.center)
                
                OnboardingPageControl(totalPages: 4, currentPage: 1)
                
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
                .padding(.bottom, 25)
            }
        }
        .preferredColorScheme(.light)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $goToNext) {
            OnboardingThirdView()
        }
        .navigationDestination(isPresented: $goToScene) {
            OnboardingFourthView()
        }
    }
}

#Preview {
    OnboardingSecondView()
}
