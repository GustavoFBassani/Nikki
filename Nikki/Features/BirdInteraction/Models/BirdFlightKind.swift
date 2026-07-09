//
//  BirdFlightKind.swift
//  Nikki
//
//  Created by Alex Fraga on 30/06/26.
//

import Foundation

/// Qual modelo 3D faz o voo.
enum FlightModel: Equatable {
    /// Origami tsuru do pacote NikkiProject.
    case tsuru
    /// FlatBird (usdz em Features/BirdInteraction/3DModels), com animação própria de bater asas.
    case flatBird
}

/// Qual variação da animação de voo deve ser disparada.
enum TsuruFlightKind: Equatable {
    /// O pássaro sai do portal, vem até a frente do rosto, paira e some.
    /// Funciona em qualquer lugar (inclusive Simulador).
    case simpleFlight(FlightModel)
    /// O pássaro voa até a mão detectada via hand tracking, pousa e some.
    /// No Simulador (sem mãos) apenas loga e não anima.
    case handLanding(FlightModel)
    /// Intro da splash: o pássaro sai da "tela", vem pra frente do rosto, paira
    /// e VOLTA para a tela. Ao voltar, sinaliza o início da splash.
    case returnToScreen(FlightModel)
}
