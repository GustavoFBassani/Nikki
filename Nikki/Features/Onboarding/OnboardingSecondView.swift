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
                    Text(StringCatalog.registerYourMoments)
                        .font(.custom("CaveatBrush-Regular", size: 38))
                        .foregroundStyle(.blueNikki)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)

                    Image("scrapExample")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 320, height: 320)
                }
                .padding(.top, 32)

                Text(StringCatalog.transformYourMoments)
                    .font(.custom("CaveatBrush-Regular", size: 32))
                    .foregroundStyle(.blueNikki)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                    .lineLimit(2)
                    .padding(.horizontal, 32)
                    .padding(.top, 18)

                Spacer()

                VStack(spacing: 16) {
                    OnboardingPageControl(totalPages: 4, currentPage: 1)

                    OnboardingButtons(
                        primaryTitle: StringCatalog.next,
                        secondaryTitle: StringCatalog.jump,
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
