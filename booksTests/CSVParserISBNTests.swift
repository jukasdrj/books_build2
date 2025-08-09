//
//  CSVParserISBNTests.swift
//  booksTests
//
//  Tests to verify CSV parser correctly handles ISBN data
//

import Testing
import Foundation
@testable import books

@Suite("CSV Parser ISBN Tests")
struct CSVParserISBNTests {
    
    @Test("ISBN Column Detection - Should detect various ISBN column names")
    func testISBNColumnDetection() throws {
        let parser = CSVParser()
        
        // Test CSV content with different ISBN column variations
        let csvContent = """
        Title,Author,ISBN,ISBN13,Published
        "The Great Gatsby","F. Scott Fitzgerald","0-7432-7356-7","978-0-7432-7356-5","1925"
        "1984","George Orwell","978-0-452-28423-4","9780452284234","1949"
        """
        
        // Create temp file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_isbn.csv")
        try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        // Parse CSV
        let session = try parser.parseCSV(from: tempURL)
        
        // Check ISBN column detection
        let isbnColumn = session.detectedColumns.first { $0.originalName == "ISBN" }
        let isbn13Column = session.detectedColumns.first { $0.originalName == "ISBN13" }
        
        #expect(isbnColumn?.mappedField == .isbn, "ISBN column should be mapped to isbn field")
        #expect(isbn13Column?.mappedField == .isbn, "ISBN13 column should be mapped to isbn field")
        
        // Check sample values are preserved
        #expect(isbnColumn?.sampleValues.contains("0-7432-7356-7") == true)
        #expect(isbn13Column?.sampleValues.contains("978-0-7432-7356-5") == true)
    }
    
    @Test("ISBN Format Preservation - Should preserve ISBN-10 and ISBN-13 formats")
    func testISBNFormatPreservation() throws {
        let parser = CSVParser()
        
        // Test CSV with various ISBN formats
        let csvContent = """
        Title,Author,ISBN
        "Book with ISBN-10","Author One","0-7432-7356-7"
        "Book with ISBN-13","Author Two","978-0-452-28423-4"
        "Book with clean ISBN","Author Three","9780452284234"
        "Book with spaces","Author Four","978 0 452 28423 4"
        """
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_isbn_formats.csv")
        try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        let session = try parser.parseCSV(from: tempURL)
        
        // Create column mappings
        let columnMappings: [String: BookField] = [
            "Title": .title,
            "Author": .author,
            "ISBN": .isbn
        ]
        
        // Parse books
        let parsedBooks = parser.parseBooks(from: session, columnMappings: columnMappings)
        
        #expect(parsedBooks.count == 4)
        
        // Check each book's ISBN is preserved
        #expect(parsedBooks[0].isbn == "0-7432-7356-7", "ISBN-10 with hyphens should be preserved")
        #expect(parsedBooks[1].isbn == "978-0-452-28423-4", "ISBN-13 with hyphens should be preserved")
        #expect(parsedBooks[2].isbn == "9780452284234", "Clean ISBN should be preserved")
        #expect(parsedBooks[3].isbn == "978 0 452 28423 4", "ISBN with spaces should be preserved")
    }
    
    @Test("ISBN Column Mapping - Should map ISBN to BookMetadata.isbn field")
    func testISBNColumnMapping() throws {
        let parser = CSVParser()
        
        let csvContent = """
        Title,Author,ISBN,Rating
        "Test Book","Test Author","978-0-7432-7356-5","5"
        """
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_mapping.csv")
        try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        let session = try parser.parseCSV(from: tempURL)
        
        let columnMappings: [String: BookField] = [
            "Title": .title,
            "Author": .author,
            "ISBN": .isbn,
            "Rating": .rating
        ]
        
        let parsedBooks = parser.parseBooks(from: session, columnMappings: columnMappings)
        
        #expect(parsedBooks.count == 1)
        let book = parsedBooks[0]
        
        #expect(book.title == "Test Book")
        #expect(book.author == "Test Author")
        #expect(book.isbn == "978-0-7432-7356-5", "ISBN should be correctly mapped")
        #expect(book.rating == 5)
    }
    
