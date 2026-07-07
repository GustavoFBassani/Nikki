//
//  SplashFlightConfig.swift
//  Nikki
//
//  Created by Alex Fraga on 03/07/26.
//

#if os(visionOS)
import CoreGraphics
import Foundation
import simd

/// Configuração do voo do pássaro que abre a splash screen.

enum SplashFlightConfig {

    // MARK: - Escolha do pássaro / voo (parametrizável)

    /// Modelo usado na intro da splash.
    static let model: FlightModel = .flatBird

    /// Tipo de voo realizado pelo modelo.
    static var flightKind: TsuruFlightKind { .handLanding(model) }

    // MARK: - Portal

    /// Distância do plano/tela à frente dos olhos metros.
    static let screenDistance: Float = 1.4
    /// Altura do centro da tela relativa à linha dos olhos metros.
    static let screenHeightOffset: Float = 0.0
    /// Largura da tela metros. Proporção 16:9 para casar com a janela 1280x720.
    static let screenWidth: Float = 1.0
    /// Altura da tela metros.
    static let screenHeight: Float = 0.5625
    /// Opacidade do plano da tela.
    static let screenOpacity: CGFloat = 0.0

    // MARK: - Coreografia do retorno

    /// Duração do voo de saída do portal até pairar na frente do rosto.
    static let approachDuration: TimeInterval = 3.5
    /// Tempo pairando na frente do rosto antes de voltar para a tela.
    static let hoverSeconds: TimeInterval = 1.5
    /// Duração do voo de volta do hover até a tela.
    static let returnDuration: TimeInterval = 2.5
}
#endif
