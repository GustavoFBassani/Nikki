//
//  ExitImmersiveButton.swift
//  Nikki
//

#if os(visionOS)
import SwiftUI

struct ExitImmersiveButton: View {
    let onExit: () -> Void

    var body: some View {
        Button {
            onExit()
        } label: {
            HStack(spacing: 18) {
                Image(systemName: "mountain.2.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.white)
                    .frame(width: 72, height: 72)
                    .background(.thinMaterial, in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(StringCatalog.exitImmersiveTitle)
                        .font(.custom("CaveatBrush-Regular", size: 40))
                        .foregroundStyle(.white)

                    Text(StringCatalog.exitImmersiveSubtitle)
                        .font(.custom("CaveatBrush-Regular", size: 28))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .glassBackgroundEffect(in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ExitImmersiveButton(onExit: {})
        .padding()
}
#endif
