//
//  VisionHomeRouter.swift
//  Nikki
//

#if os(visionOS)
import SwiftUI

struct VisionHomeRouter: View {
    @Environment(BonsaiAppModel.self) private var appModel

    var body: some View {
        Group {
            switch appModel.windowScreen {
            case .environmentSelection:
                EnvironmentSelectionView()
            case .bonsaiControl:
                BonsaiContentView()
            }
        }
        .frame(height: routerHeight)
    }

    private var routerHeight: CGFloat? {
        if appModel.windowScreen == .bonsaiControl,
           appModel.immersiveSpaceState == .open {
            return nil
        }
        return 720
    }
}
#endif
