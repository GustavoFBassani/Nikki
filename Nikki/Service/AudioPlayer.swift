//
//  AudioPlayer.swift
//  POCCanvas
//
//  Created by Alex Fraga on 10/11/25.
//

import SwiftUI
import AVFoundation

@Observable
class AudioPlayer {
    static let shared = AudioPlayer()
    private var player: AVPlayer?
    
    private var environmentPlayer: AVAudioPlayer?

    /// Faixa ambiente aatual para evitar reiniciar a mesma.
    private(set) var currentEnvironmentTrack: String?

    func play(url: URL) {
        player?.pause()
        player = AVPlayer(url: url)
        player?.play()
    }

    /// Toca a trilha ambiente padrão.
    func playEnvironment() {
        playEnvironment(named: "environmentSong")
    }

    /// Toca uma trilha ambiente em loop. Se já for a mesma faixa, mantém, se diferente troca
    func playEnvironment(named trackName: String) {

        guard currentEnvironmentTrack != trackName else { return }

        Task.detached {
            guard let audioAsset = NSDataAsset(name: trackName) else {
                print("Audio file '\(trackName)' not found in Assets")
                return
            }

            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)

                let newPlayer = try AVAudioPlayer(data: audioAsset.data, fileTypeHint: AVFileType.mp3.rawValue)
                newPlayer.numberOfLoops = -1
                newPlayer.volume = 1
                newPlayer.prepareToPlay()

                await MainActor.run {
                    self.environmentPlayer?.stop()
                    self.environmentPlayer = newPlayer
                    self.environmentPlayer?.play()
                    self.currentEnvironmentTrack = trackName
                }
            } catch {
                print("Erro:", error)
            }
        }
    }
    
    func stopEnvironmentPlayer() {
        environmentPlayer?.stop()
        environmentPlayer = nil
        currentEnvironmentTrack = nil
    }

    func stop() {
        player?.pause()
        player = nil
    }
}
