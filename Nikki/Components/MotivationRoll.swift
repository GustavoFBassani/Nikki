//
//  MotivationRoll.swift
//  Nikki
//
//  Created by sofia leitao on 09/12/25.
//
import SwiftUI

struct MotivationRoll: View {
    @Binding var motivation: String
    var isEditing: Bool

    private let maxCharacters = 40
    private let maxLines = 4

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

                if isEditing {
                    TextEditor(text: $motivation)
                        .font(Fonts.Footnote)
                        .foregroundColor(.grayNikki)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 50)
                        .padding(.bottom, 30)
                        .frame(maxHeight: .infinity)
                        .onChange(of: motivation) { _, newValue in
                            limitText(newValue)
                        }
                } else {
                    Text(motivation)
                        .font(Fonts.Footnote)
                        .foregroundColor(.grayNikki)
                        .multilineTextAlignment(.center)
                        .lineLimit(4)
                        .padding(.horizontal, 28)
                        .padding(.bottom, 30)
                }
            }
        }
        .frame(width: 306, height: 147)
    }

    private func limitText(_ newValue: String) {
        var text = newValue

        //quebras de linha (max 4)
        var lines = text.components(separatedBy: .newlines)
        if lines.count > maxLines {
            lines = Array(lines.prefix(maxLines))
            text = lines.joined(separator: "\n")
        }

        //total de caracteres
        if text.count > maxCharacters {
            text = String(text.prefix(maxCharacters))
        }

        // salva no binding so se mudou
        if text != motivation {
            motivation = text
        }
    }
}

