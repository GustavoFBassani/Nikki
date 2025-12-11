//
//  OnboardingPageControl.swift
//  Nikki
//
//  Created by Rafael Toneto on 10/12/25.
//


import SwiftUI

struct OnboardingPageControl: View {
    let totalPages: Int      // number of pages
    let currentPage: Int     // page index

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.blueNikki : Color.gray.opacity(0.4))
                    .frame(
                        width: index == currentPage ? 8 : 8,
                        height: index == currentPage ? 8 : 8
                    )
            }
        }
    }
}
