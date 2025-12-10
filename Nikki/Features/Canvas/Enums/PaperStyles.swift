//
//  PaperStyles.swift
//  Nikki
//
//  Created by Alex Fraga on 24/11/25.
//

import Foundation

enum PaperStyles: String, CaseIterable {
    case dotted = "dotted"
    case lantern = "lantern"
    case fan = "fan"
    
    var name: String {
        return rawValue
    }
    
    var title: String {
        switch self {
        case .dotted:   return String(localized: "Pontilhado")
        case .lantern:  return String(localized: "Lanternas Orientais")
        case .fan:  return String(localized: "Leques Floridos")
        }
    }
}
