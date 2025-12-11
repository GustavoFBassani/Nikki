//
//  OnboardingMotivationPersistence.swift
//  Nikki
//
//  Created by Rafael Toneto on 11/12/25.
//

import Foundation
import SwiftUI
import NikkiProject

// saves motivation typed in onboarding.
func saveOnboardingMotivation(_ rawText: String) {
    let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else { return }

    let service = ScrapService.shared

    do {
        let motivation = Motivation(text: text)
        try service.saveMotivation(motivation)
    } catch {
        print("Erro ao salvar motivação no onboarding: \(error)")
    }
}
