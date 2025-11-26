//
//  ToolBarKit.swift
//  Nikki
//
//  Created by Gustavo Ferreira bassani on 25/11/25.
//

import SwiftUI

struct TabBarToolKit: View {
    
    var showPaperKit: () -> Void
    var showPencilTool: () -> Void
    var showImages: () -> Void
    var showMusics: () -> Void
    var showStickers: () -> Void
    
    var body: some View {
        HStack(spacing: 41) {
                Button(action: showPaperKit) {
                    Image("paper")
                }
                .padding(.leading, 35)

                Button(action: showPencilTool) {
                    Image("custompencil")
                }
                
                Button(action: showImages) {
                    Image("image")
                }
                
                Button(action: showMusics) {
                    Image("music")
                }
                
                Button(action: showStickers) {
                    Image("customstar")
                }
                .padding(.trailing, 35)
            }
        .frame(height: 60)
        .background(Color.white.opacity(0.85)) 
        .clipShape(RoundedRectangle(cornerRadius: 35))
        .shadow(color: .black.opacity(0.1), radius: 8, y: -2)
        
    }
    
}

#Preview {
    TabBarToolKit(showPaperKit: {}, showPencilTool: {}, showImages: {}, showMusics: {}, showStickers: {})
}
