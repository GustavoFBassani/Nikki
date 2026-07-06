//
//  EnvironmentCard.swift
//  Nikki
//
//  Created by Alex Fraga on 02/07/26.
//

import SwiftUI

struct EnvironmentCard: View {
    let imageName: String
    let title: String
    let description: String
    let buttonLabel: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 331, height: 264)
                .padding(.top, 40)
                .padding(.horizontal, 24)

            VStack(spacing: 8) {
                Text(title)
                    .font(.custom("CaveatBrush-Regular", size: 48))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(.custom("CaveatBrush-Regular", size: 28))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 328)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            Button(action: action) {
                Text(buttonLabel)
                    .font(.custom("CaveatBrush-Regular", size: 28))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.bordered)
            .tint(.white.opacity(0.4))
            .padding(.horizontal, 100)
            .padding(.top, 40)
            .padding(.bottom, 72)
        }
        .buttonEnvSelectionBackground()
        .clipShape(RoundedRectangle(cornerRadius: 32))
    }
}
