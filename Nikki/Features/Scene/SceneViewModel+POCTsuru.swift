//
//  SceneViewModel+POCTsuru.swift
//  Nikki
//
//  Created by Alex Fraga on 30/06/26.
//

import Foundation

/// Qual variação da animação da POC deve ser disparada quando o
/// `ImmersiveSpace` "TsuruPOC" aparecer.
enum TsuruFlightKind: Equatable {
    /// O tsuru sai do portal, vem até a frente do rosto, paira e some.
    /// Funciona em qualquer lugar (inclusive Simulador).
    case simpleFlight
    /// O tsuru voa até a mão detectada via hand tracking, pousa e some.
    /// No Simulador (sem mãos) apenas loga e não anima.
    case handLanding
}
