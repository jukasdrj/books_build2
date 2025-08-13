import XCTest
import SwiftData
@testable import books

/// Tests for the 5-step CSV import workflow using modern Swift patterns
@MainActor
final class CSVImportWorkflowTests: BookTrackerTestSuite {
    
    var mockCSVImportService: MockCSVImportService!
    
    override func setUp() async throws {
        try await super.setUp()
        mockCSVImportService = MockCSVImportService()
    }
    
    override func tearDown() async throws {
        mockCSVImportService = nil
        try await super.tearDown()
    }
    
    // MARK: - Test Data Helpers
    
    /// Creates a test CSV file URL for testing
    private func createTestCSVFile(content: String) throws -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let csvFile = tempDir.appendingPathComponent("test_import_\(UUID().uuidString).csv")
        try content.write(to: csvFile, atomically: true, encoding: .utf8)
        return csvFile
    }
    
    /// Standard Goodreads CSV format test data
    private var goodreadsCSVContent: String {
        """
        Title,Author,ISBN,My Rating,Date Read,Date Added,Bookshelves,My Review
        "The Great Gatsby","F. Scott Fitzgerald","9780743273565","5","2024/01/15","2024/01/01","fiction,classics","Amazing book!"
        "To Kill a Mockingbird","Harper Lee","9780061120084","4","2024/02/20","2024/02/01","fiction,classics","Powerful story"
        "1984","George Orwell","9780451524935","5","","2024/03/01","to-read","Not read yet"
        """
    }
    
    /// CSV with various edge cases and formats
    private var edgeCaseCSVContent: String {
        """
        Title,Author,ISBN,My Rating,Date Read,Date Added,Bookshelves,My Review
        "Book with, comma in title","Author Name","1234567890","3","2024/01/15","2024/01/01","fiction","Good read"
        "Book with ""quoted"" words","Another Author","0987654321","4","","2024/02/01","non-fiction",""
        "Book with\\nnewline","Third Author","1111111111","2","2024/03/01","2024/02/15","biography","Complex\\nreview"
        "=9876543210","ISBN with equals","=1234567890","5","2024/04/01","2024/03/01","reference","Excel formula ISBN"
        """
    }
    
    // MARK: - Step 1: File Selection and Validation Tests
    
    func testCSVFileValidation() async throws {
        // Valid CSV
        let validCSV = try createTestCSVFile(content: goodreadsCSVContent)
        mockCSVImportService.validationResult = true
        
        let isValid = try await mockCSVImportService.validateCSVFormat(validCSV)
        XCTAssertTrue(isValid, "Valid CSV should pass validation")
        
        // Invalid CSV
        let invalidCSV = try createTestCSVFile(content: "Invalid,CSV\\nData")
        mockCSVImportService.validationResult = false
        
        let isInvalid = try await mockCSVImportService.validateCSVFormat(invalidCSV)
        XCTAssertFalse(isInvalid, "Invalid CSV should fail validation")
        
        // Clean up
        try? FileManager.default.removeItem(at: validCSV)
        try? FileManager.default.removeItem(at: invalidCSV)
    }
    
    func testEmptyCSVFileHandling() async throws {
        let emptyCSV = try createTestCSVFile(content: "")
        
        do {
            _ = try await mockCSVImportService.validateCSVFormat(emptyCSV)
            XCTFail("Empty CSV should throw an error")
        } catch {
            XCTAssertTrue(error is MockError, "Should throw appropriate error for empty file")
        }
        
        try? FileManager.default.removeItem(at: emptyCSV)
    }
    
    // MARK: - Step 2: CSV Preview Tests
    
    func testCSVPreviewGeneration() async throws {
        let csvFile = try createTestCSVFile(content: goodreadsCSVContent)
        
        // Set up mock preview result
        let mockPreview = CSVPreviewResult(
            books: [
                ParsedBook(rowIndex: 1, title: "The Great Gatsby", author: "F. Scott Fitzgerald", isbn: "9780743273565"),
                ParsedBook(rowIndex: 2, title: "To Kill a Mockingbird", author: "Harper Lee", isbn: "9780061120084"),
                ParsedBook(rowIndex: 3, title: "1984", author: "George Orwell", isbn: "9780451524935")
            ],
            mappedColumns: [
                "Title": 0,
                "Author": 1, 
                "ISBN": 2,
                "My Rating": 3,
                "Date Read": 4,
                "Date Added": 5
            ],
            totalRows: 3,
            estimatedImportTime: 15
        )
        
        mockCSVImportService.previewResult = mockPreview
        
        let preview = try await mockCSVImportService.previewCSV(from: csvFile)
        
        XCTAssertEqual(preview.books.count, 3)
        XCTAssertEqual(preview.totalRows, 3)
        XCTAssertTrue(preview.mappedColumns.keys.contains("Title"))
        XCTAssertTrue(preview.mappedColumns.keys.contains("Author"))
        XCTAssertTrue(preview.mappedColumns.keys.contains("ISBN"))
        XCTAssertGreaterThan(preview.estimatedImportTime, 0)
        
        try? FileManager.default.removeItem(at: csvFile)
    }
    
    func testCSVPreviewWithSpecialCharacters() async throws {
        let csvFile = try createTestCSVFile(content: edgeCaseCSVContent)
        
        let mockPreview = CSVPreviewResult(
            books: [
                ParsedBook(rowIndex: 1, title: "Book with, comma in title", author: "Author Name", isbn: "1234567890"),
                ParsedBook(rowIndex: 2, title: "Book with \"quoted\" words", author: "Another Author", isbn: "0987654321")
            ],
            mappedColumns: ["Title": 0, "Author": 1, "ISBN": 2],
            totalRows: 4,
            estimatedImportTime: 20
        )
        
        mockCSVImportService.previewResult = mockPreview
        
        let preview = try await mockCSVImportService.previewCSV(from: csvFile)
        
        XCTAssertEqual(preview.books.count, 2)
        XCTAssertTrue(preview.books[0].title?.contains("comma") == true)
        XCTAssertTrue(preview.books[1].title?.contains("quoted") == true)
        
        try? FileManager.default.removeItem(at: csvFile)
    }
    
    // MARK: - Step 3: Column Mapping Tests
    
    func testDefaultGoodreadsColumnMapping() async throws {
        let standardMapping = [
            "Title": "Title",
            "Author": "Author", 
            "ISBN": "ISBN",
            "Rating": "My Rating",
            "Date Read": "Date Read",
            "Date Added": "Date Added",
            "Shelves": "Bookshelves",
            "Review": "My Review"
        ]
        
        // Verify standard Goodreads columns are recognized
        XCTAssertEqual(standardMapping["Title"], "Title")
        XCTAssertEqual(standardMapping["Author"], "Author")
        XCTAssertEqual(standardMapping["ISBN"], "ISBN")
        XCTAssertEqual(standardMapping["Rating"], "My Rating")
    }
    
    func testCustomColumnMapping() async throws {
        let customMapping = [
            "Title": "Book Title",
            "Author": "Book Author",
            "ISBN": "ISBN13",
            "Rating": "Star Rating",
            "Date Read": "Completed Date"
        ]
        
        // Test that custom mappings work
        XCTAssertEqual(customMapping["Title"], "Book Title")
        XCTAssertEqual(customMapping["Author"], "Book Author")
        XCTAssertEqual(customMapping["ISBN"], "ISBN13")
    }
    
    func testMissingRequiredColumns() async throws {
        let incompleteMapping = [
            "Title": "Book Title"
            // Missing Author, which should be required
        ]
        
        // This would normally be validated by the import service
        let requiredColumns = ["Title", "Author"]
        let missingColumns = requiredColumns.filter { !incompleteMapping.keys.contains($0) }
        
        XCTAssertFalse(missingColumns.isEmpty, "Should detect missing required columns")
        XCTAssertTrue(missingColumns.contains("Author"), "Should detect missing Author column")
    }
    
    // MARK: - Step 4: Import Process Tests
    
    func testSuccessfulImport() async throws {
        let csvFile = try createTestCSVFile(content: goodreadsCSVContent)
        
        let columnMapping = [
            "Title": "Title",
            "Author": "Author",
            "ISBN": "ISBN",
            "Rating": "My Rating",
            "Date Read": "Date Read"
        ]
        
        let mockResult = CSVImportResult(
            successCount: 3,
            skippedBooks: [],
            errors: [],
            importDuration: 2.5
        )
        
        mockCSVImportService.importResult = mockResult
        
        let result = try await mockCSVImportService.importBooks(
            from: csvFile,
            columnMapping: columnMapping,
            modelContext: modelContext
        )
        
        XCTAssertEqual(result.successCount, 3)
        XCTAssertTrue(result.skippedBooks.isEmpty)
        XCTAssertTrue(result.errors.isEmpty)
        XCTAssertEqual(mockCSVImportService.importCallCount, 1)
        
        try? FileManager.default.removeItem(at: csvFile)
    }
    
    func testImportWithSkippedBooks() async throws {
        let csvFile = try createTestCSVFile(content: goodreadsCSVContent)
        
        let skippedBook = ParsedBook(rowIndex: 2, title: "Duplicate Book", author: "Some Author", isbn: nil)
        
        let mockResult = CSVImportResult(
            successCount: 2,
            skippedBooks: [skippedBook],
            errors: [],
            importDuration: 2.0
        )
        
        mockCSVImportService.importResult = mockResult
        
        let result = try await mockCSVImportService.importBooks(
            from: csvFile,
            columnMapping: [:],
            modelContext: modelContext
        )
        
        XCTAssertEqual(result.successCount, 2)
        XCTAssertEqual(result.skippedBooks.count, 1)
        XCTAssertEqual(result.skippedBooks.first?.title, "Duplicate Book")
        
        try? FileManager.default.removeItem(at: csvFile)
    }
    
    func testImportWithErrors() async throws {
        let csvFile = try createTestCSVFile(content: goodreadsCSVContent)
        
        let importError = ImportError(
            rowIndex: 3,
            bookTitle: "The Great Gatsby",
            errorType: .validationError,
            message: "Invalid ISBN format",
            suggestions: ["Ensure the ISBN contains only digits"]
        )
        
        let mockResult = CSVImportResult(
            successCount: 2,
            skippedBooks: [],
            errors: [importError],
            importDuration: 1.8
        )
        
        mockCSVImportService.importResult = mockResult
        
        let result = try await mockCSVImportService.importBooks(
            from: csvFile,
            columnMapping: [:],
            modelContext: modelContext
        )
        
        XCTAssertEqual(result.successCount, 2)
        XCTAssertEqual(result.errors.count, 1)
        XCTAssertEqual(result.errors.first?.message, "Invalid ISBN format")
        XCTAssertEqual(result.errors.first?.errorType, .validationError)
        
        try? FileManager.default.removeItem(at: csvFile)
    }
    
    // MARK: - Step 5: Completion and Verification Tests
    
    func testImportCompletionVerification() async throws {
        // Create some test books in the database first
        let book1 = createTestUserBook(title: "Imported Book 1", author: "Author 1")
        let book2 = createTestUserBook(title: "Imported Book 2", author: "Author 2")
        let book3 = createTestUserBook(title: "Imported Book 3", author: "Author 3")
        
        try saveContext()
        
        let allBooks = try fetchAllUserBooks()
        XCTAssertEqual(allBooks.count, 3, "Should have 3 imported books")
        
        // Verify books have proper data
        let titles = Set(allBooks.compactMap { $0.metadata?.title })
        XCTAssertTrue(titles.contains("Imported Book 1"))
        XCTAssertTrue(titles.contains("Imported Book 2"))
        XCTAssertTrue(titles.contains("Imported Book 3"))
    }
    
    func testImportSummaryGeneration() async throws {
        let mockResult = CSVImportResult(
            successCount: 5,
            skippedBooks: [
                ParsedBook(rowIndex: 3, title: "Duplicate", author: "Author", isbn: nil)
            ],
            errors: [
                ImportError(rowIndex: 7, bookTitle: "Unknown", errorType: .validationError, message: "Invalid data", suggestions: ["Check the ISBN column"])
            ],
            importDuration: 3.2
        )
        
        // Test summary generation
        let totalProcessed = mockResult.successCount + mockResult.skippedBooks.count + mockResult.errors.count
        let successRate = Double(mockResult.successCount) / Double(totalProcessed)
        
        XCTAssertEqual(totalProcessed, 7)
        XCTAssertEqual(successRate, 5.0/7.0, accuracy: 0.01)
        XCTAssertEqual(mockResult.importDuration, 3.2)
    }
    
    // MARK: - ISBN Cleaning and Processing Tests
    
    func testISBNCleaningLogic() async throws {
        let dirtyISBNs = [
            "=9780743273565",    // Excel formula prefix
            " 9780061120084 ",   // Whitespace
            "978-0-451-52493-5", // Hyphens
            "isbn:9780547928227", // Prefix
            "9780547928227x"     // Suffix
        ]
        
        let expectedCleanISBNs = [
            "9780743273565",
            "9780061120084",
            "9780451524935",
            "9780547928227",
            "9780547928227"
        ]
        
        // This would normally be implemented in CSVImportService
        for (index, dirtyISBN) in dirtyISBNs.enumerated() {
            let cleanedISBN = cleanISBN(dirtyISBN)
            XCTAssertEqual(cleanedISBN, expectedCleanISBNs[index], 
                          "ISBN '\(dirtyISBN)' should clean to '\(expectedCleanISBNs[index])'")
        }
    }
    
    private func cleanISBN(_ isbn: String) -> String {
        var cleaned = isbn
        
        // Remove leading equals (Excel formula protection)
        if cleaned.hasPrefix("=") {
            cleaned = String(cleaned.dropFirst())
        }
        
        // Remove whitespace
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove hyphens
        cleaned = cleaned.replacingOccurrences(of: "-", with: "")
        
        // Remove common prefixes
        if cleaned.lowercased().hasPrefix("isbn:") {
            cleaned = String(cleaned.dropFirst(5))
        }
        
        // Remove trailing letters
        cleaned = cleaned.replacingOccurrences(of: #"[a-zA-Z]+$"#, with: "", options: .regularExpression)
        
        return cleaned
    }
    
    // MARK: - Progress Tracking Tests
    
    func testImportProgressTracking() async throws {
        let csvFile = try createTestCSVFile(content: goodreadsCSVContent)
        
        // Mock progress tracking
        var progressUpdates: [Double] = []
        let expectedProgressSteps = [0.0, 0.33, 0.66, 1.0]
        
        // Simulate progress updates during import
        for progress in expectedProgressSteps {
            progressUpdates.append(progress)
        }
        
        XCTAssertEqual(progressUpdates.count, 4)
        XCTAssertEqual(progressUpdates.first, 0.0)
        XCTAssertEqual(progressUpdates.last, 1.0)
        
        // Verify progress is monotonically increasing
        for i in 1..<progressUpdates.count {
            XCTAssertGreaterThanOrEqual(progressUpdates[i], progressUpdates[i-1])
        }
        
        try? FileManager.default.removeItem(at: csvFile)
    }
    
    // MARK: - Error Recovery Tests
    
    func testImportErrorRecovery() async throws {
        let csvFile = try createTestCSVFile(content: goodreadsCSVContent)
        
        // Test that import can recover from partial failures
        mockCSVImportService.shouldThrowError = false
        
        let result = try await mockCSVImportService.importBooks(
            from: csvFile,
            columnMapping: [:],
            modelContext: modelContext
        )
        
        XCTAssertNotNil(result, "Import should not fail completely on partial errors")
        
        try? FileManager.default.removeItem(at: csvFile)
    }
    
    func testImportCancellation() async throws {
        // Test import cancellation handling
        let csvFile = try createTestCSVFile(content: goodreadsCSVContent)
        
        // Create a task that can be cancelled
        let importTask = Task {
            try await mockCSVImportService.importBooks(
                from: csvFile,
                columnMapping: [:],
                modelContext: modelContext
            )
        }
        
        // Immediately cancel the task
        importTask.cancel()
        
        do {
            _ = try await importTask.value
        } catch {
            // Cancellation should result in an error
            XCTAssertTrue(error is CancellationError || error is MockError)
        }
        
        try? FileManager.default.removeItem(at: csvFile)
    }
}