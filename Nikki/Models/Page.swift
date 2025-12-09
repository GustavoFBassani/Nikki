//
//  Page.swift
//  POCCanvas
//
//  Created by Alex Fraga on 18/11/25.
//
import Foundation
import SwiftData
import UIKit

@Model
class Page {
    var id: UUID = UUID()
    var title: String?
    var createdAt: Date?
    var markupData: Data?
    var paperStyle: String?
    var markupImageData: Data?  // Mudado de UIImage? para Data?
    
    init(
        title: String,
        createdAt: Date = Date(),
        markupData: Data? = nil,
        paperStyle: String? = nil,
        markupImageData: Data? = nil  // Mudado o parâmetro
    ) {
        self.title = title
        self.createdAt = createdAt
        self.markupData = markupData
        self.paperStyle = paperStyle
        self.markupImageData = markupImageData
    }
    
    // Helper para converter Data em UIImage quando necessário
    var markupImage: UIImage? {
        guard let data = markupImageData else { return nil }
        return UIImage(data: data)
    }
}
