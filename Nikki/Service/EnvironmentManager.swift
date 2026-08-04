//
//  EnvironmentManager.swift
//  Nikki
//
//  Created by Alex Fraga on 07/07/26.
//

import Foundation

@MainActor
@Observable
class EnvironmentManager {
    static let shared = EnvironmentManager()

    private(set) var dayPeriod: DayPeriod = .current()
    private(set) var weather: WeatherCondition = .clear

    private var pollingTask: Task<Void, Never>?
    private let pollingInterval: UInt64 = 30 * 60 * 1_000_000_000 // 30 min em nanosecs

    /// A trilha ambiente pertence à cena. Enquanto `false` (splash, onboarding),
    /// qualquer pedido de áudio é ignorado — inclusive o do `scenePhase` no cold
    /// launch e o do polling de clima. A cena libera em `activateEnvironmentAudio()`.
    private(set) var isEnvironmentAudioActive = false

    // MARK: - Período e clima

    /// Reavalia o período do dia a partir da hora atual.
    func refreshDayPeriod() {
        dayPeriod = .current()
    }

    /// Consulta o clima e atualiza o estado. Retorna `true` se o clima mudou.
    @discardableResult
    func refreshWeather() async -> Bool {
        await WeatherService.shared.refresh()
        let newWeather = WeatherService.shared.currentCondition
        guard newWeather != weather else { return false }
        weather = newWeather
        return true
    }

    /// Revalida o clima periodicamente enquanto o app está aberto.
    /// A hora do dia para alterar a textura do cenário só acontece quando o app é aberto (escolha própria no desenvolvimento da task)
    func startWeatherPolling() {
        guard pollingTask == nil else { return }

        pollingTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: self.pollingInterval)
                if Task.isCancelled { return }

                if await self.refreshWeather() {
                    self.updateAudioForWeather()
                }
            }
        }
    }

    func stopWeatherPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }

    // MARK: - Áudio

    /// Libera o áudio ambiente e já toca a trilha do clima atual.
    /// Só deve ser chamado quando a cena estiver montada.
    func activateEnvironmentAudio() {
        isEnvironmentAudioActive = true
        updateAudioForWeather()
    }

    /// Silencia e volta a bloquear o áudio até a cena liberar de novo.
    func deactivateEnvironmentAudio() {
        isEnvironmentAudioActive = false
        AudioPlayer.shared.stopEnvironmentPlayer()
    }

    func updateAudioForWeather() {
        guard isEnvironmentAudioActive else { return }
        AudioPlayer.shared.playEnvironment(named: weather.songName)
    }

    func pauseEnvironmentAudio() {
        AudioPlayer.shared.stopEnvironmentPlayer()
    }

    func resumeEnvironmentAudio() {
        updateAudioForWeather()
    }
}
