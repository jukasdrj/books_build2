//
// NEW: booksTests/DuplicateDetectionTests.swift
//
import Testing
import Foundation
@testable import books

@Suite("Duplicate Detection Tests")
struct DuplicateDetectionTests {
    
    private func createTestBook(id: String, title: String, authors: [String], isbn: String? = nil) -> UserBook {
        let metadata = BookMetadata(
            googleBooksID: id,
            title: title,
            authors: authors,
            isbn: isbn
        )
        return UserBook(metadata: metadata)
    }
    
    @Test("Duplicate Detection by Google Books ID - Should match correctly")
    func testDuplicateDetectionByGoogleBooksID() throws {
        let existingBook = createTestBook(id: "test123", title: "Existing Book", authors: ["Author One"])
        let newMetadata = BookMetadata(
            googleBooksID: "test123", // Same ID
            title: "Different Title", // Different title
            authors: ["Different Author"] // Different author
        )
        
        let duplicate = DuplicateDetectionService.findExistingBook(for: newMetadata, in: [existingBook])
        #expect(duplicate != nil)
        #expect(duplicate?.metadata?.googleBooksID == "test123")
    }
    
    @Test("Duplicate Detection by ISBN - Should match correctly")
    func testDuplicateDetectionByISBN() throws {
        let existingBook = createTestBook(id: "book1", title: "Book One", authors: ["Author"], isbn: "1234567890")
        let newMetadata = BookMetadata(
            googleBooksID: "book2", // Different ID
            title: "Book Two", // Different title
            authors: ["Different Author"], // Different author
            isbn: "1234567890" // Same ISBN
        )
        
        let duplicate = DuplicateDetectionService.findExistingBook(for: newMetadata, in: [existingBook])
        #expect(duplicate != nil)
        #expect(duplicate?.metadata?.isbn == "1234567890")
    }
    
    @Test("Duplicate Detection by Title and Author - Should match closely similar")
    func testDuplicateDetectionByTitleAndAuthor() throws {
        let existingBook = createTestBook(id: "book1", title: "The Great Gatsby", authors: ["F. Scott Fitzgerald"])
        let newMetadata = BookMetadata(
            googleBooksID: "book2",
            title: "The Great Gatsby", // Exact match
            authors: ["F. Scott Fitzgerald"] // Exact match
        )
        
        let duplicate = DuplicateDetectionService.findExistingBook(for: newMetadata, in: [existingBook])
        #expect(duplicate != nil)
    }
    
    @Test("No Duplicate Detection - Should not match different books")
    func testNoDuplicateDetection() throws {
        let existingBook = createTestBook(id: "book1", title: "Book One", authors: ["Author One"])
        let newMetadata = BookMetadata(
            googleBooksID: "book2",
            title: "Completely Different Book",
            authors: ["Completely Different Author"]
        )
        
        let duplicate = DuplicateDetectionService.findExistingBook(for: newMetadata, in: [existingBook])
        #expect(duplicate == nil)
    }
    
    @Test("ISBN Cleaning - Should normalize ISBNs correctly")
    func testISBNCleaning() throws {
        let existingBook = createTestBook(id: "book1", title: "Test Book", authors: ["Test Author"], isbn: "978-3-16-148410-0")
        let newMetadata = BookMetadata(
            googleBooksID: "book2",
            title: "Different Title",
            authors: ["Different Author"],
            isbn: "9783161484100" // Same ISBN without hyphens
        )
        
        let duplicate = DuplicateDetectionService.findExistingBook(for: newMetadata, in: [existingBook])
        #expect(duplicate != nil, "Should match ISBNs regardless of formatting")
    }
}