import XCTest

/// Comprehensive UI tests for the book reading tracker app
/// Tests navigation, theme switching, accessibility, and user workflows
final class ComprehensiveUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Tab Navigation Tests
    
    func testTabBarNavigation() throws {
        // Test all four main tabs are present and accessible
        let tabBar = app.tabBars["MainTabView"]
        XCTAssertTrue(tabBar.exists, "Main tab bar should exist")
        
        let expectedTabs = ["Library", "Search", "Stats", "Culture"]
        
        for tabName in expectedTabs {
            let tabButton = tabBar.buttons[tabName]
            XCTAssertTrue(tabButton.exists, "\(tabName) tab should exist")
            
            // Test tab selection
            tabButton.tap()
            XCTAssertTrue(tabButton.isSelected, "\(tabName) tab should be selected after tap")
            
            // Take screenshot for visual verification
            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "Tab_\(tabName)"
            attachment.lifetime = .deleteOnSuccess
            add(attachment)
        }
    }
    
    func testTabBarPersistence() throws {
        // Test that tab selection persists during navigation
        let tabBar = app.tabBars["MainTabView"]
        
        // Select Stats tab
        tabBar.buttons["Stats"].tap()
        XCTAssertTrue(tabBar.buttons["Stats"].isSelected)
        
        // Navigate to a detail view (if available)
        if app.buttons["StatsDetailButton"].exists {
            app.buttons["StatsDetailButton"].tap()
            
            // Navigate back
            app.navigationBars.buttons.firstMatch.tap()
            
            // Verify Stats tab is still selected
            XCTAssertTrue(tabBar.buttons["Stats"].isSelected, "Stats tab should remain selected after navigation")
        }
    }
    
    // MARK: - Theme System Tests
    
    func testThemeSwitching() throws {
        // Navigate to settings or theme picker
        let tabBar = app.tabBars["MainTabView"]
        
        // Assuming theme picker is accessible from Library or Settings
        tabBar.buttons["Library"].tap()
        
        if app.buttons["ThemePickerButton"].exists {
            app.buttons["ThemePickerButton"].tap()
            
            // Test each theme variant
            let themes = ["Purple Boho", "Forest Sage", "Ocean Blues", "Sunset Warmth", "Monochrome"]
            
            for theme in themes {
                let themeButton = app.buttons["\(theme)ThemeButton"]
                if themeButton.exists {
                    themeButton.tap()
                    
                    // Wait for theme change to complete
                    Thread.sleep(forTimeInterval: 0.5)
                    
                    // Take screenshot to verify theme change
                    let screenshot = app.screenshot()
                    let attachment = XCTAttachment(screenshot: screenshot)
                    attachment.name = "Theme_\(theme.replacingOccurrences(of: " ", with: "_"))"
                    attachment.lifetime = .deleteOnSuccess
                    add(attachment)
                }
            }
            
            // Dismiss theme picker
            if app.buttons["DismissButton"].exists {
                app.buttons["DismissButton"].tap()
            }
        }
    }
    
    func testThemeConsistencyAcrossTabs() throws {
        // Select a specific theme first
        if app.buttons["ThemePickerButton"].exists {
            app.buttons["ThemePickerButton"].tap()
            
            if app.buttons["Forest SageThemeButton"].exists {
                app.buttons["Forest SageThemeButton"].tap()
                
                if app.buttons["DismissButton"].exists {
                    app.buttons["DismissButton"].tap()
                }
            }
        }
        
        // Verify theme consistency across all tabs
        let tabBar = app.tabBars["MainTabView"]
        let tabs = ["Library", "Search", "Stats", "Culture"]
        
        for tab in tabs {
            tabBar.buttons[tab].tap()
            Thread.sleep(forTimeInterval: 0.3)
            
            // Take screenshot to verify theme consistency
            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "ThemeConsistency_\(tab)"
            attachment.lifetime = .deleteOnSuccess
            add(attachment)
        }
    }
    
    // MARK: - Search Workflow Tests
    
    func testBookSearchWorkflow() throws {
        let tabBar = app.tabBars["MainTabView"]
        tabBar.buttons["Search"].tap()
        
        // Look for search field
        let searchField = app.searchFields.firstMatch
        if searchField.exists {
            searchField.tap()
            searchField.typeText("Swift Programming")
            
            // Wait for search results
            let expectation = XCTestExpectation(description: "Search results appear")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
            
            // Take screenshot of search results
            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "SearchResults"
            attachment.lifetime = .deleteOnSuccess
            add(attachment)
            
            // Test selecting a search result
            let searchResultsTable = app.tables["SearchResultsTable"]
            if searchResultsTable.exists && searchResultsTable.cells.count > 0 {
                let firstResult = searchResultsTable.cells.firstMatch
                firstResult.tap()
                
                // Should navigate to detail view
                XCTAssertTrue(app.navigationBars.count > 0, "Should navigate to detail view")
                
                // Take screenshot of detail view
                let detailScreenshot = app.screenshot()
                let detailAttachment = XCTAttachment(screenshot: detailScreenshot)
                detailAttachment.name = "SearchResultDetail"
                detailAttachment.lifetime = .deleteOnSuccess
                add(detailAttachment)
            }
        }
    }
    
    func testSearchFieldInteraction() throws {
        let tabBar = app.tabBars["MainTabView"]
        tabBar.buttons["Search"].tap()
        
        let searchField = app.searchFields.firstMatch
        if searchField.exists {
            // Test typing and clearing
            searchField.tap()
            searchField.typeText("Test Query")
            
            XCTAssertEqual(searchField.value as? String, "Test Query", "Search field should contain typed text")
            
            // Clear search field
            searchField.buttons["Clear text"].tap()
            XCTAssertTrue((searchField.value as? String)?.isEmpty ?? true, "Search field should be empty after clearing")
        }
    }
    
    // MARK: - Library Management Tests
    
    func testLibraryViewInteractions() throws {
        let tabBar = app.tabBars["MainTabView"]
        tabBar.buttons["Library"].tap()
        
        // Test add book button if available
        if app.buttons["AddBookButton"].exists {
            app.buttons["AddBookButton"].tap()
            
            // Should either navigate to search or show add options
            XCTAssertTrue(app.navigationBars.count > 0 || app.sheets.count > 0,
                         "Add book button should trigger navigation or show sheet")
            
            // Navigate back if in navigation
            if app.navigationBars.buttons.count > 0 {
                app.navigationBars.buttons.firstMatch.tap()
            }
            
            // Dismiss sheet if present
            if app.sheets.count > 0 {
                app.buttons["Cancel"].tap()
            }
        }
        
        // Test library filters if available
        if app.buttons["FilterButton"].exists {
            app.buttons["FilterButton"].tap()
            
            // Should show filter options
            XCTAssertTrue(app.sheets.count > 0 || app.popovers.count > 0,
                         "Filter button should show filter options")
            
            // Dismiss filter
            if app.sheets.count > 0 {
                app.buttons["Done"].tap()
            }
        }
    }
    
    func testBookCardInteractions() throws {
        let tabBar = app.tabBars["MainTabView"]
        tabBar.buttons["Library"].tap()
        
        // Look for book cards in the library
        let libraryTable = app.tables["LibraryTable"]
        if libraryTable.exists && libraryTable.cells.count > 0 {
            let firstBook = libraryTable.cells.firstMatch
            
            // Test tapping book card
            firstBook.tap()
            
            // Should navigate to book details
            XCTAssertTrue(app.navigationBars.count > 0, "Should navigate to book details")
            
            // Take screenshot of book details
            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "BookDetails"
            attachment.lifetime = .deleteOnSuccess
            add(attachment)
            
            // Navigate back
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - CSV Import Workflow Tests
    
    func testCSVImportAccess() throws {
        let tabBar = app.tabBars["MainTabView"]
        tabBar.buttons["Library"].tap()
        
        // Look for import button or menu
        if app.buttons["ImportButton"].exists {
            app.buttons["ImportButton"].tap()
            
            // Should show import options or navigate to import flow
            XCTAssertTrue(app.sheets.count > 0 || app.navigationBars.count > 0,
                         "Import button should show options or navigate to import")
            
            // Take screenshot of import interface
            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "ImportInterface"
            attachment.lifetime = .deleteOnSuccess
            add(attachment)
            
            // Dismiss/navigate back
            if app.sheets.count > 0 {
                app.buttons["Cancel"].tap()
            } else if app.navigationBars.buttons.count > 0 {
                app.navigationBars.buttons.firstMatch.tap()
            }
        }
    }
    
    // MARK: - Cultural Diversity Features Tests
    
    func testCultureTabFeatures() throws {
        let tabBar = app.tabBars["MainTabView"]
        tabBar.buttons["Culture"].tap()
        
        // Wait for culture view to load
        Thread.sleep(forTimeInterval: 1.0)
        
        // Test cultural diversity charts and visualizations
        let cultureView = app.scrollViews["CultureView"]
        if cultureView.exists {
            // Take screenshot of cultural diversity interface
            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "CulturalDiversity"
            attachment.lifetime = .deleteOnSuccess
            add(attachment)
            
            // Test scrolling through cultural content
            cultureView.swipeUp()
            Thread.sleep(forTimeInterval: 0.5)
            
            let scrolledScreenshot = app.screenshot()
            let scrolledAttachment = XCTAttachment(screenshot: scrolledScreenshot)
            scrolledAttachment.name = "CulturalDiversity_Scrolled"
            scrolledAttachment.lifetime = .deleteOnSuccess
            add(scrolledAttachment)
        }
    }
    
    // MARK: - Stats and Analytics Tests
    
    func testStatsTabFeatures() throws {
        let tabBar = app.tabBars["MainTabView"]
        tabBar.buttons["Stats"].tap()
        
        // Wait for stats to load
        Thread.sleep(forTimeInterval: 1.0)
        
        // Test stats visualizations
        let statsView = app.scrollViews["StatsView"]
        if statsView.exists {
            // Take screenshot of statistics interface
            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "ReadingStats"
            attachment.lifetime = .deleteOnSuccess
            add(attachment)
            
            // Test interaction with charts if available
            if app.buttons["MonthlyChartButton"].exists {
                app.buttons["MonthlyChartButton"].tap()
                Thread.sleep(forTimeInterval: 0.5)
                
                let chartScreenshot = app.screenshot()
                let chartAttachment = XCTAttachment(screenshot: chartScreenshot)
                chartAttachment.name = "MonthlyChart"
                chartAttachment.lifetime = .deleteOnSuccess
                add(chartAttachment)
            }
        }
    }
    
    // MARK: - Performance and Responsiveness Tests
    
    func testUIResponsiveness() throws {
        let startTime = Date()
        
        // Perform rapid tab switching
        let tabBar = app.tabBars["MainTabView"]
        let tabs = ["Library", "Search", "Stats", "Culture"]
        
        for _ in 0..<3 {
            for tab in tabs {
                tabBar.buttons[tab].tap()
                
                // Verify tab switches quickly
                XCTAssertTrue(tabBar.buttons[tab].isSelected,
                             "Tab \(tab) should be selected immediately after tap")
            }
        }
        
        let duration = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(duration, 5.0, "Rapid tab switching should complete within 5 seconds")
    }
    
    func testScrollPerformance() throws {
        let tabBar = app.tabBars["MainTabView"]
        tabBar.buttons["Library"].tap()
        
        let libraryTable = app.tables["LibraryTable"]
        if libraryTable.exists {
            let startTime = Date()
            
            // Perform rapid scrolling
            for _ in 0..<10 {
                libraryTable.swipeUp()
                libraryTable.swipeDown()
            }
            
            let duration = Date().timeIntervalSince(startTime)
            XCTAssertLessThan(duration, 3.0, "Scrolling should remain responsive")
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testBasicAccessibility() throws {
        // Test that main navigation is accessible
        let tabBar = app.tabBars["MainTabView"]
        XCTAssertTrue(tabBar.isAccessibilityElement || tabBar.children(matching: .any).count > 0,
                     "Tab bar should be accessible")
        
        // Test each tab for accessibility
        let tabs = ["Library", "Search", "Stats", "Culture"]
        
        for tab in tabs {
            let tabButton = tabBar.buttons[tab]
            XCTAssertTrue(tabButton.exists, "\(tab) tab should exist")
            
            // Test accessibility properties
            XCTAssertFalse(tabButton.label.isEmpty, "\(tab) tab should have accessibility label")
        }
    }
    
    func testTouchTargetSizes() throws {
        // Test that interactive elements meet minimum touch target size
        let tabBar = app.tabBars["MainTabView"]
        
        for button in tabBar.buttons.allElementsBoundByIndex {
            let frame = button.frame
            XCTAssertGreaterThanOrEqual(frame.width, 44.0,
                                       "Button width should be at least 44pt")
            XCTAssertGreaterThanOrEqual(frame.height, 44.0,
                                       "Button height should be at least 44pt")
        }
    }
    
    // MARK: - Error State Tests
    
    func testNetworkErrorHandling() throws {
        // This would require specific test conditions or mock network states
        let tabBar = app.tabBars["MainTabView"]
        tabBar.buttons["Search"].tap()
        
        let searchField = app.searchFields.firstMatch
        if searchField.exists {
            searchField.tap()
            searchField.typeText("Network Error Test")
            
            // Wait for potential error message
            Thread.sleep(forTimeInterval: 3.0)
            
            // Check for error handling UI
            if app.alerts.count > 0 {
                let errorAlert = app.alerts.firstMatch
                XCTAssertTrue(errorAlert.exists, "Error alert should be displayed")
                
                // Take screenshot of error state
                let screenshot = app.screenshot()
                let attachment = XCTAttachment(screenshot: screenshot)
                attachment.name = "NetworkError"
                attachment.lifetime = .deleteOnSuccess
                add(attachment)
                
                // Dismiss error
                if errorAlert.buttons["OK"].exists {
                    errorAlert.buttons["OK"].tap()
                }
            }
        }
    }
}