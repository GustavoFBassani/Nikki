//
//  PaperStyles.swift
//  Nikki
//
//  Created by Alex Fraga on 24/11/25.
//

import Foundation

enum PaperStyles: String, CaseIterable {
    case recycled = "recycledPaper"
    case white = "whitePaper"
    case red = "redPaper"
    case secret = "secret"
    
    var name: String {
        return rawValue
    }
    
    var title: String {
        switch self {
        case .recycled: return String(localized: "Papel reciclado")
        case .white:    return String(localized: "Papel branco")
        case .red:      return String(localized: "Papel vermelho")
        case .secret:   return String(localized: "Papel secreto")
        }
    }
}
