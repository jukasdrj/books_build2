//
// NEW: booksTests/CSVImportTests.swift
//
import Testing
import Foundation
@testable import books

@Suite("CSV Import Tests")
struct CSVImportTests {
    
    @Test("CSVParser Configuration - Should have correct defaults")
    func testCSVParserConfiguration() throws {
        let config = CSVParser.Config.default
        
        #expect(config.delimiter == ",")
        #expect(config.quote == "\"")
        #expect(config.maxFileSize == 50 * 1024 * 1024) // 50MB
        #expect(config.maxColumns == 100)
        #expect(config.encoding == .utf8)
    }
    
    @Test("BookField Enum - Should have correct properties")
    func testBookFieldEnum() throws {
        let allCases = BookField.allCases
        #expect(allCases.count >= 20)
        
        #expect(BookField.title.isRequired == true)
        #expect(BookField.author.isRequired == true)
        #expect(BookField.isbn.isRequired == false)
        #expect(BookField.rating.isRequired == false)
        
        #expect(BookField.title.displayName == "Title")
        #expect(BookField.author.displayName == "Author")
        #expect(BookField.personalNotes.displayName == "Personal Notes")
    }
    
    @Test("GoodreadsColumnMappings - Should auto-map common columns")
    func testGoodreadsColumnMappings() throws {
        let columns = ["Title", "Author", "My Rating", "Date Read", "ISBN"]
        let mappings = GoodreadsColumnMappings.autoMap(columns: columns)
        
        #expect(mappings.count >= 3) // Should map at least title, author, rating
        #expect(mappings["Title"] == .title)
        #expect(mappings["Author"] == .author)
        #expect(mappings["My Rating"] == .rating)
    }
    
    @Test("ReadingStatus Mapping - Should map Goodreads statuses correctly")
    func testReadingStatusMapping() throws {
        #expect(GoodreadsColumnMappings.mapReadingStatus("read") == .read)
        #expect(GoodreadsColumnMappings.mapReadingStatus("currently-reading") == .reading)
        #expect(GoodreadsColumnMappings.mapReadingStatus("to-read") == .toRead)
        #expect(GoodreadsColumnMappings.mapReadingStatus("did not finish") == .dnf)
        #expect(GoodreadsColumnMappings.mapReadingStatus("unknown") == .toRead) // Default
    }
    
    @Test("ParsedBook Validation - Should validate correctly")
    func testParsedBookValidation() throws {
        var validBook = ParsedBook(rowIndex: 1)
        validBook.title = "Valid Title"
        validBook.author = "Valid Author"
        validBook.rating = 4
        
        #expect(validBook.isValid == true)
        #expect(validBook.validationErrors.isEmpty)
        
        var invalidBook = ParsedBook(rowIndex: 2)
        invalidBook.title = "" // Empty title
        invalidBook.author = "Valid Author"
        invalidBook.rating = 10 // Invalid rating
        
        #expect(invalidBook.isValid == false)
        #expect(invalidBook.validationErrors.count >= 2)
        #expect(invalidBook.validationErrors.contains("Missing title"))
        #expect(invalidBook.validationErrors.contains("Invalid rating (must be 1-5)"))
    }
    
    @Test("ImportProgress - Should track progress correctly")
    func testImportProgress() throws {
        var progress = ImportProgress(sessionId: UUID())
        progress.totalBooks = 100
        progress.processedBooks = 25
        
        #expect(progress.progress == 0.25)
        #expect(progress.isComplete == false)
        
        progress.processedBooks = 100
        #expect(progress.isComplete == true)
        
        progress.isCancelled = true
        #expect(progress.isComplete == true)
    }
    
    @Test("ImportResult - Should calculate success rate correctly")
    func testImportResult() throws {
        let result = ImportResult(
            sessionId: UUID(),
            totalBooks: 100,
            successfulImports: 85,
            failedImports: 10,
            duplicatesSkipped: 5,
            duplicatesISBN: 3,
            duplicatesGoogleID: 1,
            duplicatesTitleAuthor: 1,
            duration: 120.0,
            errors: [],
            importedBookIds: []
        )
        
        #expect(result.successRate == 0.85)
        #expect(result.hasErrors == false)
        #expect(result.summary.contains("85 imported"))
        #expect(result.summary.contains("5 duplicates skipped"))
        #expect(result.summary.contains("10 failed"))
    }
    
    @Test("DuplicateDetection - Should detect duplicates by ISBN first")
    func testISBNFirstDuplicateDetection() throws {
        // Create test metadata with ISBN
        let metadata1 = BookMetadata(
            googleBooksID: "google-id-1",
            title: "The Great Gatsby",
            authors: ["F. Scott Fitzgerald"],
            isbn: "978-0-7432-7356-5"
        )
        
        let metadata2 = BookMetadata(
            googleBooksID: "google-id-2",  // Different Google ID
            title: "Great Gatsby",  // Slightly different title
            authors: ["Fitzgerald"],  // Different author format
            isbn: "9780743273565"  // Same ISBN without hyphens
        )
        
        let userBook = UserBook(metadata: metadata1)
        
        // Test duplicate detection - should match by ISBN despite different title/author
        let duplicate = DuplicateDetectionService.findExistingBook(
            for: metadata2,
            in: [userBook]
        )
        
        #expect(duplicate != nil, "Should find duplicate by ISBN")
        #expect(duplicate?.metadata?.googleBooksID == "google-id-1")
    }
    
    @Test("DuplicateDetection - Should fallback to title/author when no ISBN")
    func testTitleAuthorFallbackDuplicateDetection() throws {
        // Create test metadata without ISBN
        let metadata1 = BookMetadata(
            googleBooksID: "google-id-1",
            title: "To Kill a Mockingbird",
            authors: ["Harper Lee"],
            isbn: nil
        )
        
        let metadata2 = BookMetadata(
            googleBooksID: "google-id-2",
            title: "to kill a mockingbird",  // Different case
            authors: ["Harper Lee"],
            isbn: nil
        )
        
        let userBook = UserBook(metadata: metadata1)
        
        // Test duplicate detection - should match by title/author
        let duplicate = DuplicateDetectionService.findExistingBook(
            for: metadata2,
            in: [userBook]
        )
        
        #expect(duplicate != nil, "Should find duplicate by title and author")
        #expect(duplicate?.metadata?.googleBooksID == "google-id-1")
    }
}