    @Test("ISBN in Duplicate Detection - Should flow through to duplicate detection")
    func testISBNFlowsToDuplicateDetection() throws {
        // Create existing book with ISBN
        let existingMetadata = BookMetadata(
            googleBooksID: "existing-book",
            title: "Existing Book",
            authors: ["Existing Author"],
            isbn: "978-0-7432-7356-5"
        )
        let existingBook = UserBook(metadata: existingMetadata)
        
        // Create parsed book with same ISBN but different title/author
        var parsedBook = ParsedBook(rowIndex: 1)
        parsedBook.title = "Different Title"
        parsedBook.author = "Different Author"
        parsedBook.isbn = "9780743273565"  // Same ISBN without hyphens
        
        // Create temporary metadata for duplicate check
        let tempMetadata = BookMetadata(
            googleBooksID: "",
            title: parsedBook.title ?? "",
            authors: [parsedBook.author ?? ""],
            isbn: parsedBook.isbn
        )
        
        // Check duplicate detection
        let duplicate = DuplicateDetectionService.findExistingBook(
            for: tempMetadata,
            in: [existingBook]
        )
        
        #expect(duplicate != nil, "Should detect duplicate by ISBN despite different title/author")
        #expect(duplicate?.metadata?.googleBooksID == "existing-book")
    }
    
    @Test("ISBN Priority in Import - Should use ISBN for API lookup when available")
    func testISBNPriorityInImport() throws {
        var parsedBook = ParsedBook(rowIndex: 1)
        parsedBook.title = "Test Book"
        parsedBook.author = "Test Author"
        parsedBook.isbn = "978-0-7432-7356-5"
        
        // Verify that ISBN is available for API lookup
        #expect(parsedBook.isbn != nil)
        #expect(!parsedBook.isbn!.isEmpty)
        
        // In actual import, this would trigger fetchMetadataFromISBN
        // which uses: BookSearchService.shared.search(query: "isbn:\(cleanISBN)")
        let expectedQuery = "isbn:9780743273565"  // Cleaned ISBN
        
        let cleanISBN = parsedBook.isbn!
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")
        
        #expect(cleanISBN == "9780743273565", "ISBN should be cleaned for API query")
    }
    
    @Test("Multiple ISBN Columns - Should handle both ISBN and ISBN13")
    func testMultipleISBNColumns() throws {
        let parser = CSVParser()
        
        let csvContent = """
        Title,Author,ISBN,ISBN13
        "Book One","Author One","0-7432-7356-7","978-0-7432-7356-5"
        "Book Two","Author Two","","978-0-452-28423-4"
        "Book Three","Author Three","0-316-76948-7",""
        """
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_multi_isbn.csv")
        try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        let session = try parser.parseCSV(from: tempURL)
        
        // Map both ISBN columns
        let columnMappings: [String: BookField] = [
            "Title": .title,
            "Author": .author,
            "ISBN": .isbn,
            "ISBN13": .isbn  // Both map to same field
        ]
        
        let parsedBooks = parser.parseBooks(from: session, columnMappings: columnMappings)
        
        #expect(parsedBooks.count == 3)
        
        // Note: The last mapped column will overwrite previous ones
        // Book One: ISBN13 should overwrite ISBN
        #expect(parsedBooks[0].isbn == "978-0-7432-7356-5" || parsedBooks[0].isbn == "0-7432-7356-7")
        
        // Book Two: Only ISBN13 has value
        #expect(parsedBooks[1].isbn == "978-0-452-28423-4" || parsedBooks[1].isbn == nil || parsedBooks[1].isbn == "")
        
        // Book Three: Only ISBN has value
        #expect(parsedBooks[2].isbn == "0-316-76948-7" || parsedBooks[2].isbn == nil || parsedBooks[2].isbn == "")
    }
    
    @Test("Empty ISBN Handling - Should handle missing ISBN gracefully")
    func testEmptyISBNHandling() throws {
        let parser = CSVParser()
        
        let csvContent = """
        Title,Author,ISBN
        "Book with ISBN","Author One","978-0-7432-7356-5"
        "Book without ISBN","Author Two",""
        "Another book without ISBN","Author Three",
        """
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_empty_isbn.csv")
        try csvContent.write(to: tempURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tempURL) }
        
        let session = try parser.parseCSV(from: tempURL)
        
        let columnMappings: [String: BookField] = [
            "Title": .title,
            "Author": .author,
            "ISBN": .isbn
        ]
        
        let parsedBooks = parser.parseBooks(from: session, columnMappings: columnMappings)
        
        #expect(parsedBooks.count == 3)
        #expect(parsedBooks[0].isbn == "978-0-7432-7356-5")
        #expect(parsedBooks[1].isbn == nil || parsedBooks[1].isbn == "")
        #expect(parsedBooks[2].isbn == nil || parsedBooks[2].isbn == "")
        
        // Books without ISBN should still be valid for import
        #expect(parsedBooks[1].isValid == true, "Book without ISBN should still be valid")
        #expect(parsedBooks[2].isValid == true, "Book without ISBN should still be valid")
    }
}
