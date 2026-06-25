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
    @State var motivationString: String = ""
    
    func saveOnboardingMotivation(_ rawText: String) {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        do {
            let service = MotivationService.shared
            let motivation = Motivation(text: text, updatedAt: Date())
            try service.saveMotivation(motivation)
        } catch {
            print("Erro ao salvar motivação no onboarding: \(error)")
        }
    }
    
    var body: some View {
        ZStack {
            Color("onboardingBackground")
                .ignoresSafeArea()
                .onTapGesture { hideKeyboard() }

            VStack(spacing: 0) {

                VStack(spacing: 114) {
                    Text(StringCatalog.journalIntention)
                        .font(.custom("CaveatBrush-Regular", size: 38))
                        .foregroundStyle(.blueNikki)
                        .padding(.horizontal, 32)

                    MotivationRoll(motivation: $motivationString, isEditing: true)
                }
                .padding(.top, 32)

                VStack(spacing: 17) {
                    Text(StringCatalog.itGuidesYourProccess)
                        .font(.custom("CaveatBrush-Regular", size: 32))
                        .foregroundStyle(.blueNikki)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.6)
                        .lineLimit(3)

                    Text(StringCatalog.clickOnTheParchment)
                        .font(Fonts.Footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()

                VStack(spacing: 16) {
                    OnboardingPageControl(totalPages: 4, currentPage: 3)

                    OnboardingButtons(
                        primaryTitle: StringCatalog.next,
                        secondaryTitle: "",
                        isSecondHidden: true,
                        onPrimaryTap: {
                            // saves motivation
                            saveOnboardingMotivation(motivationString)
                            // marks onboarding as seen
                            hasSeenOnboarding = true
                        },
                        onSecondaryTap: { }
                    )
                }
            }
            .padding(.top, 8)
            .navigationBarBackButtonHidden(true)
            .preferredColorScheme(.light)
        }
    }
}

#Preview {
    NavigationStack {
        OnboardingFourthView()
    }
}
