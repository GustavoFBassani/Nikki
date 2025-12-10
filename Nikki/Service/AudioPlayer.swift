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

    func play(url: URL) {
        player?.pause()
        player = AVPlayer(url: url)
        player?.play()
    }

    func stop() {
        player?.pause()
        player = nil
    }
}
