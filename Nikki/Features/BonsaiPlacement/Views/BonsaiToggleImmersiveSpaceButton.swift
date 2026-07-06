//
//  BonsaiToggleImmersiveSpaceButton.swift
//  Nikki
//
//  Created by Anthony Antonelli Andrade on 22/06/26.
//

#if os(visionOS)
import SwiftUI

struct BonsaiToggleImmersiveSpaceButton: View {

    @Environment(BonsaiAppModel.self) private var appModel
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace

    var body: some View {
        Button {
            Task { @MainActor in
                await toggleImmersiveSpace()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                Text(buttonLabel)
                    .font(Fonts.Body)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 52)
        }
        .buttonStyle(.bordered)
        .tint(.white.opacity(0.4))
        .disabled(appModel.immersiveSpaceState == .inTransition)
    }

    private func toggleImmersiveSpace() async {
        switch appModel.immersiveSpaceState {
        case .open:
            appModel.immersiveSpaceState = .inTransition
            await dismissImmersiveSpace()

        case .closed:
            appModel.immersiveSpaceState = .inTransition
            switch await openImmersiveSpace(id: appModel.immersiveSpaceID) {
            case .opened:
                break
            case .userCancelled, .error:
                fallthrough
            @unknown default:
                appModel.immersiveSpaceState = .closed
            }

        case .inTransition:
            break
        }
    }

    private var iconName: String {
        appModel.immersiveSpaceState == .open ? "xmark.circle.fill" : "tree.fill"
    }

    private var buttonLabel: String {
        switch appModel.immersiveSpaceState {
        case .open: return StringCatalog.bonsaiClosePlacement
        case .closed: return StringCatalog.bonsaiOpenPlacement
        case .inTransition: return StringCatalog.bonsaiWait
        }
    }
}
#endif
