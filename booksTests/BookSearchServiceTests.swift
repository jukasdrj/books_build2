//
// UPDATED: booksTests/BookSearchServiceTests.swift
//
import Testing
import Foundation
@testable import books

@Suite("Book Search Service Tests")
struct BookSearchServiceTests {
    
    private func createTestBookMetadata(
        id: String = "test123",
        title: String = "Test Book",
        authors: [String] = ["Test Author"],
        isbn: String = "1234567890123"
    ) -> BookMetadata {
        return BookMetadata(
            googleBooksID: id,
            title: title,
            authors: authors,
            publishedDate: "2024",
            pageCount: 200,
            bookDescription: "Test description",
            imageURL: URL(string: "https://example.com/cover.jpg"),
            language: "en",
            publisher: "Test Publisher",
            isbn: isbn,
            genre: ["Technology", "Programming"]
        )
    }
    
    @Test("BookSearchService Initialization - Should create singleton")
    func testBookSearchServiceInitialization() async {
        let service = await BookSearchService.shared
        let service2 = await BookSearchService.shared
        #expect(service === service2, "BookSearchService should be a singleton")
    }
    
    @Test("Search Query - Should handle empty and whitespace queries gracefully")
    func testEmptySearchQuery() async throws {
        let service = await BookSearchService.shared
        
        // Test completely empty query
        let emptyResult = await service.search(query: "")
        switch emptyResult {
        case .success(let results):
            #expect(results.isEmpty, "Empty query should return empty results")
        case .failure:
            throw TestingError("Empty query should not fail, but return empty results")
        }
        
        // Test whitespace-only query
        let whitespaceResult = await service.search(query: "   ")
        switch whitespaceResult {
        case .success(let results):
            #expect(results.isEmpty, "Whitespace query should return empty results")
        case .failure:
            throw TestingError("Whitespace query should not fail, but return empty results")
        }
    }
    
    @Test("BookMetadata Creation - Should initialize correctly from helper")
    func testBookMetadataCreation() {
        let metadata = createTestBookMetadata()
        
        #expect(metadata.title == "Test Book")
        #expect(metadata.authors == ["Test Author"])
        #expect(metadata.googleBooksID == "test123")
        #expect(metadata.isbn == "1234567890123")
        #expect(metadata.genre.contains("Technology") == true)
        #expect(metadata.id == metadata.googleBooksID)
    }
    
    @Test("BookMetadata Creation - Should handle missing optional fields")
    func testMissingOptionalFields() {
        let metadata = BookMetadata(
            googleBooksID: "minimal123",
            title: "Minimal Book",
            authors: ["Single Author"]
        )
        
        #expect(metadata.publishedDate == nil)
        #expect(metadata.genre.isEmpty) // Default is empty array, not nil
        #expect(metadata.originalLanguage == nil)
        #expect(metadata.authorNationality == nil)
        #expect(metadata.translator == nil)
    }
    
    @Test("BookMetadata Arrays - Should handle arrays correctly")
    func testBookMetadataArrays() {
        let metadata = BookMetadata(
            googleBooksID: "array-test",
            title: "Array Test Book",
            authors: ["Author One", "Author Two"],
            genre: ["Fiction", "Mystery", "Thriller"]
        )
        
        #expect(metadata.authors.count == 2)
        #expect(metadata.authors.contains("Author One"))
        #expect(metadata.authors.contains("Author Two"))
        
        #expect(metadata.genre.count == 3)
        #expect(metadata.genre.contains("Fiction"))
        #expect(metadata.genre.contains("Mystery"))
        #expect(metadata.genre.contains("Thriller"))
    }
    
    @Test("BookMetadata Validation - Should validate fields correctly")
    func testBookMetadataValidation() {
        let metadata = BookMetadata(
            googleBooksID: "validation-test",
            title: "Valid Title",
            authors: ["Valid Author"],
            pageCount: 250
        )
        
        #expect(metadata.validateTitle() == true)
        #expect(metadata.validateAuthors() == true)
        #expect(metadata.validatePageCount() == true)
        
        // Test invalid page count
        metadata.pageCount = -10
        #expect(metadata.validatePageCount() == false)
    }
}

// TestingError moved to ErrorHandlingAndRetryLogicTests.swift to avoid duplication