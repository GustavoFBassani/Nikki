//
//  ITunesSearchView.swift
//  POCCanvas
//
//  Created by Alex Fraga on 14/11/25.
//

import SwiftUI

// MARK: - ITunesSearchView
struct ITunesSearchView: View {
    var onSelect: (ITunesTrack) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var viewModel = ITunesSearchViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(viewModel.tracks.prefix(viewModel.searchText.isEmpty ? 4 : viewModel.tracks.count)) { track in
                        TrackCardButton(track: track) {
                            onSelect(track)
                            dismiss()
                        }
                    }
                }
                .padding()
            }
            .preferredColorScheme(.light)
            .navigationTitle("Search Music")
            .searchable(text: $viewModel.searchText, prompt: "Search music")
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image("xCustom")
                            .resizable()
                            .frame(width: 16, height: 16)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Música")
                        .font(Fonts.Title2)
                        .foregroundStyle(.blueNikki)
                }
            }
            .preferredColorScheme(.light)
        }
    }
}

// MARK: - Track Card Button
struct TrackCardButton: View {
    let track: ITunesTrack
    let action: () -> Void
    
    @State private var cover: UIImage?
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                AsyncImage(url: track.artworkURL) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if phase.error != nil {
                        Color.gray.opacity(0.2)
                            .overlay {
                                Image(systemName: "music.note")
                                    .foregroundColor(.gray)
                            }
                    } else {
                        ProgressView()
                    }
                }
                .frame(width: 150, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(track.name)
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    Text(track.artist)
                        .font(.subheadline)
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 4)
            }
            .frame(width: 160)
        }
        .buttonStyle(.plain)
    }
}

