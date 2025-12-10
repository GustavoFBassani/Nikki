//
//  BubbleTipStyle.swift
//  Nikki
//
//  Created by Rafael Toneto on 09/12/25.
//

import SwiftUI
import TipKit

// tip style for adding a tsuru
struct BubbleTipStyle: TipViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: .topTrailing) {

            // body
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {

                    configuration.title
                        .font(.custom("CaveatBrush-Regular", size: 24))
                        .foregroundColor(.blueNikki)

                    if let message = configuration.message {
                        message
                            .font(.custom("CaveatBrush-Regular", size: 18))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(width: 300, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
            )

            // tail on top-right
            Image("tipTail")
                .resizable()
                .frame(width: 37, height: 13)
                .offset(x: -9, y: -9)
        }
        .padding(.top, 10)
    }
}

// tip style for localizing tsurus
struct BottomLeftBubbleTipStyle: TipViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: .bottomLeading) {

            // body
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {

                    configuration.title
                        .font(.custom("CaveatBrush-Regular", size: 24))
                        .foregroundColor(.blueNikki)

                    if let message = configuration.message {
                        message
                            .font(.custom("CaveatBrush-Regular", size: 18))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(width: 300, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
            )

            // tail
            Image("tipTail")
                .resizable()
                .frame(width: 37, height: 13)
                .rotationEffect(.degrees(180))
                .offset(x: 9, y: 9)
        }
        .padding(.bottom, 10)
    }
}
