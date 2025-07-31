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
        
        // Test mixed whitespace query
        let mixedWhitespaceResult = await service.search(query: " \t \n ")
        switch mixedWhitespaceResult {
        case .success(let results):
            #expect(results.isEmpty, "Mixed whitespace query should return empty results")
        case .failure:
            throw TestingError("Mixed whitespace query should not fail, but return empty results")
        }
    }
    
    @Test("BookMetadata Creation - Should initialize correctly from helper")
    func testBookMetadataCreation() {
        let metadata = createTestBookMetadata()
        
        #expect(metadata.title == "Test Book")
        #expect(metadata.authors == ["Test Author"])
        #expect(metadata.googleBooksID == "test123")
        #expect(metadata.isbn == "1234567890123")
        #expect(metadata.genre?.contains("Technology") == true)
    }
    
    @Test("BookMetadata Creation - Should handle missing optional fields")
    func testMissingOptionalFields() {
        let metadata = BookMetadata(
            googleBooksID: "minimal123",
            title: "Minimal Book",
            authors: ["Single Author"]
        )
        
        #expect(metadata.publishedDate == nil)
        #expect(metadata.genre == nil)
        #expect(metadata.originalLanguage == nil)
    }
    
    @Test("BookMetadata Identifiable Conformance - Should use googleBooksID as id")
    func testBookMetadataIdentifiable() {
        let metadata = createTestBookMetadata(id: "unique-test-id")
        #expect(metadata.id == "unique-test-id")
        #expect(metadata.id == metadata.googleBooksID)
    }
}

// Custom error for clearer test failures
struct TestingError: Error, CustomStringConvertible {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
    
    var description: String {
        return message
    }
}