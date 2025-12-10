//
//  Recording.swift
//  POCCanvas
//
//  Created by Alex Fraga on 14/11/25.
//
import Foundation

struct Recording: Identifiable {
    let id = UUID()
    let sequence: Int
    let url: URL
}
