//
//  EnvironmentSelectionView.swift
//  Nikki
//
//  Created by Alex Fraga on 01/07/26.
//

import SwiftUI

struct EnvironmentSelectionView: View {
    var body: some View {
        VStack(spacing: 28) {
            Text(StringCatalog.nikki)
                .font(.custom("CaveatBrush-Regular", size: 72))
                .foregroundStyle(.white)

            HStack(spacing: 20) {
                Button("Botão 1") {
                    // TODO: configurar ação
                }
                Button("Botão 2") {
                    // TODO: configurar ação
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.extraLarge)
        }
    }
}

