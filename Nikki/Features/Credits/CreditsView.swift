//
//  CreditsView.swift
//  Nikki
//
//  Created by Rafael Toneto on 05/12/25.
//

import SwiftUI

struct CreditsView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        
        ZStack{
            VStack(spacing: 32) {

                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image("leftChevron")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                    }
                    Spacer()
                }
                .overlay(
                    Text("Creditos")
                        .font(.custom("CaveatBrush-Regular", size: 24))
                        .foregroundStyle(Color(.black))
                )
                .padding(.horizontal)

                VStack(spacing: 20){
                    VStack(spacing: 8){
                        Text("Tree")
                            .foregroundStyle(Color(.blueNikki))
                            .font(.custom("CaveatBrush-Regular", size: 22))
                            .frame(width: 361, alignment: .leading)

                        Text("3D Model: “Cherry Tree” Created by: local.yany Available in: https://sketchfab.com/3d-models/cherry-tree-5f6d9059b971429999343e0f398bf487  License: Creative Commons Attribution 4.0 (CC BY 4.0) https://creativecommons.org/licenses/by/4.0/")
                            .foregroundStyle(Color(.blueNikki))
                            .font(.system(size: 13, weight: .regular))
                            .frame(width: 361, alignment: .leading)
                    }
                    .padding(.horizontal)

                    VStack(spacing: 8){
                        Text("Scenery")
                            .foregroundStyle(Color(.blueNikki))
                            .font(.custom("CaveatBrush-Regular", size: 22))
                            .frame(width: 361, alignment: .leading)

                        Text("3D Model “Japanese garden” — created by Katydid. License: Sketchfab Free Standard (https://sketchfab.com/licenses/free-standard).  Modified by Martina Adegas. Available in: https://sketchfab.com/3d-models/japanese-garden-3083a8ae73bd47c68e655713915787f5")
                            .foregroundStyle(Color(.blueNikki))
                            .font(.system(size: 13, weight: .regular))
                            .frame(width: 361, alignment: .leading)
                    }
                    .padding(.horizontal)

                    VStack(spacing: 8){
                        Text("Gate")
                            .foregroundStyle(Color(.blueNikki))
                            .font(.custom("CaveatBrush-Regular", size: 22))
                            .frame(width: 361, alignment: .leading)

                        Text("Model: Japanese Torii Gate Author: Sahir Virmani Model's Link: https://sketchfab.com/3d-models/japanese-torii-gate-2027a248de1b4b70985ff97e708fb50d  License: Creative Commons Attribution (CC BY 4.0)")
                            .foregroundStyle(Color(.blueNikki))
                            .font(.system(size: 13, weight: .regular))
                            .frame(width: 361, alignment: .leading)
                    }
                    .padding(.horizontal)

                    VStack(spacing: 8){
                        Text("Bandstand")
                            .foregroundStyle(Color(.blueNikki))
                            .font(.custom("CaveatBrush-Regular", size: 22))
                            .frame(width: 361, alignment: .leading)

                        Text("Model: Japan HW Author: Kumekovaaa Model's Link: https://sketchfab.com/3d-models/japan-hw-c3d60d0e25224ea592e87425a2f3b130  License: CC BY 4.0 — Creative Commons Attribution License's Link: https://creativecommons.org/licenses/by/4.0/")
                            .foregroundStyle(Color(.blueNikki))
                            .font(.system(size: 13, weight: .regular))
                            .frame(width: 361, alignment: .leading)
                    }
                    .padding(.horizontal)

                    VStack(spacing: 8){
                        Text("Lamp")
                            .foregroundStyle(Color(.blueNikki))
                            .font(.custom("CaveatBrush-Regular", size: 22))
                            .frame(width: 361, alignment: .leading)

                        Text("Model: Chinese Lamp - 4096px² Author: Mark Peters Model's Link: https://sketchfab.com/3d-models/chinese-lamp-4096px2-9eddb4de98274410b7405f7ea6667f3a  License: Creative Commons Attribution (CC BY)")
                            .foregroundStyle(Color(.blueNikki))
                            .font(.system(size: 13, weight: .regular))
                            .frame(width: 361, alignment: .leading)
                    }
                    .padding(.horizontal)
                }
                .preferredColorScheme(.light)
                .navigationBarBackButtonHidden(true)
            }
        }
    }
}

#Preview {
    CreditsView()
}
