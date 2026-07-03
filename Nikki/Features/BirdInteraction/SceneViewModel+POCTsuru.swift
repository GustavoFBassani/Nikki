//
//  SceneViewModel+POCTsuru.swift
//  Nikki
//
//  Created by Alex Fraga on 30/06/26.
//

import Foundation

/// Qual modelo 3D faz o voo da POC.
enum FlightModel: Equatable {
    /// Origami tsuru do pacote NikkiProject.
    case tsuru
    /// FlatBird (usdz em Features/3DModels), com animação própria de bater asas.
    case flatBird
}

/// Qual variação da animação da POC deve ser disparada quando o
/// `ImmersiveSpace` "TsuruPOC" aparecer.
enum TsuruFlightKind: Equatable {
    /// O pássaro sai do portal, vem até a frente do rosto, paira e some.
    /// Funciona em qualquer lugar (inclusive Simulador).
    case simpleFlight(FlightModel)
    /// O pássaro voa até a mão detectada via hand tracking, pousa e some.
    /// No Simulador (sem mãos) apenas loga e não anima.
    case handLanding(FlightModel)
}
