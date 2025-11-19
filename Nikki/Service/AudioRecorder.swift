//
//  AudioRecorder.swift
//  POCCanvas
//
//  Created by Alex Fraga on 14/11/25.
//

import Foundation
import AVFoundation

class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    var recordings: [Recording] = []
    var audioLevels: [CGFloat] = Array(repeating: 20, count: 30)

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var meterTimer: Timer?

    func startRecording() {
        let sequence = (recordings.last?.sequence ?? 0) + 1
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let dateString = formatter.string(from: Date())
        let fileName = "recording_\(sequence)_\(dateString).m4a"

        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: [.defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)

            audioRecorder = try AVAudioRecorder(url: path, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            startMeterTimer()
        } catch {
            print("Failed to start recording: \(error.localizedDescription)")
        }
    }

    func stopRecording() {
        audioRecorder?.stop()
        
        if let recorder = audioRecorder {
            let url = recorder.url
            let sequence = (recordings.last?.sequence ?? 0) + 1
            let recording = Recording(sequence: sequence, url: url)
            recordings.append(recording)
        }

        audioRecorder = nil
        meterTimer?.invalidate()
    }


    func playRecording(url: URL) {
        do {
            let session = AVAudioSession.sharedInstance()
            
            // usa playAndRecord para permitir o defaultToSpeaker
            try session.setCategory(.playAndRecord, options: [.defaultToSpeaker])
            try session.setActive(true)

            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            
        } catch {
            print("Playback error: \(error.localizedDescription)")
        }
    }


    private func startMeterTimer() {
        meterTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.audioRecorder?.updateMeters()
            let avg = self.audioRecorder?.averagePower(forChannel: 0) ?? -160
            let level = max(0, min(1, (avg + 160) / 160))
            DispatchQueue.main.async {
                self.audioLevels.removeFirst()
                self.audioLevels.append(CGFloat(level * 100))
            }
        }
    }
}
