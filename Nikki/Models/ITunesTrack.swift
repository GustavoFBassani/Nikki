//
//  ITunesTrack.swift
//  POCCanvas
//
//  Created by Alex Fraga on 10/11/25.
//

import SwiftUI

// MARK: - Modelo de música iTunes
struct ITunesTrack: Identifiable, Hashable {
    var id = UUID()
    let name: String
    let artist: String
    let artworkURL: URL?
    let previewURL: URL
}
