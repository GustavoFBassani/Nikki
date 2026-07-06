//
//  BirdFlightConfig.swift
//  Nikki
//
//  Created by Alex Fraga on 30/06/26.
//

#if os(visionOS)
import Foundation
import simd

/// Constantes de geometria do voo (distâncias, alturas, escalas) e as
/// correções de orientação por modelo. Centraliza os "números mágicos" que
/// antes ficavam espalhados na view.
enum BirdFlightConfig {

    // MARK: - Distâncias e alturas (em metros), relativas aos olhos.

    /// Portal à frente da cabeça.
    static let portalDistance: Float = 2
    /// Portal um pouco acima da linha dos olhos.
    static let portalHeightOffset: Float = 0.35
    /// Ponto onde o pássaro paira.
    static let hoverDistance: Float = 0.9
    /// Praticamente na linha dos olhos.
    static let hoverHeightOffset: Float = -0.05
    // Tempo em segundos que o modelo fica pousado na palma da mão.
    static let handLandingSeconds: TimeInterval = 7

    // MARK: - Escalas por modelo.

    static let tsuruScale: Float = 0.5
    static let flatBirdScale: Float = 0.0005

    /// Escala aplicada a cada modelo.
    static func scale(for model: FlightModel) -> Float {
        switch model {
        case .tsuru:    return tsuruScale
        case .flatBird: return flatBirdScale
        }
    }

    // MARK: - Ajuste de pouso na mão.

    /// Offset vertical em metros aplicado ao pousar
    ///
    /// - `flatBird`: a origem do modelo fica no centro vertical, então subimos
    ///   metade da altura já escalada
    /// - `tsuru`: quase certo, só um pouco pra cima.
    static func landingHeightOffset(for model: FlightModel, scaledHeight: Float) -> Float {
        switch model {
        case .flatBird: return scaledHeight / 2
        case .tsuru:    return 0.02
        }
    }

    // MARK: - Correção de orientação por modelo.

    /// Correção do eixo "frente" de cada modelo, para o bico apontar na
    /// direção do voo (o "frente" do RealityKit é -Z).
    ///
    /// Se um modelo voar de costas ou de lado, ajuste o ângulo dele
    /// (0, .pi, .pi/2, -.pi/2).
    static func forwardFix(for model: FlightModel) -> simd_quatf {
        switch model {
        case .tsuru:
            return simd_quatf(angle: -.pi / 2, axis: [0, 1, 0])
        case .flatBird:
            return simd_quatf(angle: .pi / 2, axis: [0, 1, 0])
        }
    }
}
#endif
