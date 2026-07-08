//
//  VisionSplashView+Phase.swift
//  Nikki
//
//  Created by Alex Fraga on 01/07/26.
//

#if os(visionOS)
/// Enum de etapas da animação da Splash Screen
extension VisionSplashView {
    enum Phase: Int, Comparable {
        case idle, flightIntro, windowOpen, mountainUp, sunUp, textIn, fadingOut
        static func < (left: Self, right: Self) -> Bool { left.rawValue < right.rawValue }
    }
}
#endif
