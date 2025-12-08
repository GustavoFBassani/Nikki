//
//  Motivation.swift
//  Nikki
//
//  Created by sofia leitao on 08/12/25.
//

import SwiftUI

struct MotivationRoll: View {
    var message: String

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
                .padding(.top, 5)
                .padding(.horizontal, 28)

                Text(message)
                    .font(Fonts.Parchment)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 28)
        }
        .frame(width: 306, height: 147)
    }
}

#Preview {
    MotivationRoll(
//        message: "aaaaaaaaa"
        message: """
Através do journal eu desejo
registrar momentos do cotidiano
para ter lembranças de
acontecimentos especiais.
"""
    )
    .padding()
    .background(Color.gray.opacity(0.3))
}
