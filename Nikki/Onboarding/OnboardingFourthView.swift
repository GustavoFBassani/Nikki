//
//  OnboardingFourthView.swift
//  Nikki
//
//  Created by Alex Fraga on 10/12/25.
//

import SwiftUI

struct OnboardingFourthView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    @State private var goToNext = false
    @State var motivation: String = ""

    var body: some View {
        ZStack {
            Color("onboardingBackground")
                .ignoresSafeArea()
                .onTapGesture { hideKeyboard() }

            VStack(spacing: 0) {

                VStack(spacing: 114) {
                    Text("Intenção do journal")
                        .font(.custom("CaveatBrush-Regular", size: 38))
                        .foregroundStyle(.blueNikki)

                    MotivationRoll(motivation: $motivation, isEditing: true)
                }
                .padding(.top, 32)

                VStack(spacing: 17) {
                    Text("Ela guia seu processo de journaling e ajuda a lembrar porque começou a prática")
                        .font(.custom("CaveatBrush-Regular", size: 32))
                        .foregroundStyle(.blueNikki)
                        .multilineTextAlignment(.center)

                    Text("*Clique no pergaminho para escrever sua motivação\nVocê poderá atualizar quando quiser")
                        .font(Fonts.Footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()

                VStack(spacing: 16) {
                    OnboardingPageControl(totalPages: 4, currentPage: 3)

                    OnboardingButtons(
                        primaryTitle: "Próximo",
                        secondaryTitle: "",
                        isSecondHidden: true,
                        onPrimaryTap: {
                            saveOnboardingMotivation(motivation)
                            hasSeenOnboarding = true
                            goToNext = true
                        },
                        onSecondaryTap: { }
                    )
                }
            }
            .padding(.top, 8)
            .navigationBarBackButtonHidden(true)
            .preferredColorScheme(.light)
            .navigationDestination(isPresented: $goToNext) {
                SceneView()
            }
        }
    }
}

#Preview {
    NavigationStack {
        OnboardingFourthView()
    }
}
