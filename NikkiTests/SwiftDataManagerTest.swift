//
//  SwiftDataManagerTest.swift
//  NikkiTests
//
//  Created by Alex Fraga on 25/11/25.
//

import Testing
@testable import Nikki
import SwiftData
import Foundation

@Suite("Testing SwiftDataManager", .serialized)
struct SwiftDataManagerTest {
    
    @Test
    func settingDataManager() {
        // Given
        resetDatabase()
        let manager: SwiftDataManager
        
        // When
        manager = SwiftDataManager.shared
           
        // Then
        #expect(manager.context.container === manager.container)
    }
    
    
    @Test
    func savingPageSuccessfully(){
        // Given
        resetDatabase()
        let manager = SwiftDataManager.shared
        
        // When
        let page = Page(title: "Page 1",
                        markupData: nil,
                        paperStyle: "recycledPaper")
        try? manager.savePage(page)
        let pages = try? manager.fetchAllPages()
        
        // Then
        if let pages {
            #expect(pages.contains(where: { $0.id == page.id }))
        }
    }
    
    @Test
    func updatingPageSuccessfully(){
        // Given
        resetDatabase()
        let manager = SwiftDataManager.shared
        
        // When
        let page = Page(title: "Page 1",
                        markupData: nil,
                        paperStyle: "recycledPaper")
        try? manager.savePage(page)
        page.title = "Updated Page 1"
        try? manager.updatePage(page)
        let fetchedPage = try? manager.fetchPage(by: page.id)
        
        // Then
        if let fetchedPage {
            #expect(fetchedPage.title == "Updated Page 1")
        }
    }
    
    @Test
    func deletingPageSuccessfully(){
        // Given
        resetDatabase()
        let manager = SwiftDataManager.shared
        
        // When
        let page = Page(title: "Page 1",
                        markupData: nil,
                        paperStyle: "recycledPaper")
        try? manager.savePage(page)
        let fetchedPage = try? manager.fetchAllPages()
        
        try? manager.deletePage(page)
        let refetchedPage = try? manager.fetchAllPages()
        
        
        // Then
        if let fetchedPage, let refetchedPage {
            #expect(fetchedPage.contains(where: { $0.id == page.id }))
            #expect(fetchedPage.count - 1 ==  refetchedPage.count)
        }
    }
    
    @Test
    func fetchingPageSuccesfully(){
        // Given
        resetDatabase()
        let manager = SwiftDataManager.shared
        
        // When
        let page = Page(title: "Page 1",
                        markupData: nil,
                        paperStyle: "recycledPaper")
        
        let fetchedPage = try? manager.fetchPage(by: page.id)
        
        // Then
        if let fetchedPage {
            #expect(fetchedPage.id == page.id)
        }
    }
    
    @Test
    func fetchingNonExistantPageReturnsNil() {
        // Given
        resetDatabase()
        let manager = SwiftDataManager.shared
        
        // When
        let nonExistantPage = try? manager.fetchPage(by: UUID())
        
        // Then
        #expect(nonExistantPage == nil)
    }
    
    // Aux funcs
    func resetDatabase() {
        let manager = SwiftDataManager.shared
        let pages = try? manager.fetchAllPages()
        if let pages {
            for page in pages {
                try? manager.deletePage(page)
            }
        }
    }
}
