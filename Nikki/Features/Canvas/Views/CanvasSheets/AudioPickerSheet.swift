//
//  AudioPickerSheet.swift
//  Nikki
//
//  Created by Gustavo Ferreira bassani on 26/11/25.
//

import SwiftUI

struct AudioPickerSheet: View {
    @State var audioRecorder: AudioRecorder
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(audioRecorder.recordings) { recording in
                    Button(action: {
                        audioRecorder.playRecording(url: recording.url)
                    }) {
                        HStack {
                            Image(systemName: "waveform")
                            Text(String(format: StringCatalog.audioSequence, recording.sequence + 1))
                        }
                    }
                }
            }
            .navigationTitle(StringCatalog.pickAudio)
        }
    }
}


#Preview {
    AudioPickerSheet(audioRecorder: .init())
}
