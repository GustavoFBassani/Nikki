//
//  ITunesResponse.swift
//  POCCanvas
//
//  Created by Alex Fraga on 14/11/25.
//
import Foundation

struct ITunesResponse: Decodable {
    let results: [ITunesTrackDTO]
}

struct ITunesTrackDTO: Decodable, Identifiable {
    let id = UUID()
    let trackName: String
    let artistName: String
    let artworkUrl100: String?
    let previewUrl: String?

    private enum CodingKeys: String, CodingKey {
        case trackName
        case artistName
        case artworkUrl100
        case previewUrl
    }
}
