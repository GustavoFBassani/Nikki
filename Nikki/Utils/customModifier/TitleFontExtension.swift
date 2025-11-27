//
//  TitleFontExtension.swift
//  Nikki
//
//  Created by Gustavo Ferreira bassani on 26/11/25.
//

import SwiftUI

extension View {
    func navigationTitleFont(_ font: UIFont, color: UIColor = .label) -> some View {
        self.onAppear {
            let appearance = UINavigationBarAppearance()
            appearance.titleTextAttributes = [.font: font, .foregroundColor: color]
            appearance.largeTitleTextAttributes = [.font: font, .foregroundColor: color]
            
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
