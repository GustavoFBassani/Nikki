//
//  StringCatalog+Bonsai.swift
//  Nikki
//
//  Created by Anthony Antonelli Andrade on 03/07/26.
//

import Foundation

extension StringCatalog {

    // Bonsai / painel de controle
    static let bonsaiTitle = String(localized: "bonsai.panel.title")
    static let bonsaiSubtitle = String(localized: "bonsai.panel.subtitle")
    static let bonsaiPlaced = String(localized: "bonsai.panel.placed")
    static let bonsaiInstructionLook = String(localized: "bonsai.panel.instruction.look")
    static let bonsaiInstructionTap = String(localized: "bonsai.panel.instruction.tap")
    static let bonsaiInstructionDrag = String(localized: "bonsai.panel.instruction.drag")

    // Bonsai / botão do espaço imersivo
    static let bonsaiOpenPlacement = String(localized: "bonsai.toggle.open")
    static let bonsaiClosePlacement = String(localized: "bonsai.toggle.close")
    static let bonsaiWait = String(localized: "bonsai.toggle.wait")

    // Bonsai / status dentro do espaço imersivo
    static let bonsaiTargetBonsai = String(localized: "bonsai.target.bonsai")
    static let bonsaiTargetScene = String(localized: "bonsai.target.scene")
    static let bonsaiSearchingSurface = String(localized: "bonsai.status.searching")
    static let bonsaiSearchingHint = String(localized: "bonsai.status.searchHint")

    static func bonsaiLoading(_ targetName: String) -> String {
        String(format: String(localized: "bonsai.status.loading"), targetName)
    }

    static func bonsaiTapToPlace(_ targetName: String) -> String {
        String(format: String(localized: "bonsai.status.tapToPlace"), targetName)
    }

    // Bonsai / erros
    static let bonsaiModelLoadError = String(localized: "bonsai.error.model")
    static let bonsaiTrackingError = String(localized: "bonsai.error.tracking")
}
