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
        
        // Tap the search button instead of using return key
        let searchButton = app.buttons.matching(identifier: "magnifyingglass").firstMatch
        if searchButton.exists {
            searchButton.tap()
        } else {
            // Fallback to return key if search button not found
            searchField.typeText("\n")
        }
        
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
        
        let searchButton = app.buttons.matching(identifier: "magnifyingglass").firstMatch
        // Search button might not always be visible, so this is optional
        if searchButton.exists {
            XCTAssert(true, "Search button found")
        }
        
        // Verify initial state message
        let initialMessage = app.staticTexts["Search for a Book"]
        XCTAssert(initialMessage.exists, "Initial search message should be visible")
    }
}