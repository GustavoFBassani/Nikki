//
//  MotivationRoll.swift
//  Nikki
//
//  Created by sofia leitao on 09/12/25.
//
import SwiftUI

struct MotivationRoll: View {
    var motivation: String

    var body: some View {
        ZStack(alignment: .top) {
            Image("pergaminho")
                .resizable()
                .scaledToFit()
       

            VStack(spacing: 7) {
                VStack(spacing: 0) {
                    Text("Minha intenção")
                        .font(Fonts.Subheadline)
                        .foregroundColor(.blueNikki)
                    Image("stroke")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 143)
                }
                .padding(.top, 8)
                .padding(.horizontal, 28)

                Text(motivation)
                    .font(Fonts.Parchment)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
            }
            .padding(.horizontal, 28)
        }
        .frame(width: 306, height: 147)
    }
}

#Preview {
    MotivationRoll(
//        message: "aaaaaaaaa"
        motivation: """
Através do journal eu desejo
registrar momentos do cotidiano
para ter lembranças de
acontecimentos especiais.
"""
    )
    .padding()
    .background(Color.gray.opacity(0.3))
}
