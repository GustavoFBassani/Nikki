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
    var onClose: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = ITunesSearchViewModel()

    private func close() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }

    var body: some View {
#if os(visionOS)
        visionBody
#else
        iOSBody
#endif
    }

    // MARK: - iOS Body

    private var iOSBody: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: 16
                ) {
                    ForEach(viewModel.tracks.prefix(viewModel.searchText.isEmpty ? 4 : viewModel.tracks.count)) { track in
                        TrackCardButton(track: track) {
                            onSelect(track)
                            close()
                        }
                    }
                }
                .padding()
            }
            .preferredColorScheme(.light)
            .navigationTitle(StringCatalog.searchMusic)
            .searchable(
                text: $viewModel.searchText,
                prompt: StringCatalog.searchMusic
            )
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
                        close()
                    } label: {
                        Image("xCustom")
                            .resizable()
                            .frame(width: 16, height: 16)
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text(StringCatalog.music)
                        .font(Fonts.Title2)
                        .foregroundStyle(.blueNikki)
                }
            }
            .preferredColorScheme(.light)
        }
    }

#if os(visionOS)
    // MARK: - visionOS Body

    private var visionBody: some View {
        VStack(spacing: 0) {
            visionHeader

            Spacer()
                .frame(height: 20)

            visionSearchBar

            Spacer()
                .frame(height: 16)

            visionContent
        }
        .padding(.horizontal, 35)
        .padding(.top, 22)
        .padding(.bottom, 22)
        .frame(width: 408, height: 692, alignment: .top)
        .background {
            RoundedRectangle(cornerRadius: 42, style: .continuous)
                .fill(Color.gray.opacity(0.86))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 42, style: .continuous)
                .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
        }
        .preferredColorScheme(.light)
        .zIndex(0)
    }

    private var visionHeader: some View {
        ZStack {
            HStack {
                Button {
                    close()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background {
                            Circle()
                                .fill(Color.white.opacity(0.18))
                        }
                }
                .buttonStyle(.plain)
                .hoverEffect(.highlight)

                Spacer()
            }

            Text(StringCatalog.music)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(height: 44)
    }

    private var visionSearchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "mic.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)

            TextField("", text: $viewModel.searchText)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .tint(.white)
                .textFieldStyle(.plain)
                .placeholder(
                    when: viewModel.searchText.isEmpty,
                    alignment: .leading
                ) {
                    Text(StringCatalog.searchMusic)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.92))
                }
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.gray.opacity(0.44))
                .shadow(color: .black.opacity(0.14), radius: 5, y: 2)
        }
    }

    private var visionContent: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(
                columns: [
                    GridItem(.fixed(161), spacing: 16),
                    GridItem(.fixed(161), spacing: 16)
                ],
                spacing: 16
            ) {
                if viewModel.isLoading {
                    ForEach(0..<4, id: \.self) { _ in
                        VisionTrackPlaceholderCard()
                    }
                } else {
                    ForEach(viewModel.tracks.prefix(viewModel.searchText.isEmpty ? 4 : viewModel.tracks.count)) { track in
                        VisionTrackCardButton(track: track) {
                            onSelect(track)
                            close()
                        }
                    }
                }
            }
            .frame(width: 338)
            .padding(.bottom, 96)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
            }
        }
    }
#endif
}

// MARK: - Track Card Button - iOS

struct TrackCardButton: View {
    let track: ITunesTrack
    let action: () -> Void

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

#if os(visionOS)
// MARK: - Track Card Button - visionOS

private struct VisionTrackCardButton: View {
    let track: ITunesTrack
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                AsyncImage(url: track.artworkURL) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else if phase.error != nil {
                        VisionCheckerboardPlaceholder()
                            .overlay {
                                Image(systemName: "music.note")
                                    .font(.system(size: 30, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.75))
                            }
                    } else {
                        VisionCheckerboardPlaceholder()
                            .overlay {
                                ProgressView()
                                    .tint(.white)
                            }
                    }
                }
                .frame(width: 161, height: 161)
                .clipped()

                Text(track.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(track.artist)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(1)
            }
            .frame(width: 161, alignment: .leading)
            .scaleEffect(isHovered ? 1.04 : 1.0)
            .animation(.easeInOut(duration: 0.16), value: isHovered)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .hoverEffect(.highlight)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Placeholder Card - visionOS

private struct VisionTrackPlaceholderCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VisionCheckerboardPlaceholder()
                .frame(width: 161, height: 161)

            Text("Title")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)

            Text("Artist")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white.opacity(0.92))
        }
        .frame(width: 161, alignment: .leading)
    }
}

// MARK: - Checkerboard Placeholder - visionOS

private struct VisionCheckerboardPlaceholder: View {
    var body: some View {
        Canvas { context, size in
            let squareSize: CGFloat = 12

            for row in 0..<Int(size.height / squareSize + 1) {
                for column in 0..<Int(size.width / squareSize + 1) {
                    let isLight = (row + column).isMultiple(of: 2)

                    let rect = CGRect(
                        x: CGFloat(column) * squareSize,
                        y: CGFloat(row) * squareSize,
                        width: squareSize,
                        height: squareSize
                    )

                    context.fill(
                        Path(rect),
                        with: .color(
                            isLight
                                ? .white.opacity(0.82)
                                : .white.opacity(0.56)
                        )
                    )
                }
            }
        }
        .background(Color.white.opacity(0.35))
    }
}
#endif

// MARK: - Placeholder Helper

private extension View {
    @ViewBuilder
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder()
                .opacity(shouldShow ? 1 : 0)

            self
        }
    }
}
