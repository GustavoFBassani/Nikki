//
//  Motivation.swift
//  Nikki
//
//  Created by Rafael Toneto on 03/12/25.
//

import Foundation
import SwiftData

@Model
class Motivation {
    var text: String?
    var updatedAt: Date?

    init(text: String, updatedAt: Date) {
        self.text = text
        self.updatedAt = updatedAt
    }
}
