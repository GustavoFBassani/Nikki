//
//  View+Snapshot.swift
//  Nikki
//
//  Created by Rafael Toneto on 25/11/25.
//

import SwiftUI

extension View {
    func asImage(size: CGSize) -> UIImage {
        let rootView = self
            .frame(width: size.width, height: size.height)
            .ignoresSafeArea()
        
        let controller = UIHostingController(rootView: rootView)
        controller.view.bounds = CGRect(origin: .zero, size: size)
        controller.view.backgroundColor = .clear
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}
