//
// UPDATED: booksTests/IntegrationTests.swift
//
import Testing
import SwiftData
import Foundation
@testable import books

@Suite("Integration Tests")
struct IntegrationTests {

    private func createTestContainer() throws -> ModelContainer {
        let schema = Schema([UserBook.self, BookMetadata.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private func createTestBook(title: String, authors: [String], status: ReadingStatus) -> UserBook {
        let metadata = BookMetadata(
            googleBooksID: UUID().uuidString,
            title: title,
            authors: authors
        )
        let userBook = UserBook(readingStatus: status, metadata: metadata)
        return userBook
    }

    @Test("Adding and Deleting a Book - Should update library correctly")
    func testAddAndDeleteBook() async throws {
        let container = try createTestContainer()
        let context = ModelContext(container)

        var fetchedBooks = try context.fetch(FetchDescriptor<UserBook>())
        #expect(fetchedBooks.isEmpty)

        let newBook = createTestBook(title: "Integration Test Book", authors: ["QA Author"], status: .reading)
        context.insert(newBook)
        try context.save()

        fetchedBooks = try context.fetch(FetchDescriptor<UserBook>())
        #expect(fetchedBooks.count == 1)
        #expect(fetchedBooks.first?.metadata?.title == "Integration Test Book")

        if let bookToDelete = fetchedBooks.first {
            context.delete(bookToDelete)
            try context.save()
        }

        fetchedBooks = try context.fetch(FetchDescriptor<UserBook>())
        #expect(fetchedBooks.isEmpty)
    }

    @Test("Search and Add to Wishlist - Should function end-to-end")
    func testSearchAndAddToWishlist() async throws {
        let container = try createTestContainer()
        let context = ModelContext(container)

        let searchResultMetadata = BookMetadata(
            googleBooksID: "search-result-123",
            title: "A Searched Book",
            authors: ["API Author"],
            genre: ["Fantasy"]
        )
        
        let userBook = UserBook(onWishlist: true, metadata: searchResultMetadata)
        
        context.insert(userBook)
        try context.save()

        let allBooks = try context.fetch(FetchDescriptor<UserBook>())
        let wishlistBooks = allBooks.filter { $0.onWishlist == true }

        #expect(wishlistBooks.count == 1, "One book should be on the wishlist")
        #expect(wishlistBooks.first?.metadata?.title == "A Searched Book")
        #expect(wishlistBooks.first?.onWishlist == true)
    }
    
    @Test("Adding Book Auto-navigates to EditBookDetails - Should trigger navigation")
    func testAddBookAutoNavigation() async throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let searchResultMetadata = BookMetadata(
            googleBooksID: "auto-nav-test-123",
            title: "Navigation Test Book",
            authors: ["Navigation Author"],
            genre: ["Testing"]
        )
        
        // Simulate adding book to library (not wishlist)
        let userBook = UserBook(readingStatus: .reading, onWishlist: false, metadata: searchResultMetadata)
        
        context.insert(userBook)
        try context.save()
        
        let allBooks = try context.fetch(FetchDescriptor<UserBook>())
        let libraryBooks = allBooks.filter { !$0.onWishlist }
        
        #expect(libraryBooks.count == 1, "One book should be in the library")
        #expect(libraryBooks.first?.metadata?.title == "Navigation Test Book")
        #expect(libraryBooks.first?.readingStatus == .reading, "Book should have reading status")
    }
    
    @Test("Book Duplicate Detection - Should identify duplicates correctly")
    func testBookDuplicateDetection() async throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let metadata1 = BookMetadata(
            googleBooksID: "duplicate-test-1",
            title: "Duplicate Test Book",
            authors: ["Duplicate Author"],
            isbn: "1234567890"
        )
        
        let metadata2 = BookMetadata(
            googleBooksID: "duplicate-test-2", // Different ID
            title: "Duplicate Test Book", // Same title
            authors: ["Duplicate Author"], // Same author
            isbn: "1234567890" // Same ISBN
        )
        
        let userBook1 = UserBook(readingStatus: .read, metadata: metadata1)
        context.insert(userBook1)
        try context.save()
        
        let allBooks = try context.fetch(FetchDescriptor<UserBook>())
        
        // Test duplicate detection
        let duplicate = DuplicateDetectionService.findExistingBook(for: metadata2, in: allBooks)
        #expect(duplicate != nil, "Should detect duplicate by ISBN")
        #expect(duplicate?.metadata?.googleBooksID == "duplicate-test-1")
    }
    
    @Test("Reading Progress Tracking - Should track progress correctly")
    func testReadingProgressTracking() async throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let metadata = BookMetadata(
            googleBooksID: "progress-test",
            title: "Progress Test Book",
            authors: ["Progress Author"],
            pageCount: 300
        )
        
        let userBook = UserBook(readingStatus: .reading, metadata: metadata)
        userBook.currentPage = 75
        userBook.updateReadingProgress()
        
        #expect(userBook.readingProgress == 0.25, "Should be 25% complete")
        
        userBook.addReadingSession(minutes: 60, pagesRead: 25)
        #expect(userBook.currentPage == 100)
        #expect(userBook.totalReadingTimeMinutes == 60)
        #expect(userBook.readingSessions.count == 1)
        
        context.insert(userBook)
        try context.save()
        
        let savedBooks = try context.fetch(FetchDescriptor<UserBook>())
        let savedBook = savedBooks.first!
        
        #expect(savedBook.currentPage == 100)
        #expect(savedBook.totalReadingTimeMinutes == 60)
        #expect(savedBook.readingSessions.count == 1)
    }
}