//
//  StickersSheet.swift
//  Nikki
//
//  Created by Gustavo Ferreira bassani on 26/11/25.
//

import SwiftUI

// MARK: - StickersSheet
struct StickersSheet: View {
    // MARK: - Properties
    let stickers: [String]
    let onSelect: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    private let columns = [GridItem(), GridItem()]
    private let spacing: CGFloat = 37
    private let itemSize: CGSize = CGSize(width: 133, height: 133)
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            stickersGrid
                .navigationTitle("Carimbos")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { closeButton }
        }
        .background(Color.clear)
    }
    
    // MARK: - View Components
    private var stickersGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(stickers, id: \.self) { stickerName in
                    stickerButton(for: stickerName)
                }
            }
            .padding()
        }
    }
    
    private func stickerButton(for stickerName: String) -> some View {
        Button {
            onSelect(stickerName)
            dismiss()
        } label: {
            stickerImage(named: stickerName)
        }
    }
    
    private func stickerImage(named name: String) -> some View {
        Image(name)
            .resizable()
            .scaledToFill()
            .frame(width: itemSize.width, height: itemSize.height)
            .background(.gray.opacity(0.10))
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.customStroke, lineWidth: 0.5)
            )
    }
    
    @ToolbarContentBuilder
    private var closeButton: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
            }
        }
    }
}

// MARK: - Preview
#Preview {
    StickersSheet(
        stickers: [
            "redLetter", "sparkle", "leque", "bamboo", "blueDragon",
            "cloud", "dragon", "envelope", "fish", "flower",
            "fuji", "goldenStar", "greenBamboo", "house", "lamp",
            "letter", "redEnvelope", "moth", "orangeFish", "redTorii",
            "star", "teaBag", "zen"
        ]
    ) { selected in
        print("Selected sticker: \(selected)")
    }
}
