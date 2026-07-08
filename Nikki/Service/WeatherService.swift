//
//  WeatherService.swift
//  Nikki
//
//  Created by Alex Fraga on 07/07/26.
//

import CoreLocation
import WeatherKit

@Observable
class WeatherService {
    static let shared = WeatherService()

    private let weatherKit = WeatherKit.WeatherService.shared
    private let locationService = LocationService.shared

    private(set) var currentCondition: WeatherCondition = .clear

    /// Consulta o clima atual do usuário e atualiza `currentCondition`.
    func refresh() async {
        guard let location = await locationService.currentLocation() else {
            print("Sem localização para consultar o clima")
            return
        }

        do {
            let weather = try await weatherKit.weather(for: location)
            currentCondition = WeatherCondition(from: weather.currentWeather.condition)
        } catch {
            print("Erro ao consultar o clima:", error)
        }
    }
}
