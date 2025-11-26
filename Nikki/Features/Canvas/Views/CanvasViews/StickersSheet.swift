//
//  StickersSheet.swift
//  Nikki
//
//  Created by Gustavo Ferreira bassani on 26/11/25.
//
import SwiftUI

struct StickersSheet: View {
    let stickers: [String]
    let onSelect: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    

    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(),GridItem()], spacing: 37) {
                    ForEach(stickers, id: \.self) { stickerName in
                        Button {
                            onSelect(stickerName)
                            dismiss()
                        } label: {
                            Image(stickerName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 133, height: 133)
                                .background(.gray.opacity(0.10))
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8).stroke(Color.customStroke, lineWidth: 0.5)
                                )
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Carimbos")
//            .navigationTitleFont(<#T##font: UIFont##UIFont#>) COLOCAR A FONTE DE PREFERENCIA AQUIII
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label : {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
        .background(Color.clear)
    }
}

#Preview {
    StickersSheet(stickers: [
        "redLetter",
        "sparkle",
        "leque",
        "bamboo",
        "blueDragon",
        "cloud",
        "dragon",
        "envelope",
        "fish",
        "flower",
        "fuji",
        "goldenStar",
        "greenBamboo",
        "house",
        "lamp",
        "letter",
        "redEnvelope",
        "moth",
        "orangeFish",
        "redTorii",
        "star",
        "teaBag",
        "zen"
  ]) { selected in
        // Preview action
        print("Selected sticker: \(selected)")
    }
}
