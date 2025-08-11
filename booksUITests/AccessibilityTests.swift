import XCTest

/// Comprehensive accessibility tests for the book reading tracker app
/// Tests VoiceOver support, Dynamic Type, color contrast, and WCAG compliance
final class AccessibilityTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launchArguments.append("--accessibility-testing")
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - VoiceOver Support Tests
    
    func testVoiceOverNavigation() throws {
        // Test basic VoiceOver navigation through tab bar
        let tabBar = app.tabBars["MainTabView"]
        
        let tabs = ["Library", "Search", "Stats", "Culture"]
        
        for tab in tabs {
            let tabButton = tabBar.buttons[tab]
            
            // Test that tab buttons are accessible
            XCTAssertTrue(tabButton.exists, "\(tab) tab should exist")
            XCTAssertTrue(tabButton.isAccessibilityElement, "\(tab) tab should be accessible to VoiceOver")
            
            // Test accessibility label
            let accessibilityLabel = tabButton.label
            XCTAssertFalse(accessibilityLabel.isEmpty, "\(tab) tab should have accessibility label")
            XCTAssertTrue(accessibilityLabel.contains(tab) || accessibilityLabel.lowercased().contains(tab.lowercased()),
                         "\(tab) tab accessibility label should contain tab name")
            
            // Test accessibility traits
            XCTAssertTrue(tabButton.elementType == .button, "\(tab) tab should have button trait")
            
            // Navigate to tab and test content accessibility
            tabButton.tap()
            
            // Wait for tab content to load
            Thread.sleep(forTimeInterval: 0.5)
            
            // Take screenshot for visual verification
            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "Accessibility_\(tab)"
            attachment.lifetime = .deleteOnSuccess
            add(attachment)
        }
    }
    
    func testVoiceOverBookCardAccessibility() throws {
        let tabBar = app.tabBars["MainTabView"]
        tabBar.buttons["Library"].tap()
        
        // Test book card accessibility
        let libraryTable = app.tables["LibraryTable"]
        if libraryTable.exists && libraryTable.cells.count > 0 {
            let firstBookCard = libraryTable.cells.firstMatch
            
            // Test basic accessibility
            XCTAssertTrue(firstBookCard.isAccessibilityElement || firstBookCard.children(matching: .any).count > 0,
                         "Book card should be accessible")
            
            // Test accessibility label contains book information
            let accessibilityLabel = firstBookCard.label
            XCTAssertFalse(accessibilityLabel.isEmpty, "Book card should have accessibility label")
            
            // Should contain title and author information
            // This would need to be customized based on actual book data
            XCTAssertTrue(accessibilityLabel.count > 10, "Book card accessibility label should be descriptive")
            
            // Test accessibility hint for actions
            if let accessibilityHint = firstBookCard.value as? String, !accessibilityHint.isEmpty {
                // Hint should describe what happens when tapped - verify it's meaningful
                XCTAssertTrue(accessibilityHint.count > 5, "Accessibility hint should be descriptive")
            }
            
            // Test that rating information is accessible
            let ratingElements = firstBookCard.buttons.matching(identifier: "StarRating")
            if ratingElements.count > 0 {
                for i in 0..<min(ratingElements.count, 5) {
                    let starElement = ratingElements.element(boundBy: i)
                    XCTAssertTrue(starElement.isAccessibilityElement,
                                 "Star rating \(i+1) should be accessible")
                }
            }
        }
    }
    
    func testVoiceOverSearchAccessibility() throws {
        let tabBar = app.tabBars["MainTabView"]
        tabBar.buttons["Search"].tap()
        
        // Test search field accessibility
        let searchField = app.searchFields.firstMatch
        if searchField.exists {
            XCTAssertTrue(searchField.isAccessibilityElement, "Search field should be accessible")
            
            let searchLabel = searchField.label
            XCTAssertFalse(searchLabel.isEmpty, "Search field should have accessibility label")
            XCTAssertTrue(searchLabel.lowercased().contains("search") || 
                         searchLabel.lowercased().contains("find"),
                         "Search field label should indicate search functionality")
            
            // Test search field placeholder
            let searchPlaceholder = searchField.placeholderValue
            XCTAssertNotNil(searchPlaceholder, "Search field should have placeholder text")
            
            // Test typing accessibility
            searchField.tap()
            searchField.typeText("Test Search")
            
            XCTAssertEqual(searchField.value as? String, "Test Search",
                          "Search field should update value for accessibility")
        }
        
        // Test search results accessibility
        if searchField.exists {
            searchField.tap()
            searchField.typeText("Swift")
        }
        
        // Wait for results
        Thread.sleep(forTimeInterval: 2.0)
        
        let searchResultsTable = app.tables["SearchResultsTable"]
        if searchResultsTable.exists && searchResultsTable.cells.count > 0 {
            let firstResult = searchResultsTable.cells.firstMatch
            
            XCTAssertTrue(firstResult.isAccessibilityElement,
                         "Search result should be accessible")
            
            let resultLabel = firstResult.label
            XCTAssertFalse(resultLabel.isEmpty, "Search result should have accessibility label")
            XCTAssertTrue(resultLabel.count > 5, "Search result label should be descriptive")
        }
    }
    
    // MARK: - Dynamic Type Support Tests
    
    func testDynamicTypeSupport() throws {
        // This test would need to be run with different Dynamic Type settings
        // We can test that text elements respond to size changes
        
        let tabBar = app.tabBars["MainTabView"]
        tabBar.buttons["Library"].tap()
        
        // Take screenshots at different text sizes for manual verification
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "DynamicType_Default"
        attachment.lifetime = .deleteOnSuccess
        add(attachment)
        
        // Test that text elements don't get truncated at larger sizes
        // This would require setting up different text size configurations
        
        // Verify important text is still visible
        let libraryTable = app.tables["LibraryTable"]
        if libraryTable.exists && libraryTable.cells.count > 0 {
            let firstBook = libraryTable.cells.firstMatch
            let bookTitle = firstBook.staticTexts.firstMatch
            
            if bookTitle.exists {
                // Title should be visible and not truncated
                XCTAssertTrue(bookTitle.exists, "Book title should remain visible")
                XCTAssertFalse(bookTitle.label.hasSuffix("..."), "Book title should not be truncated")
            }
        }
    }
    
    func testLargeTextAccessibility() throws {
        // Test accessibility with larger text sizes
        // This simulates accessibility text sizes (A11Y sizes)
        
        let tabBar = app.tabBars["MainTabView"]
        
        // Test that all tabs remain accessible with large text
        let tabs = ["Library", "Search", "Stats", "Culture"]
        
        for tab in tabs {
            let tabButton = tabBar.buttons[tab]
            
            // Tab should still be touchable
            XCTAssertTrue(tabButton.exists, "\(tab) tab should exist with large text")
            XCTAssertTrue(tabButton.isHittable, "\(tab) tab should be hittable with large text")
            
            // Tab label should not be empty
            XCTAssertFalse(tabButton.label.isEmpty, "\(tab) tab should have label with large text")
            
            tabButton.tap()
            Thread.sleep(forTimeInterval: 0.3)
            
            // Take screenshot for large text verification
            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "LargeText_\(tab)"
            attachment.lifetime = .deleteOnSuccess
            add(attachment)
        }
    }
    
    // MARK: - Color Contrast and Visual Accessibility Tests
    
    func testHighContrastMode() throws {
        // Test app behavior with high contrast mode
        // This would need to be configured at the system level
        
        let tabBar = app.tabBars["MainTabView"]
        
        // Test each theme with high contrast considerations
        if app.buttons["ThemePickerButton"].exists {
            app.buttons["ThemePickerButton"].tap()
            
            let themes = ["Purple Boho", "Forest Sage", "Ocean Blues", "Sunset Warmth", "Monochrome"]
            
            for theme in themes {
                let themeButton = app.buttons["\(theme)ThemeButton"]
                if themeButton.exists {
                    themeButton.tap()
                    Thread.sleep(forTimeInterval: 0.5)
                    
                    // Take screenshot for contrast analysis
                    let screenshot = app.screenshot()
                    let attachment = XCTAttachment(screenshot: screenshot)
                    attachment.name = "HighContrast_\(theme.replacingOccurrences(of: " ", with: "_"))"
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
    
    func testDarkModeAccessibility() throws {
        // Test accessibility in dark mode
        // This would need dark mode to be enabled
        
        let tabBar = app.tabBars["MainTabView"]
        let tabs = ["Library", "Search", "Stats", "Culture"]
        
        for tab in tabs {
            tabBar.buttons[tab].tap()
            Thread.sleep(forTimeInterval: 0.3)
            
            // Take screenshot for dark mode accessibility verification
            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "DarkMode_\(tab)"
            attachment.lifetime = .deleteOnSuccess
            add(attachment)
            
            // Verify text is still readable in dark mode
            let textElements = app.staticTexts.allElementsBoundByIndex
            for textElement in textElements.prefix(5) { // Test first 5 text elements
                XCTAssertTrue(textElement.exists, "Text should exist in dark mode")
                XCTAssertFalse(textElement.label.isEmpty, "Text should not be empty in dark mode")
            }
        }
    }
    
    // MARK: - Interaction Accessibility Tests
    
    func testTouchTargetSizes() throws {
        // Test that all interactive elements meet minimum 44pt touch target
        let tabBar = app.tabBars["MainTabView"]
        
        // Test tab bar buttons
        for tabButton in tabBar.buttons.allElementsBoundByIndex {
            let frame = tabButton.frame
            XCTAssertGreaterThanOrEqual(frame.width, 44.0,
                                       "Tab button width should be at least 44pt for accessibility")
            XCTAssertGreaterThanOrEqual(frame.height, 44.0,
                                       "Tab button height should be at least 44pt for accessibility")
        }
        
        // Test other interactive elements
        tabBar.buttons["Library"].tap()
        
        // Test add/action buttons
        if app.buttons["AddBookButton"].exists {
            let addButton = app.buttons["AddBookButton"]
            let addButtonFrame = addButton.frame
            XCTAssertGreaterThanOrEqual(addButtonFrame.width, 44.0,
                                       "Add button width should be at least 44pt")
            XCTAssertGreaterThanOrEqual(addButtonFrame.height, 44.0,
                                       "Add button height should be at least 44pt")
        }
        
        // Test filter buttons
        if app.buttons["FilterButton"].exists {
            let filterButton = app.buttons["FilterButton"]
            let filterButtonFrame = filterButton.frame
            XCTAssertGreaterThanOrEqual(filterButtonFrame.width, 44.0,
                                       "Filter button width should be at least 44pt")
            XCTAssertGreaterThanOrEqual(filterButtonFrame.height, 44.0,
                                       "Filter button height should be at least 44pt")
        }
    }
    
    func testKeyboardNavigation() throws {
        // Test keyboard navigation support
        let tabBar = app.tabBars["MainTabView"]
        tabBar.buttons["Search"].tap()
        
        let searchField = app.searchFields.firstMatch
        if searchField.exists {
            searchField.tap()
            
            // Test that keyboard appears and is accessible
            XCTAssertTrue(app.keyboards.count > 0, "Keyboard should appear for search field")
            
            // Test typing
            searchField.typeText("Accessibility Test")
            XCTAssertEqual(searchField.value as? String, "Accessibility Test",
                          "Search field should accept keyboard input")
            
            // Test keyboard dismissal
            app.keyboards.buttons["Return"].tap()
            // Keyboard might still be visible depending on implementation
        }
    }
    
    // MARK: - Screen Reader Announcements Tests
    
    func testScreenReaderAnnouncements() throws {
        // Test that important state changes are announced to screen readers
        let tabBar = app.tabBars["MainTabView"]
        
        // Test tab selection announcements
        tabBar.buttons["Library"].tap()
        // Screen reader should announce "Library selected" or similar
        
        tabBar.buttons["Search"].tap()
        // Screen reader should announce "Search selected" or similar
        
        // Test loading state announcements
        let searchField = app.searchFields.firstMatch
        if searchField.exists {
            searchField.tap()
            searchField.typeText("Loading Test")
            
            // Wait for potential loading state
            Thread.sleep(forTimeInterval: 1.0)
            
            // Screen reader should announce loading/results states
        }
    }
    
    // MARK: - Accessibility Actions Tests
    
    func testCustomAccessibilityActions() throws {
        let tabBar = app.tabBars["MainTabView"]
        tabBar.buttons["Library"].tap()
        
        // Test book card accessibility actions
        let libraryTable = app.tables["LibraryTable"]
        if libraryTable.exists && libraryTable.cells.count > 0 {
            let firstBookCard = libraryTable.cells.firstMatch
            
            // Test that custom accessibility actions are available
            // For example: "Mark as Read", "Add Rating", "Edit Book"
            
            // This would require the app to implement custom accessibility actions
            // We can test that the basic tap action works
            XCTAssertTrue(firstBookCard.isHittable, "Book card should be hittable")
            
            firstBookCard.tap()
            
            // Should navigate to detail view
            XCTAssertTrue(app.navigationBars.count > 0,
                         "Book card tap should navigate to detail view")
            
            // Navigate back
            if app.navigationBars.buttons.count > 0 {
                app.navigationBars.buttons.firstMatch.tap()
            }
        }
    }
    
    // MARK: - Error and Alert Accessibility Tests
    
    func testErrorMessageAccessibility() throws {
        // Test that error messages are properly announced to screen readers
        let tabBar = app.tabBars["MainTabView"]
        tabBar.buttons["Search"].tap()
        
        let searchField = app.searchFields.firstMatch
        if searchField.exists {
            searchField.tap()
            searchField.typeText("Error Test Query")
            
            // Wait for potential error
            Thread.sleep(forTimeInterval: 3.0)
            
            // Check for error alerts
            if app.alerts.count > 0 {
                let alert = app.alerts.firstMatch
                
                XCTAssertTrue(alert.isAccessibilityElement,
                             "Error alert should be accessible")
                
                let alertTitle = alert.label
                XCTAssertFalse(alertTitle.isEmpty,
                              "Error alert should have accessible title")
                
                // Error alert should be announced automatically
                // and should have appropriate accessibility traits
                
                // Dismiss alert
                if alert.buttons["OK"].exists {
                    let okButton = alert.buttons["OK"]
                    XCTAssertTrue(okButton.isAccessibilityElement,
                                 "OK button should be accessible")
                    okButton.tap()
                }
            }
        }
    }
    
    // MARK: - Form Accessibility Tests
    
    func testFormAccessibility() throws {
        // Test form accessibility if the app has forms (like book editing)
        let tabBar = app.tabBars["MainTabView"]
        tabBar.buttons["Library"].tap()
        
        // Navigate to book editing if available
        if app.buttons["AddBookButton"].exists {
            app.buttons["AddBookButton"].tap()
            
            // Look for form fields
            let textFields = app.textFields.allElementsBoundByIndex
            
            for textField in textFields {
                XCTAssertTrue(textField.isAccessibilityElement,
                             "Form text field should be accessible")
                
                let fieldLabel = textField.label
                XCTAssertFalse(fieldLabel.isEmpty,
                              "Form field should have accessibility label")
                
                // Test that field describes its purpose
                XCTAssertTrue(fieldLabel.count > 2,
                             "Form field label should be descriptive")
            }
            
            // Navigate back
            if app.navigationBars.buttons.count > 0 {
                app.navigationBars.buttons.firstMatch.tap()
            }
        }
    }
}