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
        ZStack {
            Color("onboardingBackground")
                .ignoresSafeArea()

            VStack(spacing: 0) {

                Text(StringCatalog.collectOrigamis)
                    .font(.custom("CaveatBrush-Regular", size: 38))
                    .foregroundStyle(.blueNikki)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .padding(.top, 32)

                AnimatedImage(name: "tsuruanimation.gif")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 320, height: 320)
                    .padding(.top, 63)
                    .padding(.bottom, 34)

                Text(StringCatalog.yourScrapsTransformIntoMemories)
                    .font(.custom("CaveatBrush-Regular", size: 32))
                    .foregroundStyle(.blueNikki)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                    .lineLimit(2)
                    .padding(.horizontal, 32)

                Spacer()

                VStack(spacing: 16) {
                    OnboardingPageControl(totalPages: 4, currentPage: 2)

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
            OnboardingFourthView()
        }
        .navigationDestination(isPresented: $goToScene) {
            OnboardingFourthView()
        }
    }
}

#Preview {
    NavigationStack {
        OnboardingThirdView()
    }
}
