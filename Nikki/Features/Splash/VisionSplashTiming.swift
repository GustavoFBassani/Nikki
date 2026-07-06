//
//  VisionSplashTiming.swift
//  Nikki
//
//  Created by Alex Fraga on 30/06/26.
//

import Foundation

/// Tempos em segundos de cada etapa da animação da splash screen no visionOS
enum VisionSplashTiming {
    static let windowOpen: Double = 3.0  // abertura lateral da janela
    static let initialDelay: Double = 0.4 // espera antes da montanha subir
    static let mountainRise: Double = 1.5 // subida da montanha
    static let sunRise: Double = 1      // subida do sol
    static let textFadeIn: Double = 0.5   // fade in do texto "Nikki"
    static let hold: Double = 3.0         // tempo parado antes de sumir e trocar de tela
    static let fadeOut: Double = 0.8      // fade out final
}
