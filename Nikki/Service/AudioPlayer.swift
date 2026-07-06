//
//  AudioPlayer.swift
//  POCCanvas
//
//  Created by Alex Fraga on 10/11/25.
//

import SwiftUI
import AVFoundation

// MARK: - Player de áudio simples
@Observable
class AudioPlayer {
    static let shared = AudioPlayer()
    private var player: AVPlayer?
    
    private var environmentPlayer: AVAudioPlayer?

    func play(url: URL) {
        player?.pause()
        player = AVPlayer(url: url)
        player?.play()
    }
    
    func playEnvironment() {
        
        guard environmentPlayer == nil else { return }

        print("antes do data asset")

        Task.detached {
            guard let audioAsset = NSDataAsset(name: "environmentSong") else {
                print("Audio file 'environmentSong' not found in Assets")
                return
            }

            print("depois do data asset")
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
                
                let newPlayer = try AVAudioPlayer(data: audioAsset.data, fileTypeHint: AVFileType.mp3.rawValue)
                newPlayer.numberOfLoops = -1
                newPlayer.volume = 1
                newPlayer.prepareToPlay()
                
                await MainActor.run {
                    self.environmentPlayer = newPlayer
                    self.environmentPlayer?.play()
                    print("Tocando com sucesso!")
                }
            } catch {
                print("Erro:", error)
            }
        }
    }
    
    func stopEnvironmentPlayer() {
        environmentPlayer?.stop()
        environmentPlayer = nil
    }

    func stop() {
        player?.pause()
        player = nil
    }
}
