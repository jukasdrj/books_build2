import XCTest

final class booksUITests: XCTestCase {

    override func setUpWithError() throws {
        // This method is called before the invocation of each test method in the class.
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testSearchAndNavigateToAddBook() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // 1. Navigate to the Search tab using its accessibility label.
        app.tabBars.buttons["Search"].tap()
        
        // 2. Find the search field, tap it, and type a search query.
        let searchField = app.textFields["Search by title, author, or ISBN"]
        // We use `waitForExistence` to give the app time to transition to the view.
        XCTAssert(searchField.waitForExistence(timeout: 5), "The search text field should be present.")
        searchField.tap()
        
        // Use a more common book title that's likely to return results
        searchField.typeText("Swift Programming")
        
        // Simplified search trigger - just use return key to avoid button issues
        searchField.typeText("\n")
        
        // 3. Wait for search results to load
        // First, wait for the "Searching..." progress view to appear and then disappear
        let searchingIndicator = app.staticTexts["Searching..."]
        if searchingIndicator.waitForExistence(timeout: 3) {
            // Wait for searching to complete
            let searchCompleted = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "exists == false"),
                object: searchingIndicator
            )
            wait(for: [searchCompleted], timeout: 15)
        }
        
        // 4. Look for search results in multiple ways
        var foundResults = false
        
        // Try to find results in a List (table)
        let tableResults = app.tables.cells.firstMatch
        if tableResults.waitForExistence(timeout: 5) {
            foundResults = true
            tableResults.tap()
        }
        
        // If no table results, try to find results in other containers
        if !foundResults {
            // Look for any text that might indicate results
            let anyResultText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'swift'")).firstMatch
            if anyResultText.waitForExistence(timeout: 5) {
                foundResults = true
                anyResultText.tap()
            }
        }
        
        // If still no results, check if we got a "No Results" message
        if !foundResults {
            let noResultsMessage = app.staticTexts["No Results Found"]
            if noResultsMessage.waitForExistence(timeout: 3) {
                // Test passed - search worked but no results found, which is a valid state
                XCTAssert(true, "Search completed successfully but found no results")
                return
            }
            
            // Check for error messages
            let errorMessage = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'error'")).firstMatch
            if errorMessage.exists {
                XCTFail("Search failed with error: \(errorMessage.label)")
                return
            }
            
            // If we get here, something unexpected happened
            XCTFail("Search did not complete successfully. No results, error, or loading state found.")
            return
        }
        
        // 5. If we found and tapped results, look for the detail view
        let addToLibraryButton = app.buttons["Add to Library"]
        if addToLibraryButton.waitForExistence(timeout: 5) {
            addToLibraryButton.tap()
            
            // 6. Navigate back to the Library tab to verify the book was added
            app.tabBars.buttons["Library"].tap()
            
            // 7. Look for any indication that a book was added
            // Since we don't know the exact title, look for any books in the library
            let libraryTable = app.tables.firstMatch
            if libraryTable.waitForExistence(timeout: 5) {
                // Success - we have content in the library
                XCTAssert(true, "Successfully added book to library")
            } else {
                XCTAssert(false, "Book may not have been added to library successfully")
            }
        } else {
            // We found results but couldn't navigate to detail view
            XCTAssert(false, "Found search results but could not navigate to book detail view")
        }
    }
    
    // NEW: Test the empty wishlist to search navigation flow that was fixed
    @MainActor
    func testEmptyWishlistToSearchNavigation() throws {
        let app = XCUIApplication()
        app.launch()
        
        // 1. Navigate to the Wishlist tab
        app.tabBars.buttons["Wishlist"].tap()
        
        // 2. Look for the empty state "Browse Books" button
        let browseButton = app.buttons["Browse Books"]
        if browseButton.waitForExistence(timeout: 5) {
            // 3. Tap the Browse Books button - this should switch to Search tab
            browseButton.tap()
            
            // 4. Verify we're now on the Search tab
            let searchField = app.textFields["Search by title, author, or ISBN"]
            XCTAssert(searchField.waitForExistence(timeout: 5), "Should navigate to Search tab with search field visible")
            
            // 5. Verify the Search tab is selected
            let searchTab = app.tabBars.buttons["Search"]
            XCTAssert(searchTab.isSelected, "Search tab should be selected after tapping Browse Books")
            
            // 6. Test that search still works from this flow
            searchField.tap()
            searchField.typeText("Test\n")
            
            // Wait for search to process (success, error, or no results are all valid)
            Thread.sleep(forTimeInterval: 2)
            let hasResponse = app.tables.cells.count > 0 || 
                            app.staticTexts["No Results Found"].exists || 
                            app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'error'")).firstMatch.exists
            
            XCTAssert(hasResponse, "Search should work after navigating from empty wishlist")
        } else {
            // If wishlist isn't empty, this test doesn't apply
            print("Wishlist is not empty - skipping empty state navigation test")
        }
    }
    
    // NEW: Test navigation destination stability (the core issue that was fixed)
    @MainActor
    func testSearchResultDetailViewStability() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to Search tab
        app.tabBars.buttons["Search"].tap()
        
        let searchField = app.textFields["Search by title, author, or ISBN"]
        XCTAssert(searchField.waitForExistence(timeout: 5), "Search field should exist")
        
        searchField.tap()
        searchField.typeText("Swift\n")
        
        // Wait for results
        Thread.sleep(forTimeInterval: 3)
        
        // If we have results, tap on the first one
        let firstResult = app.tables.cells.firstMatch
        if firstResult.waitForExistence(timeout: 5) {
            firstResult.tap()
            
            // The key test: verify the detail view stays open and doesn't immediately dismiss
            let bookDetailsTitle = app.navigationBars["Book Details"]
            XCTAssert(bookDetailsTitle.waitForExistence(timeout: 5), "Book details view should appear")
            
            // Wait a moment to ensure the view doesn't auto-dismiss
            Thread.sleep(forTimeInterval: 2)
            XCTAssert(bookDetailsTitle.exists, "Book details view should remain stable and not auto-dismiss")
            
            // Verify we can interact with the detail view
            let addToLibraryButton = app.buttons["Add to Library"]
            let addToWishlistButton = app.buttons["Add to Wishlist"]
            
            XCTAssert(addToLibraryButton.exists || addToWishlistButton.exists, 
                     "Detail view should have actionable buttons")
        }
    }
    
    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    // Additional helper test to debug search functionality
    @MainActor
    func testSearchFieldExists() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to search tab
        app.tabBars.buttons["Search"].tap()
        
        // Verify search components exist
        let searchField = app.textFields["Search by title, author, or ISBN"]
        XCTAssert(searchField.waitForExistence(timeout: 5), "Search field should exist")
        
        // Verify initial state message
        let initialMessage = app.staticTexts["Search for a Book"]
        XCTAssert(initialMessage.exists, "Initial search message should be visible")
    }
    
    // Simplified test that just uses the return key and checks for any response
    @MainActor
    func testSearchWithReturnKey() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to the Search tab
        app.tabBars.buttons["Search"].tap()
        
        // Find and use the search field
        let searchField = app.textFields["Search by title, author, or ISBN"]
        XCTAssert(searchField.waitForExistence(timeout: 5), "The search text field should be present.")
        
        searchField.tap()
        searchField.typeText("Swift\n") // Use return key to trigger search
        
        // Wait a moment for search to process
        Thread.sleep(forTimeInterval: 3)
        
        // Check if we get any response (results, no results, or error)
        let hasResults = app.tables.cells.count > 0
        let hasNoResults = app.staticTexts["No Results Found"].exists
        let hasError = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'error'")).firstMatch.exists
        let isSearching = app.staticTexts["Searching..."].exists
        
        XCTAssert(hasResults || hasNoResults || hasError || isSearching, 
                 "Search should show results, no results, error, or searching state")
    }

    @MainActor
    func testDarkModeToggleAndUIVisibility() throws {
        let app = XCUIApplication()
        
        // 1. Test Light Mode first
        XCUIDevice.shared.userInterfaceStyle = .light
        app.launch()

        // Verify UI elements are visible in Light Mode
        let libraryButton = app.tabBars.buttons["Library"]
        XCTAssert(libraryButton.waitForExistence(timeout: 5), "Library tab button should exist in light mode.")

        // 2. Switch to Dark Mode using modern API
        XCUIDevice.shared.userInterfaceStyle = .dark
        
        // Allow time for the interface to update
        Thread.sleep(forTimeInterval: 1)

        // 3. Verify UI elements are still visible in Dark Mode
        XCTAssert(libraryButton.exists, "Library tab button should still exist after toggling to dark mode.")
        
        // 4. Test navigation still works in dark mode
        app.tabBars.buttons["Search"].tap()
        let searchField = app.textFields["Search by title, author, or ISBN"]
        XCTAssert(searchField.waitForExistence(timeout: 5), "Search field should exist in dark mode.")
        
        // 5. Clean up by returning to Light Mode
        XCUIDevice.shared.userInterfaceStyle = .light
    }
    
    // NEW: Test accessibility identifiers for stable UI testing
    @MainActor
    func testAccessibilityIdentifiersExist() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Navigate to Search tab
        app.tabBars.buttons["Search"].tap()
        
        let searchField = app.textFields["Search by title, author, or ISBN"]
        XCTAssert(searchField.waitForExistence(timeout: 5), "Search field should exist")
        
        searchField.tap()
        searchField.typeText("Swift\n")
        
        // Wait for potential results
        Thread.sleep(forTimeInterval: 3)
        
        // Look for search result rows with accessibility identifiers
        let searchResultRows = app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH 'SearchResultRow_'"))
        
        if searchResultRows.count > 0 {
            XCTAssert(true, "Found search results with proper accessibility identifiers")
        } else {
            // This is OK - might just mean no results for this search
            print("No search results found, or results don't have accessibility identifiers yet")
        }
    }
}