//
//  Page.swift
//  POCCanvas
//
//  Created by Alex Fraga on 18/11/25.
//
import Foundation
import SwiftData

@Model
class Page {
    var id: UUID = UUID()
    var title: String?
    var createdAt: Date?
    var markupData: Data?
    var backgroundImageName: String?
    
    init(
        title: String,
        createdAt: Date = Date(),
        markupData: Data? = nil,
        backgroundImageName: String? = nil
    ) {
        self.title = title
        self.createdAt = createdAt
        self.markupData = markupData
        self.backgroundImageName = backgroundImageName
    }
}
