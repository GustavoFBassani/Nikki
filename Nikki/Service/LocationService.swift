//
//  LocationService.swift
//  Nikki
//
//  Created by Alex Fraga on 07/07/26.
//

import CoreLocation

@MainActor
@Observable
class LocationService: NSObject, CLLocationManagerDelegate {
    static let shared = LocationService()

    private let manager = CLLocationManager()
    private var locationContinuations: [CheckedContinuation<CLLocation?, Never>] = []
    private var authContinuations: [CheckedContinuation<CLAuthorizationStatus, Never>] = []

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    /// Pede autorização e devolve a localização atual ou `nil`.
    func currentLocation() async -> CLLocation? {
        var status = manager.authorizationStatus

        if status == .notDetermined {
            status = await requestAuthorization()
        }

        #if os(visionOS)
        guard status == .authorizedWhenInUse else { return nil }
        #else
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            return nil
        }
        #endif

        return await withCheckedContinuation { continuation in
            locationContinuations.append(continuation)
            // Junta pedidos concorrentes num único requestLocation().
            if locationContinuations.count == 1 {
                manager.requestLocation()
            }
        }
    }

    /// Mostra o prompt de permissão e aguarda a resposta do usuário.
    private func requestAuthorization() async -> CLAuthorizationStatus {
        await withCheckedContinuation { continuation in
            authContinuations.append(continuation)
            if authContinuations.count == 1 {
                manager.requestWhenInUseAuthorization()
            }
        }
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        // O callback inicial chega antes do usuário responder o prompt.
        guard status != .notDetermined else { return }

        MainActor.assumeIsolated {
            let continuations = authContinuations
            authContinuations.removeAll()
            continuations.forEach { $0.resume(returning: status) }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        MainActor.assumeIsolated {
            resumeLocationContinuations(returning: locations.first)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Erro ao obter localização:", error)
        MainActor.assumeIsolated {
            resumeLocationContinuations(returning: nil)
        }
    }

    private func resumeLocationContinuations(returning location: CLLocation?) {
        let continuations = locationContinuations
        locationContinuations.removeAll()
        continuations.forEach { $0.resume(returning: location) }
    }
}
