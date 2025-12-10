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
        ZStack(alignment: .topTrailing) {

            // tip body
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {

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
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(width: 300, alignment: .leading)   // largura do balão
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
            )
            //tip tail
            Image("tipTail")
                .resizable()
                .frame(width: 37, height: 13)
                .offset(x: -9, y: -9)
        }
        .padding(.top, 10)
    }
}
