//
//  NikkiUITests.swift
//  NikkiUITests
//
//  Created by Rafael Toneto on 05/12/25.
//

import XCTest

final class NikkiUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }
    
    func testOpenCanvasFromScene() throws {
        // 1. Opens the app
        let app = XCUIApplication()
        app.launch()
        
        // Awaits the navBar load
        let navBar = app.navigationBars.firstMatch
        XCTAssertTrue(navBar.waitForExistence(timeout: 8), "Navigation bar did not appear")

        // 2. Taps new page button (filtering by identifier AND label)
        let newPageMenuButton = navBar.buttons
            .matching(identifier: "scene_new_page_menu")
            .matching(NSPredicate(format: "label == %@", "Nova página"))
            .firstMatch
        
        XCTAssertTrue(newPageMenuButton.waitForExistence(timeout: 5),
                      "Button 'New Page' didn't appear")
        newPageMenuButton.tap()

        // 3. Picks a paper style
        // Use an existing item from PaperStyles.name
        let styleButton = app.buttons["recycledPaper"]
        XCTAssertTrue(styleButton.waitForExistence(timeout: 5),
                      "Button style 'recycledPaper' didn't appear in menu")
        styleButton.tap()

        // 4. Check if the Canvas opened
        // Checks the 'Save' button existence
        let saveButton = app.buttons["canvas_save_button"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5),
                      "Save Canvas button didn't appear – Canvas counldn't be opened")
    }
    
    func testOpenAndSaveCanvasHidesAndShowsSceneToolbar() throws {
        let app = XCUIApplication()
        app.launch()

        let navBar = app.navigationBars.firstMatch
        XCTAssertTrue(navBar.waitForExistence(timeout: 10))

        // Scene "New Page" button (identifier + label to avoid ambiguity)
        let newPageMenuButton = navBar.buttons
            .matching(identifier: "scene_new_page_menu")
            .matching(NSPredicate(format: "label == %@", "Nova página"))
            .firstMatch
        
        XCTAssertTrue(newPageMenuButton.waitForExistence(timeout: 10))

        // Opens Canvas
        newPageMenuButton.tap()
        XCTAssertTrue(app.buttons["recycledPaper"].waitForExistence(timeout: 10))
        app.buttons["recycledPaper"].tap()

        // Waits for the Canvas save button
        let saveButton = app.buttons["canvas_save_button"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 12))

        // While Canvas is open, the Scene toolbar should be hidden
        // NOTE: Using negation check with delay — UI needs time to hide toolbar
        XCTAssertFalse(newPageMenuButton.exists,
                       "Scene toolbar should be hidden with open Canvas")

        // Saves the Canvas
        saveButton.tap()

        // After saving, Canvas closes and Scene toolbar should reappear
        XCTAssertTrue(newPageMenuButton.waitForExistence(timeout: 12),
                      "Scene Toolbar didn't come back after closing the Canvas")
    }
    
    /// Opens the Canvas, saves a page and then opens the Canvas again
    /// to ensure the main journaling flow can be repeated without issues.
    func testSaveAndReopenCanvas() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for Scene navigation bar
        let navBar = app.navigationBars.firstMatch
        XCTAssertTrue(navBar.waitForExistence(timeout: 10),
                      "Navigation bar did not appear")
        
        // Scene "New Page" button (identifier + label)
        let newPageMenuButton = navBar.buttons
            .matching(identifier: "scene_new_page_menu")
            .matching(NSPredicate(format: "label == %@", "Nova página"))
            .firstMatch
        
        XCTAssertTrue(newPageMenuButton.waitForExistence(timeout: 10),
                      "Scene 'New Page' menu button did not appear")
        
        // First open: open Canvas and save
        
        newPageMenuButton.tap()
        
        let styleButtonFirst = app.buttons["recycledPaper"]
        XCTAssertTrue(styleButtonFirst.waitForExistence(timeout: 10),
                      "Paper style 'recycledPaper' did not appear in menu")
        styleButtonFirst.tap()
        
        let saveButtonFirst = app.buttons["canvas_save_button"]
        XCTAssertTrue(saveButtonFirst.waitForExistence(timeout: 12),
                      "Save Canvas button did not appear on first open")
        
        // Save the first page
        saveButtonFirst.tap()
        
        // Wait for Scene toolbar to come back
        XCTAssertTrue(newPageMenuButton.waitForExistence(timeout: 12),
                      "Scene toolbar did not reappear after saving the first page")
        
        // --- Second open: open Canvas again (reopen flow) ---
        
        newPageMenuButton.tap()
        
        let styleButtonSecond = app.buttons["recycledPaper"]
        XCTAssertTrue(styleButtonSecond.waitForExistence(timeout: 10),
                      "Paper style 'recycledPaper' did not appear in menu on second open")
        styleButtonSecond.tap()
        
        let saveButtonSecond = app.buttons["canvas_save_button"]
        XCTAssertTrue(saveButtonSecond.waitForExistence(timeout: 12),
                      "Canvas did not open again after saving a page")
        
        // - The user can open a Canvas
        // - Save a page
        // - Return to the Scene
        // - And open the Canvas again through the same main flow
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
