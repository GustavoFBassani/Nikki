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
///
/// Tudo que define QUAL pássaro e COMO ele voa antes da splash começar mora
/// aqui, para ficar fácil de trocar durante os testes sem mexer na lógica da
/// view. Hoje o fluxo é fixo (FlatBird + voo simples), mas mantemos os valores
/// parametrizados para experimentar depois.
enum SplashFlightConfig {

    // MARK: - Escolha do pássaro / voo (parametrizável)

    /// Modelo usado na intro da splash.
    static let model: FlightModel = .flatBird

    /// Voo disparado na intro. Por padrão é o "volta pra tela" (o pássaro sai da
    /// tela, paira e retorna, disparando a splash). Trocar aqui para testar
    /// outras variações no futuro (ex.: `.simpleFlight(model)`).
    static var flightKind: TsuruFlightKind { .returnToScreen(model) }

    // MARK: - Portal em modo "tela" (splash)

    /// No fluxo da splash o portal não é o pequeno plano flutuante da POC: ele
    /// representa a própria "tela" de onde o pássaro sai e para onde volta, do
    /// tamanho da janela da splash. Estes valores posicionam/dimensionam esse
    /// plano à frente do usuário.

    /// Distância do plano/tela à frente dos olhos (metros).
    static let screenDistance: Float = 1.4
    /// Altura do centro da tela relativa à linha dos olhos (metros).
    static let screenHeightOffset: Float = 0.0
    /// Largura da tela (metros). Proporção ~16:9 para casar com a janela 1280x720.
    static let screenWidth: Float = 1.0
    /// Altura da tela (metros).
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
