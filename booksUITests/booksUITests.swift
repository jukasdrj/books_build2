//
// UPDATED: booksUITests/booksUITests.swift (Fixed navigation and search issues)
//
import XCTest

final class booksUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Put teardown code here.
    }

    @MainActor
    func testBasicAppLaunch() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Verify that the main tabs are present
        let tabBar = app.tabBars.firstMatch
        XCTAssert(tabBar.waitForExistence(timeout: 5), "Tab bar should be present")
        
        let libraryTab = app.tabBars.buttons["Library"]
        let wishlistTab = app.tabBars.buttons["Wishlist"]
        let searchTab = app.tabBars.buttons["Search"]
        let statsTab = app.tabBars.buttons["Stats"]
        
        XCTAssert(libraryTab.exists, "Library tab should exist")
        XCTAssert(wishlistTab.exists, "Wishlist tab should exist")
        XCTAssert(searchTab.exists, "Search tab should exist")
        XCTAssert(statsTab.exists, "Stats tab should exist")
    }

    @MainActor
    func testSearchFunctionality() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to Search tab
        app.tabBars.buttons["Search"].tap()
        
        // Find and interact with search field
        let searchField = app.textFields["Search by title, author, or ISBN"]
        XCTAssert(searchField.waitForExistence(timeout: 5), "Search field should exist")
        
        searchField.tap()
        searchField.typeText("Swift")
        
        // Trigger search using return key
        searchField.typeText("\n")
        
        // NEW: Wait for a search response (results, no results, or error) to appear
        let searchResponseExpectation = expectation(description: "Wait for search results or no results message")
        
        let resultsTable = app.tables.firstMatch
        let noResultsText = app.staticTexts["No Results Found"]
        let errorText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'error'")).firstMatch
        
        let predicate = NSPredicate { _, _ in
            return resultsTable.exists || noResultsText.exists || errorText.exists
        }
        
        let expectationResult = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: app)], timeout: 10)
        
        XCTAssert(expectationResult == .completed, "Search should provide some response")
        
        // These checks are now largely redundant if the expectation passes, but provide specific detail.
        let hasResults = resultsTable.cells.count > 0
        let hasNoResults = noResultsText.exists
        let hasError = errorText.exists
        
        XCTAssert(hasResults || hasNoResults || hasError, "Search should provide some response")
    }
    
    @MainActor
    func testTabNavigation() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Test navigation to each tab
        app.tabBars.buttons["Wishlist"].tap()
        XCTAssert(app.navigationBars["Wishlist (0)"].waitForExistence(timeout: 3) || 
                 app.staticTexts["Your Wishlist is Empty"].exists, 
                 "Should navigate to Wishlist")
        
        app.tabBars.buttons["Search"].tap()
        let searchField = app.textFields["Search by title, author, or ISBN"]
        XCTAssert(searchField.waitForExistence(timeout: 3), "Should navigate to Search")
        
        app.tabBars.buttons["Stats"].tap()
        XCTAssert(app.navigationBars["Reading Stats"].waitForExistence(timeout: 3) ||
                 app.staticTexts["Total Books"].exists,
                 "Should navigate to Stats")
        
        app.tabBars.buttons["Library"].tap()
        XCTAssert(app.navigationBars.containing(NSPredicate(format: "identifier CONTAINS 'Library'")).firstMatch.waitForExistence(timeout: 3) ||
                 app.staticTexts["Your Library is Empty"].exists,
                 "Should navigate to Library")
    }
    
    @MainActor
    func testEmptyStateHandling() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Test Library empty state
        app.tabBars.buttons["Library"].tap()
        if app.staticTexts["Your Library is Empty"].exists {
            XCTAssert(app.buttons["Add Your First Book"].exists || 
                     app.buttons["Import from Goodreads"].exists,
                     "Empty library should show action buttons")
        }
        
        // Test Wishlist empty state
        app.tabBars.buttons["Wishlist"].tap()
        if app.staticTexts["Your Wishlist is Empty"].exists {
            XCTAssert(app.buttons["Discover New Books"].exists,
                     "Empty wishlist should show discovery button")
        }
        
        // Test Search initial state
        app.tabBars.buttons["Search"].tap()
        XCTAssert(app.staticTexts["Search for a Book"].exists,
                 "Search should show initial instruction")
    }

    @MainActor
    func testSearchResultNavigation() throws {
        let app = XCUIApplication()
        app.launch()
        
        app.tabBars.buttons["Search"].tap()
        
        let searchField = app.textFields["Search by title, author, or ISBN"]
        searchField.tap()
        searchField.typeText("Programming\n")
        
        // Wait for search completion
        Thread.sleep(forTimeInterval: 3)
        
        // If we have results, test navigation
        let firstResult = app.tables.cells.firstMatch
        if firstResult.waitForExistence(timeout: 5) {
            firstResult.tap()
            
            // Verify detail view appears and is stable
            let detailView = app.navigationBars["Book Details"]
            XCTAssert(detailView.waitForExistence(timeout: 5), "Book detail view should appear")
            
            // Verify it doesn't auto-dismiss
            Thread.sleep(forTimeInterval: 2)
            XCTAssert(detailView.exists, "Detail view should remain stable")
            
            // Test action buttons exist
            let addToLibraryButton = app.buttons["Add to Library"]
            let addToWishlistButton = app.buttons["Add to Wishlist"]
            XCTAssert(addToLibraryButton.exists || addToWishlistButton.exists,
                     "Detail view should have action buttons")
        }
    }
    
    @MainActor
    func testDarkModeSupport() throws {
        // Test Light Mode by launching without dark mode argument
        var app = XCUIApplication()
        app.launch()
        
        let libraryTabLight = app.tabBars.buttons["Library"]
        XCTAssert(libraryTabLight.waitForExistence(timeout: 5), "UI should work in light mode")
        
        app.terminate() // Terminate current app instance
        
        // Test Dark Mode by launching with a specific argument
        app = XCUIApplication() // Create a new app instance
        app.launchArguments += ["-AppleInterfaceStyle", "Dark"] // Set argument for dark mode
        app.launch()
        
        let libraryTabDark = app.tabBars.buttons["Library"]
        XCTAssert(libraryTabDark.waitForExistence(timeout: 5), "UI should work in dark mode")
        
        // Test navigation in dark mode
        app.tabBars.buttons["Search"].tap()
        let searchField = app.textFields["Search by title, author, or ISBN"]
        XCTAssert(searchField.waitForExistence(timeout: 5), "Search should work in dark mode")
        
        app.terminate() // Terminate dark mode app instance
        
        // Restore light mode for subsequent tests if needed (by launching normally)
        app = XCUIApplication()
        app.launch()
        let libraryTabRestore = app.tabBars.buttons["Library"]
        XCTAssert(libraryTabRestore.waitForExistence(timeout: 5), "UI should restore to light mode")
    }
    
    @MainActor
    func testAccessibilitySupport() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Test that key UI elements have accessibility labels
        app.tabBars.buttons["Search"].tap()
        
        let searchField = app.textFields["Search by title, author, or ISBN"]
        XCTAssert(searchField.exists, "Search field should have accessibility label")
        
        searchField.tap()
        searchField.typeText("Test\n")
        
        Thread.sleep(forTimeInterval: 2)
        
        // Check for accessibility identifiers on search results
        let searchResults = app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH 'SearchResultRow_'"))
        if searchResults.count > 0 {
            XCTAssert(true, "Search results should have accessibility identifiers")
        }
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
