//
//  SceneViewModel+POCTsuru.swift
//  Nikki
//
//  POC: tsuru atravessando um portal e (opcionalmente) pousando na mão.
//  Mantido separado do código de produção para facilitar o debug e a remoção.
//  O estado observável (`pocFlightRequest`) fica no próprio SceneViewModel para
//  ser observado pela TsuruPortalView; aqui só vive o enum da POC.
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
