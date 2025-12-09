//
//  BubbleTipStyle.swift
//  Nikki
//
//  Created by Rafael Toneto on 09/12/25.
//


import TipKit
import SwiftUI

struct BubbleTipStyle: TipViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                if let image = configuration.image {
                    image
                        .font(.system(size: 20))
                }

                VStack(alignment: .leading, spacing: 4) {
                    configuration.title
                        .font(.headline)
                    if let message = configuration.message {
                        message
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(radius: 8)
        )
    }
}