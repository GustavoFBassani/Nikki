//
//  AudioPlayer.swift
//  POCCanvas
//
//  Created by Alex Fraga on 23/06/26.
//

import AVFoundation
import CoreLocation
import WeatherKit
import UIKit

// MARK: - AmbientTrack

enum AmbientTrack: String {
    case nature = "natureSound"
    case rain   = "rain"

    static func from(_ condition: WeatherCondition) -> AmbientTrack {
        switch condition {
        case .clear, .mostlyClear, .partlyCloudy:
            return .nature
        default:
            return .rain
        }
    }
}

// MARK: - WeatherAudioManager

@Observable
class WeatherAudioManager: NSObject {
    static let shared = WeatherAudioManager()

    private(set) var currentTrack: AmbientTrack = .nature
    private(set) var isPlaying: Bool = false

    // MOCK
    // .rain   
    // .nature 
    // nil     usa clima real do WeatherKit
    var mockTrack: AmbientTrack? = .rain

    private var activePlayer: AVAudioPlayer?
    private var fadingOutPlayer: AVAudioPlayer?
    private let ambientVolume: Float = 0.35

    private let locationManager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var refreshTask: Task<Void, Never>?
    private let refreshInterval: TimeInterval = 15 * 60 // 15 min 

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSignificantTimeChange),
            name: UIApplication.significantTimeChangeNotification,
            object: nil
        )
    }

    @objc private func handleSignificantTimeChange() {
        guard let location = lastLocation else { return }
        beginRefreshLoop(for: location)
    }

    // MARK: - Public Interface

    func start() {
        configureAudioSession()

        if let mock = mockTrack {
            if !isPlaying || mock != currentTrack { crossfade(to: mock) }
            return
        }

        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if let location = lastLocation {
                beginRefreshLoop(for: location)
            } else {
                locationManager.requestLocation()
            }
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            if !isPlaying { crossfade(to: .nature) }
        @unknown default:
            break
        }
    }

    func stop() {
        refreshTask?.cancel()
        refreshTask = nil
        fadeOutAndStop(player: activePlayer)
        activePlayer = nil
        isPlaying = false
    }

    // MARK: - Audio Session

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("WeatherAudioManager: audio session error — \(error)")
        }
    }

    // MARK: - Refresh Loop

    private func beginRefreshLoop(for location: CLLocation) {
        refreshTask?.cancel()
        refreshTask = Task {
            while !Task.isCancelled {
                await fetchAndUpdate(location: location)
                try? await Task.sleep(for: .seconds(refreshInterval))
            }
        }
    }

    @MainActor
    private func fetchAndUpdate(location: CLLocation) async {
        if let mock = mockTrack {
            if mock != currentTrack || !isPlaying { crossfade(to: mock) }
            return
        }

        do {
            let weather = try await WeatherService.shared.weather(for: location)
            let newTrack = AmbientTrack.from(weather.currentWeather.condition)
            if newTrack != currentTrack || !isPlaying {
                crossfade(to: newTrack)
            }
        } catch {
            if !isPlaying { crossfade(to: .nature) }
            print("WeatherAudioManager: weather fetch error — \(error)")
        }
    }

    // MARK: - Audio Playback

    private func crossfade(to track: AmbientTrack) {
        guard let url = Bundle.main.url(forResource: track.rawValue, withExtension: "mp3") else {
            print("WeatherAudioManager: arquivo de áudio não encontrado — '\(track.rawValue).mp3'")
            currentTrack = track
            return
        }

        if let current = activePlayer, current.isPlaying {
            fadingOutPlayer = current
            fadeOutAndStop(player: current)
        }

        do {
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.numberOfLoops = -1
            newPlayer.volume = 0
            newPlayer.prepareToPlay()
            newPlayer.play()
            activePlayer = newPlayer
            currentTrack = track
            isPlaying = true
            fadeIn(player: newPlayer, to: ambientVolume)
        } catch {
            print("WeatherAudioManager: erro ao criar player para \(track.rawValue) — \(error)")
        }
    }

    private func fadeIn(player: AVAudioPlayer, to target: Float, duration: TimeInterval = 2.0) {
        let steps = 20
        let stepInterval = duration / Double(steps)
        let stepSize = target / Float(steps)
        var step = 0
        Timer.scheduledTimer(withTimeInterval: stepInterval, repeats: true) { [weak player, weak self] timer in
            guard let player, let self, player === self.activePlayer else {
                timer.invalidate()
                return
            }
            step += 1
            player.volume = min(target, stepSize * Float(step))
            if step >= steps { timer.invalidate() }
        }
    }

    private func fadeOutAndStop(player: AVAudioPlayer?, duration: TimeInterval = 2.0) {
        guard let player else { return }
        let startVolume = player.volume
        let steps = 20
        let stepInterval = duration / Double(steps)
        let stepSize = startVolume / Float(steps)
        var step = 0
        Timer.scheduledTimer(withTimeInterval: stepInterval, repeats: true) { timer in
            step += 1
            player.volume = max(0, startVolume - stepSize * Float(step))
            if step >= steps {
                player.stop()
                timer.invalidate()
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension WeatherAudioManager: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
        beginRefreshLoop(for: location)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            Task { @MainActor in
                if !isPlaying { crossfade(to: .nature) }
            }
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("WeatherAudioManager: location error — \(error)")
        Task { @MainActor in
            if !isPlaying { crossfade(to: .nature) }
        }
    }
}
