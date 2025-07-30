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
        app.tabBars["Tab Bar"].buttons["Search"].tap()
        
        // 2. Find the search field, tap it, and type a search query.
        let searchField = app.textFields["Search by title, author, or ISBN"]
        // We use `waitForExistence` to give the app time to transition to the view.
        XCTAssert(searchField.waitForExistence(timeout: 5), "The search text field should be present.")
        searchField.tap()
        searchField.typeText("Dune\n") // The \n character simulates pressing the 'return' key.
        
        // 3. IMPORTANT FIX: A SwiftUI List is represented as a `table` in UI tests.
        // We wait for the first cell within any table to exist.
        let firstResultCell = app.tables.cells.firstMatch
        XCTAssert(firstResultCell.waitForExistence(timeout: 10), "Search results should appear in the list.")
        
        // 4. Tap the first result cell to trigger the NavigationLink.
        firstResultCell.tap()
        
        // 5. In the detail view, verify the "Add to Library" button exists and tap it.
        let addToLibraryButton = app.buttons["Add to Library"]
        XCTAssert(addToLibraryButton.waitForExistence(timeout: 5), "The 'Add to Library' button should be on the detail screen.")
        addToLibraryButton.tap()
        
        // 6. Navigate back to the Library tab.
        app.tabBars["Tab Bar"].buttons["Library"].tap()
        
        // 7. Verify that the book now appears in the library's table.
        // We search for any text within the table that contains "Dune".
        let newBookInLibrary = app.tables.staticTexts["Dune"]
        XCTAssert(newBookInLibrary.waitForExistence(timeout: 5), "The newly added book should be visible in the library.")
    }
    
    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
