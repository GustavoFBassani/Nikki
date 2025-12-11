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
        ZStack {
            Color("onboardingBackground")
                .ignoresSafeArea()

            VStack(spacing: 0) {

                VStack(spacing: 64) {
                    Text("Registre seus momentos")
                        .font(.custom("CaveatBrush-Regular", size: 38))
                        .foregroundStyle(.blueNikki)

                    Image("scrapExample")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 320, height: 320)
                }
                .padding(.top, 32)

                Text("Transforme seus momentos \n em registros personalizados")
                    .font(.custom("CaveatBrush-Regular", size: 32))
                    .foregroundStyle(.blueNikki)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 18)

                Spacer()

                VStack(spacing: 16) {
                    OnboardingPageControl(totalPages: 4, currentPage: 1)

                    OnboardingButtons(
                        primaryTitle: String(localized: "Próximo"),
                        secondaryTitle: String(localized: "Pular"),
                        isSecondHidden: false,
                        onPrimaryTap: {
                            goToNext = true
                        },
                        onSecondaryTap: {
                            goToScene = true
                        }
                    )
                }
            }
            .padding(.top, 8)
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
    NavigationStack {
        OnboardingSecondView()
    }
}
