//
//  ITunesTrackCardView.swift
//  Nikki
//
//  Created by Rafael Toneto on 25/11/25.
//

import SwiftUI

struct ITunesTrackCardView: View {
    let track: ITunesTrack
    let cover: UIImage?
    
    var body: some View {
        ZStack(alignment: .leading) {
            HStack {
                Spacer()
                
                Image("vinylRecord")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 231, height: 384)
//                    .offset(x: 50)
            }
            
            VStack(spacing: 16) {
                if let cover {
                    Image(uiImage: cover)
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                        .frame(width: 185, height: 185)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                VStack(alignment: .center, spacing: 0) {
                    Text(track.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                        .lineLimit(1)
                        .frame(width: 282, height: 36)
                    
                    Text(track.artist)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.black)
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                        .frame(width: 282, height: 36)
                }
            }
            .padding(.vertical, 54)
            .padding(.horizontal, 51)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.iTunesCardBackground)
            )
        }
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.9).ignoresSafeArea()
        
        ITunesTrackCardView(
            track: ITunesTrack(
                name: "Don't Look Back In Anger",
                artist: "Oasis",
                artworkURL: nil,
                previewURL: URL(string: "https://example.com")!
            ),
            cover: UIImage(named: "coverTeste")
        )
        .frame(width: 615, height: 384) 
        .padding()
    }
}
