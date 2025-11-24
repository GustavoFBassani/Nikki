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
    var paperStyle: String?
    
    init(
        title: String,
        createdAt: Date = Date(),
        markupData: Data? = nil,
        paperStyle: String? = nil
    ) {
        self.title = title
        self.createdAt = createdAt
        self.markupData = markupData
        self.paperStyle = paperStyle
    }
}
