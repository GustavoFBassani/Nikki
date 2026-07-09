//
//  DayPeriod.swift
//  Nikki
//
//  Created by Alex Fraga on 07/07/26.
//

import Foundation

/// Período do dia usado para escolher o cenário (dia vs. noite).
enum DayPeriod: String, CaseIterable {
    case day
    case night

    /// Nome da textura a aplicar no SkyDome.
    var scenarioTextureName: String {
        switch self {
        case .day:      return "dayScenario"
        case .night:    return "nightScenario"
        }
    }

    /// Regra: 6:00–18:59 é dia, o resto é noite.
    static func current(from date: Date = .now) -> DayPeriod {
        let hour = Calendar.current.component(.hour, from: date)
        return (6...18).contains(hour) ? .day : .night
    }
}
