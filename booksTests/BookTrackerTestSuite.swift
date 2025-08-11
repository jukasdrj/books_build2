import XCTest
import SwiftData
import SwiftUI
@testable import books

/// Base test suite providing common SwiftData test infrastructure
/// Follows modern Swift 6 concurrency patterns and SwiftData best practices
@MainActor
class BookTrackerTestSuite: XCTestCase {
    var testModelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory container for testing to avoid persistence between tests
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        testModelContainer = try ModelContainer(
            for: UserBook.self, BookMetadata.self,
            configurations: config
        )
        modelContext = testModelContainer.mainContext
    }
    
    override func tearDown() async throws {
        // Clean up test data
        try deleteAllTestData()
        
        testModelContainer = nil
        modelContext = nil
        try await super.tearDown()
    }
    
    // MARK: - Test Data Management
    
    /// Removes all test data from the model context
    private func deleteAllTestData() throws {
        let userBookDescriptor = FetchDescriptor<UserBook>()
        let userBooks = try modelContext.fetch(userBookDescriptor)
        for book in userBooks {
            modelContext.delete(book)
        }
        
        let metadataDescriptor = FetchDescriptor<BookMetadata>()
        let metadata = try modelContext.fetch(metadataDescriptor)
        for meta in metadata {
            modelContext.delete(meta)
        }
        
        try modelContext.save()
    }
    
    /// Creates a test UserBook with default values that can be overridden
    func createTestUserBook(
        title: String = "Test Book",
        author: String = "Test Author",
        isbn: String? = "1234567890",
        readingStatus: ReadingStatus = .toRead,
        rating: Int? = nil,
        culturalRegion: CulturalRegion? = nil,
        insert: Bool = true
    ) -> UserBook {
        let metadata = BookMetadata(
            googleBooksID: "test-\(UUID().uuidString)",
            title: title,
            authors: [author],
            publishedDate: "2024",
            pageCount: 300,
            bookDescription: "A test book for unit testing",
            language: "en",
            publisher: "Test Publisher",
            isbn: isbn,
            genre: ["Fiction"]
        )
        
        if let culturalRegion {
            metadata.culturalRegion = culturalRegion
        }
        
        let userBook = UserBook(
            readingStatus: readingStatus,
            rating: rating,
            metadata: metadata
        )
        
        if insert {
            modelContext.insert(metadata)
            modelContext.insert(userBook)
        }
        
        return userBook
    }
    
    /// Creates test metadata with cultural diversity fields
    func createTestBookMetadata(
        title: String = "Test Book",
        authors: [String] = ["Test Author"],
        culturalRegion: CulturalRegion? = nil,
        originalLanguage: String? = nil,
        authorNationality: String? = nil,
        insert: Bool = true
    ) -> BookMetadata {
        let metadata = BookMetadata(
            googleBooksID: "metadata-\(UUID().uuidString)",
            title: title,
            authors: authors,
            publishedDate: "2024",
            pageCount: 250,
            bookDescription: "Test metadata for cultural diversity testing",
            language: "en",
            publisher: "Test Publisher",
            isbn: "\(Int.random(in: 1000000000...9999999999))",
            genre: ["Fiction"],
            originalLanguage: originalLanguage,
            authorNationality: authorNationality,
            culturalRegion: culturalRegion
        )
        
        if insert {
            modelContext.insert(metadata)
        }
        
        return metadata
    }
    
    /// Saves the model context and handles errors appropriately
    func saveContext() throws {
        try modelContext.save()
    }
    
    /// Fetches all UserBooks from the test context
    func fetchAllUserBooks() throws -> [UserBook] {
        let descriptor = FetchDescriptor<UserBook>()
        return try modelContext.fetch(descriptor)
    }
    
    /// Fetches all BookMetadata from the test context
    func fetchAllBookMetadata() throws -> [BookMetadata] {
        let descriptor = FetchDescriptor<BookMetadata>()
        return try modelContext.fetch(descriptor)
    }
}

// MARK: - Test Data Generators

extension BookTrackerTestSuite {
    
    /// Generates a set of diverse books for cultural diversity testing
    func createDiverseBookCollection() -> [UserBook] {
        let diverseBooks = [
            createTestUserBook(
                title: "Things Fall Apart",
                author: "Chinua Achebe",
                culturalRegion: .africa,
                insert: false
            ),
            createTestUserBook(
                title: "One Hundred Years of Solitude",
                author: "Gabriel García Márquez",
                culturalRegion: .southAmerica,
                insert: false
            ),
            createTestUserBook(
                title: "Norwegian Wood",
                author: "Haruki Murakami",
                culturalRegion: .asia,
                insert: false
            ),
            createTestUserBook(
                title: "Pride and Prejudice",
                author: "Jane Austen",
                culturalRegion: .europe,
                insert: false
            ),
            createTestUserBook(
                title: "The Joy Luck Club",
                author: "Amy Tan",
                culturalRegion: .northAmerica,
                insert: false
            )
        ]
        
        // Insert all books and their metadata
        for book in diverseBooks {
            if let metadata = book.metadata {
                modelContext.insert(metadata)
            }
            modelContext.insert(book)
        }
        
        return diverseBooks
    }
    
    /// Creates a collection of books with various reading statuses
    func createVariousStatusBooks() -> [UserBook] {
        let books = [
            createTestUserBook(title: "Completed Book", readingStatus: .read, rating: 5, insert: false),
            createTestUserBook(title: "Currently Reading", readingStatus: .reading, insert: false),
            createTestUserBook(title: "Want to Read", readingStatus: .toRead, insert: false),
            createTestUserBook(title: "Did Not Finish", readingStatus: .dnf, insert: false)
        ]
        
        for book in books {
            if let metadata = book.metadata {
                modelContext.insert(metadata)
            }
            modelContext.insert(book)
        }
        
        return books
    }
}