//
//  ShareSheet.swift
//  Nikki
//
//  Created by Alex Fraga on 31/03/26.
//

import SwiftUI

struct ShareSheet: View {
    var onStories: () -> Void
    var onMessages: () -> Void
    var onSaveImage: () -> Void
    var onShareOtherApps: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 18) {
                Text(StringCatalog.share)
                    .font(Fonts.Title2)

                HStack(spacing: 8) {
                    storiesButton
                    messagesButton
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 18)

            Divider()

            VStack(spacing: 8) {
                actionRow(
                    title: "Save image",
                    systemImage: "arrow.down.to.line"
                ) {
                    onSaveImage()
                }

                actionRow(
                    title: "Share with other apps",
                    systemImage: "square.and.arrow.up"
                ) {
                    onShareOtherApps()
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(uiColor: .systemBackground))
        .preferredColorScheme(.light)
    }

    private var storiesButton: some View {
        Button(action: onStories) {
            VStack(spacing: 8) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.99, green: 0.2, blue: 0.33),
                                Color(red: 0.96, green: 0.17, blue: 0.55),
                                Color(red: 0.53, green: 0.29, blue: 0.95)
                            ],
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        )
                    )
                    .frame(width: 74, height: 74)
                    .overlay {
                        Image("insta")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 37, height: 37)
                    }

                Text(StringCatalog.stories)
                    .font(.custom("CaveatBrush-Regular", size: 20))

                    .foregroundStyle(.secondary)
            }
            .frame(width: 120, alignment: .top)
        }
        .buttonStyle(.plain)
    }

    private var messagesButton: some View {
        Button(action: onMessages) {
            VStack(spacing: 8) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 74, height: 74)
                    .overlay {
                        Image(systemName: "message.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white)
                    }

                Text(StringCatalog.messages)
                    .font(.custom("CaveatBrush-Regular", size: 20))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 88)
            }
            .frame(width: 120, alignment: .top)
        }
        .buttonStyle(.plain)
    }

    private func actionRow(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 54, height: 54)
                    .overlay {
                        Image(systemName: systemImage)
                            .font(.system(size: 25, weight: .medium))
                            .foregroundStyle(.primary)
                    }

                Text(title)
                    .font(.custom("CaveatBrush-Regular", size: 22))
                    .foregroundStyle(.primary)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ShareSheet(
        onStories: {},
        onMessages: {},
        onSaveImage: {},
        onShareOtherApps: {}
    )
}
