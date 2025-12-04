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
            List(viewModel.tracks) { track in
                trackRow(track)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelect(track)
                        dismiss()
                    }
            }
            .navigationTitle("Search iTunes")
            .searchable(text: $viewModel.searchText, prompt: "Search music")
            .onSubmit(of: .search) {
                viewModel.performSearch()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                }
            }
            .overlay {
                if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Text("Erro")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - Track Row
    @ViewBuilder
    private func trackRow(_ track: ITunesTrack) -> some View {
        HStack(spacing: 12) {
            AsyncImage(url: track.artworkURL) { phase in
                if let img = phase.image {
                    img.resizable().aspectRatio(contentMode: .fill)
                } else {
                    Color.gray.opacity(0.2)
                }
            }
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading) {
                Text(track.name)
                    .font(.headline)
                Text(track.artist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}
