//
//  VisionScrapMenu.swift
//  Nikki
//
//  Created by Gustavo Ferreira bassani on 03/07/26.
//

#if os(visionOS)
import SwiftUI


struct VisionScrapMenu: View {
    @Binding var isPaperMenuOpen: Bool
    let onVisualizeOrigamis: () -> Void
    let onSelectStyle: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            Button {
                onVisualizeOrigamis()
            } label: {
                HStack(spacing: 24) {
                    Image("origamiVision")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)

                    Text(StringCatalog.visualizeOrigamis)
                        .font(.custom("CaveatBrush-Regular", size: 30))
                        .foregroundStyle(.white)

                    Spacer()
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 24) {
                Button {
                    withAnimation(.easeInOut(duration: 0.22)) {
                        isPaperMenuOpen.toggle()
                        print("botao ativando")
                    }
                } label: {
                    HStack(spacing: 24) {
                        Image("plusVision")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 58, height: 58)

                        Text(StringCatalog.createYourScrap)
                            .font(.custom("CaveatBrush-Regular", size: 30))
                            .foregroundStyle(.white)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                            .rotationEffect(.degrees(isPaperMenuOpen ? 90 : 0))
                    }
                }
                .buttonStyle(.plain)

                if isPaperMenuOpen {
                    VStack(alignment: .leading, spacing: 26) {
                        PaperOptionButton(
                            imageName: "dottedVision",
                            title: StringCatalog.dottedPaper
                        ) {
                            openStyle(at: 0)
                        }

                        PaperOptionButton(
                            imageName: "lanternVision",
                            title: StringCatalog.lanterns
                        ) {
                            openStyle(at: 1)
                        }

                        PaperOptionButton(
                            imageName: "fanVision",
                            title: StringCatalog.fan
                        ) {
                            openStyle(at: 2)
                        }
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .padding(.horizontal, 48)
        .padding(.vertical, 30)
        .frame(width: 500, alignment: .leading)
        .glassBackgroundEffect(
            in: RoundedRectangle(cornerRadius: 48)
        )
        
    }

    private func openStyle(at index: Int) {
        let styles = Array(PaperStyles.allCases)

        guard styles.indices.contains(index) else { return }

        onSelectStyle(styles[index].name)
    }
}


#Preview {
    VisionScrapMenu(isPaperMenuOpen: .constant(true), onVisualizeOrigamis: { }) { string in }
}

private struct PaperOptionButton: View {
    let imageName: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 34) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 74, height: 74)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white)
                    )

                Text(title)
                    .font(.custom("CaveatBrush-Regular", size: 30))
                    .foregroundStyle(.white)

                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}
#endif
