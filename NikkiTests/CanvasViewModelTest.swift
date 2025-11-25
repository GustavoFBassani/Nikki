//
//  CanvasViewModelTest.swift
//  NikkiTests
//
//  Created by Alex Fraga on 25/11/25.
//

import Testing
@testable import Nikki
import SwiftData
import Foundation
import SwiftUI

@Suite("Testing CanvasViewModel", .serialized)
struct CanvasViewModelTest {
    
    @Test @MainActor
    func initializingWithoutPage() {
        // Given
        let paperStyle = "recycledPaper"
        
        // When
        let viewModel = CanvasViewModel(page: nil, paperStyle: paperStyle)
        
        // Then
        #expect(viewModel.currentPage == nil)
        #expect(viewModel.paperStyle == paperStyle)
    }
    
    @Test @MainActor
    func initializingWithExistingPage() {
        // Given
        let page = Page(title: "Test Page", markupData: Data(), paperStyle: "redPaper")
        let paperStyle = "recycledPaper"
        
        // When
        let viewModel = CanvasViewModel(page: page, paperStyle: paperStyle)
        
        // Then
        #expect(viewModel.currentPage?.id == page.id)
        #expect(viewModel.currentPage?.title == "Test Page")
        #expect(viewModel.paperStyle == paperStyle)
    }
    
    @Test @MainActor
    func creatingAudioIcon() {
        // Given
        let viewModel = CanvasViewModel(page: nil, paperStyle: nil)
        
        // When
        let icon = viewModel.createAudioIcon()
        
        // Then
        #expect(icon.size.width == 60)
        #expect(icon.size.height == 60)
    }
    
    @Test @MainActor
    func savingNewPage() async {
        // Given
        resetDatabase()
        let viewModel = CanvasViewModel(page: nil, paperStyle: "recycledPaper")
        
        // When
        try? await viewModel.savePage()
        
        // Then
        #expect(viewModel.currentPage != nil)
        if let savedPage = viewModel.currentPage {
            let manager = SwiftDataManager.shared
            let fetchedPage = try? manager.fetchPage(by: savedPage.id)
            #expect(fetchedPage != nil)
            #expect(fetchedPage?.id == savedPage.id)
        }
    }
    
    @Test @MainActor
    func updatingExistingPage() async {
        // Given
        resetDatabase()
        let page = Page(title: "Original Title", markupData: nil, paperStyle: "grid")
        let manager = SwiftDataManager.shared
        try? manager.savePage(page)
        let viewModel = CanvasViewModel(page: page, paperStyle: nil)
        
        // When
        page.title = "Updated Title"
        try? await viewModel.savePage()
        
        // Then
        let fetchedPage = try? manager.fetchPage(by: page.id)
        #expect(fetchedPage?.title == "Updated Title")
    }
    
    @Test @MainActor
    func deletingCurrentPage() {
        // Given
        resetDatabase()
        let page = Page(title: "Page to Delete", markupData: nil, paperStyle: "recycledPaper")
        let manager = SwiftDataManager.shared
        try? manager.savePage(page)
        
        let viewModel = CanvasViewModel(page: page, paperStyle: nil)
        
        // When
        try? viewModel.deleteCurrentPage(using: manager.context)
        
        // Then
        let fetchedPage = try? manager.fetchPage(by: page.id)
        #expect(fetchedPage == nil)
        #expect(viewModel.currentPage == nil)
    }
    
    @Test @MainActor
    func handlingPhotoSelectionWithoutPhoto() async {
        // Given
        let viewModel = CanvasViewModel(page: nil, paperStyle: nil)
        viewModel.photoItem = nil
        
        // When
        await viewModel.handlePhotoSelection()
        
        // Then
        #expect(viewModel.photoItem == nil)
    }
    
    @Test @MainActor
    func showToolsToggling() {
        // Given
        let viewModel = CanvasViewModel(page: nil, paperStyle: nil)
        let initialState = viewModel.showTools
        
        // When
        viewModel.showTools.toggle()
        
        // Then
        #expect(viewModel.showTools == !initialState)
    }
    
    @Test @MainActor
    func stickersArrayContainsExpectedItems() {
        // Given
        let viewModel = CanvasViewModel(page: nil, paperStyle: nil)
        
        // When
        let stickerCount = viewModel.stickers.count
        
        // Then
        #expect(stickerCount > 0)
        #expect(viewModel.stickers.contains("redLetter"))
        #expect(viewModel.stickers.contains("sparkle"))
        #expect(viewModel.stickers.contains("bamboo"))
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

