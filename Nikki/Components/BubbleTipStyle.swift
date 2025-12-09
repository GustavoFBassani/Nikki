//
//  BubbleTipStyle.swift
//  Nikki
//
//  Created by Rafael Toneto on 09/12/25.
//


import SwiftUI
import TipKit

struct BubbleTipStyle: TipViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 0) {

            // tail
            Triangle()
                .fill(Color.white)
                .frame(width: 28, height: 14)
                .rotationEffect(.degrees(180))
                .offset(x: 120, y: 6)
                .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 2)

            // body
            HStack(alignment: .top, spacing: 12) {

                VStack(alignment: .leading, spacing: 6) {

                    configuration.title
                        .font(.custom("CaveatBrush-Regular", size: 26))
                        .foregroundColor(Color(red: 0.04, green: 0.07, blue: 0.21))

                    if let message = configuration.message {
                        message
                            .font(.custom("CaveatBrush-Regular", size: 20))
                            .foregroundColor(.gray)
                    }
                }

                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
            )
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()

        return path
    }
}
