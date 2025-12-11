//
//  OnboardingThirdView.swift
//  Nikki
//
//  Created by Rafael Toneto on 10/12/25.
//

import SwiftUI

struct OnboardingFirstView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    @State private var goToNext = false
    @State private var goToScene = false

    var body: some View {
        ZStack {
            Color("onboardingBackground")
                .ignoresSafeArea()

            VStack(spacing: 0) {

                VStack(spacing: 0) {
                    Text("Nikki")
                        .font(.custom("CaveatBrush-Regular", size: 77))
                        .foregroundStyle(.blueNikki)

                    Text("Seu jardim de memórias")
                        .font(.custom("CaveatBrush-Regular", size: 30))
                        .foregroundStyle(.blueNikki)
                }

                Image("mountain")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 393, height: 282)
                    .clipped()
                    .padding(.top, 45)
                    .padding(.bottom, 22)

                Text("Um novo jeito de praticar journaling")
                    .font(.custom("CaveatBrush-Regular", size: 32))
                    .foregroundStyle(.blueNikki)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                VStack(spacing: 16) {
                    OnboardingPageControl(totalPages: 4, currentPage: 0)

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
                }
            }
            .padding(.top, 8)
        }
        .preferredColorScheme(.light)
        .navigationDestination(isPresented: $goToNext) {
            OnboardingSecondView()
        }
        .navigationDestination(isPresented: $goToScene) {
            OnboardingFourthView()
        }
    }
}

#Preview {
    NavigationStack {
        OnboardingFirstView()
    }
}
