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
            HStack(spacing: 16) {
                Image(systemName: "mountain.2.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(.thinMaterial, in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(StringCatalog.exitImmersiveTitle)
                        .font(Fonts.Body)
                        .foregroundStyle(.white)

                    Text(StringCatalog.exitImmersiveSubtitle)
                        .font(Fonts.Footnote)
                        .foregroundStyle(.white.opacity(0.85))
                }

                Spacer(minLength: 0)
            }
            .padding(12)
            .frame(minWidth: 320, alignment: .leading)
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
