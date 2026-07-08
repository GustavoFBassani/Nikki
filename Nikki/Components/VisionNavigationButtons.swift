//
//  Untitled.swift
//  Nikki
//
//  Created by Gustavo Ferreira bassani on 06/07/26.
//

import SwiftUI

struct VisionNavigationButtons: View {
    var vm: SceneViewModel
    let dismiss: ()->Void
    let navigateToLeft: ()->Void
    let navigateToRight: ()->Void
    
    var body: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 500))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            
            HStack {
                Button {
                    navigateToLeft()
                } label: {
                    Image(systemName: "chevron.left")
                        .frame(width: 52, height: 52)
                        .background(.thinMaterial, in: Circle())
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                
                Button {
                    navigateToRight()
                } label: {
                    Image(systemName: "chevron.right")
                        .frame(width: 52, height: 52)
                        .background(.thinMaterial, in: Circle())
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)
                
            }
        }
        .padding(12)
#if os(visionOS)
        .glassBackgroundEffect(
            in: RoundedRectangle(cornerRadius: 48)
        )
#endif
    }
}

#Preview {
//    VisionNavigationButtons(state: AttachmentState(), vm: SceneViewModel(), dismiss: { }, navigateToLeft: { }, navigateToRight: { })
}
