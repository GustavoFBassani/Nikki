//
//  BonsaiPlacementStatusView.swift
//  Nikki
//
//  Created by Anthony Antonelli Andrade on 22/06/26.
//

#if os(visionOS)
import SwiftUI

struct BonsaiPlacementStatusView: View {

    let loadState: BonsaiPlacementManager.LoadState
    let isTreePlaced: Bool
    let hasSurface: Bool
    let target: BonsaiAppModel.PlacementTarget

    var body: some View {
        Group {
            switch loadState {
            case .loading:
                card {
                    ProgressView()
                    Text(StringCatalog.bonsaiLoading(targetName))
                        .font(.headline)
                }

            case .failed(let message):
                card {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title)
                        .foregroundStyle(.yellow)
                    Text(message)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                }

            case .ready:
                if isTreePlaced {
                    EmptyView()
                } else if !hasSurface {
                    card {
                        ProgressView()
                        Text(StringCatalog.bonsaiSearchingSurface)
                            .font(.headline)
                        Text(StringCatalog.bonsaiSearchingHint)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    card {
                        Image(systemName: "hand.tap.fill")
                            .font(.title)
                            .foregroundStyle(.tint)
                        Text(StringCatalog.bonsaiTapToPlace(targetName))
                            .font(.headline)
                            .multilineTextAlignment(.center)
                    }
                }
            }
        }
    }

    private var targetName: String {
        switch target {
        case .bonsai: return StringCatalog.bonsaiTargetBonsai
        case .scene: return StringCatalog.bonsaiTargetScene
        }
    }

    @ViewBuilder
    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 12) {
            content()
        }
        .padding(24)
        .frame(maxWidth: 360)
        .glassBackgroundEffect(in: RoundedRectangle(cornerRadius: 20))
    }
}
#endif
