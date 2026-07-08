//
//  WeatherCondition.swift
//  Nikki
//
//  Created by Alex Fraga on 07/07/26.
//

import Foundation
import WeatherKit

/// Clima simplificado ao que o app precisa: define a trilha de áudio ambiente.
enum WeatherCondition: String, CaseIterable {
    case clear
    case rainy

    /// Só os chuvosos trocam a trilha.
    var isRainy: Bool {
        self == .rainy
    }

    /// Trilha ambiente correspondente (tocada em loop).
    var songName: String {
        isRainy ? "rainySong" : "environmentSong"
    }

    /// Mapeia a condition do WeatherKit para os nossos casos.
    init(from wkCondition: WeatherKit.WeatherCondition) {
        switch wkCondition {
        case .rain, .heavyRain, .drizzle, .sunShowers,
             .thunderstorms, .isolatedThunderstorms, .scatteredThunderstorms,
             .strongStorms, .hurricane, .tropicalStorm:
            self = .rainy
        default:
            self = .clear
        }
    }
}
