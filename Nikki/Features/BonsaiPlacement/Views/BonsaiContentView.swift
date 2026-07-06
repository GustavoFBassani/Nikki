//
//  BonsaiContentView.swift
//  Nikki
//
//  Created by Anthony Antonelli Andrade on 22/06/26.
//

#if os(visionOS)
import SwiftUI

struct BonsaiContentView: View {

    @Environment(BonsaiAppModel.self) private var appModel
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    var body: some View {
        ZStack(alignment: .topLeading) {
            controlCard
                .frame(maxWidth: .infinity)

            backButton
                .padding(32)
        }
        .animation(.easeInOut(duration: 0.3), value: appModel.isTreePlaced)
        .animation(.easeInOut(duration: 0.3), value: appModel.immersiveSpaceState)
    }

    // MARK: - Card de controle

    private var controlCard: some View {
        VStack(spacing: 0) {
            Image("bonsai3d")
                .resizable()
                .scaledToFit()
                .frame(width: 331, height: 264)
                .padding(.top, 40)
                .padding(.horizontal, 24)

            VStack(spacing: 8) {
                Text(StringCatalog.bonsaiTitle)
                    .font(.custom("CaveatBrush-Regular", size: 48))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(StringCatalog.bonsaiSubtitle)
                    .font(Fonts.Body)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 328)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            Spacer(minLength: 16)

            statusSection

            Spacer(minLength: 16)

            BonsaiToggleImmersiveSpaceButton()
                .padding(.horizontal, 72)
                .padding(.bottom, 56)
        }
        .buttonEnvSelectionBackground()
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .frame(width: 494)
        .padding(.vertical, 42)
    }

    @ViewBuilder
    private var statusSection: some View {
        if appModel.isTreePlaced {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                Text(StringCatalog.bonsaiPlaced)
                    .font(Fonts.Subheadline)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(.white.opacity(0.15), in: Capsule())
        } else if appModel.immersiveSpaceState == .open {
            VStack(alignment: .leading, spacing: 12) {
                BonsaiInstructionRow(icon: "viewfinder", text: StringCatalog.bonsaiInstructionLook)
                BonsaiInstructionRow(icon: "hand.tap.fill", text: StringCatalog.bonsaiInstructionTap)
                BonsaiInstructionRow(icon: "hand.draw.fill", text: StringCatalog.bonsaiInstructionDrag)
            }
            .padding(20)
            .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 20))
        }
    }

    // MARK: - Voltar

    private var backButton: some View {
        Button {
            Task { @MainActor in
                if appModel.immersiveSpaceState == .open {
                    appModel.immersiveSpaceState = .inTransition
                    await dismissImmersiveSpace()
                    appModel.immersiveSpaceState = .closed
                }
                withAnimation { appModel.windowScreen = .environmentSelection }
            }
        } label: {
            Label(StringCatalog.back, systemImage: "chevron.left")
                .font(Fonts.Subheadline)
                .foregroundStyle(.white)
        }
        .buttonStyle(.bordered)
        .tint(.white.opacity(0.4))
    }
}

struct BonsaiInstructionRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .frame(width: 28)
            Text(text)
                .font(Fonts.Subheadline)
        }
        .foregroundStyle(.white)
    }
}

#Preview {
    BonsaiContentView()
        .nikkiGradientBackground()
        .environment(BonsaiAppModel())
}
#endif
