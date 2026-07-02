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
                .frame(height: 300)
                .padding(.top, 40)
                .padding(.horizontal, 24)

            VStack(spacing: 12) {
                Text(title)
                    .font(.custom("CaveatBrush-Regular", size: 48))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(.custom("CaveatBrush-Regular", size: 28))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            Spacer()

            Button(action: action) {
                Text(buttonLabel)
                    .font(.custom("CaveatBrush-Regular", size: 28))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 72)
        }
        .frame(width: 480)
        .buttonEnvSelectionBackground()
        .clipShape(RoundedRectangle(cornerRadius: 32))
    }
}
