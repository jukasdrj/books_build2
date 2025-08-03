//
// UPDATED: booksTests/ModelContainerTests.swift
//
import Testing
import SwiftData
import Foundation
@testable import books

@Suite("ModelContainer Tests")
struct ModelContainerTests {
    
    private func createTestContainer() throws -> ModelContainer {
        let schema = Schema([UserBook.self, BookMetadata.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }
    
    private func createComprehensiveTestUserBook(
        title: String = "Comprehensive Test Book",
        authors: [String] = ["Test Author"]
    ) -> UserBook {
        let metadata = BookMetadata(
            googleBooksID: UUID().uuidString,
            title: title,
            authors: authors,
            publishedDate: "2024-01-01",
            pageCount: 400,
            bookDescription: "A comprehensive test book.",
            imageURL: URL(string: "https://example.com/cover.jpg"),
            language: "en",
            publisher: "Test Publisher",
            isbn: "9781234567890",
            genre: ["Fiction", "Test", "Programming"],
            originalLanguage: "Klingon",
            authorNationality: "Qo'noS",
            translator: "Worf"
        )
        
        let userBook = UserBook(readingStatus: .reading, metadata: metadata)
        userBook.rating = 4
        userBook.tags = ["science-fiction", "test-book"]
        userBook.notes = "Great book for testing!"
        return userBook
    }

    @Test("Comprehensive Model Persistence - Should save and retrieve all fields")
    func testComplexDataPersistence() async throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let userBook = createComprehensiveTestUserBook()
        context.insert(userBook)
        try context.save()
        
        let descriptor = FetchDescriptor<UserBook>()
        let books = try context.fetch(descriptor)
        
        #expect(books.count == 1)
        let savedBook = books.first!
        let savedMetadata = savedBook.metadata
        
        #expect(savedMetadata?.title == "Comprehensive Test Book")
        #expect(savedMetadata?.genre.contains("Fiction") == true)
        #expect(savedMetadata?.originalLanguage == "Klingon")
        #expect(savedMetadata?.authorNationality == "Qo'noS")
        #expect(savedMetadata?.translator == "Worf")
        #expect(savedBook.rating == 4)
        #expect(savedBook.tags.contains("science-fiction"))
        #expect(savedBook.notes == "Great book for testing!")
    }
    
    @Test("Relationship Persistence - Should maintain UserBook-BookMetadata relationship")
    func testRelationshipPersistence() async throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let metadata = BookMetadata(
            googleBooksID: "relationship-test",
            title: "Relationship Test",
            authors: ["Relationship Author"]
        )
        
        let userBook1 = UserBook(readingStatus: .read, metadata: metadata)
        let userBook2 = UserBook(readingStatus: .toRead, metadata: metadata)
        
        context.insert(userBook1)
        context.insert(userBook2)
        try context.save()
        
        let userBookDescriptor = FetchDescriptor<UserBook>()
        let savedUserBooks = try context.fetch(userBookDescriptor)
        
        #expect(savedUserBooks.count == 2)
        
        let metadataDescriptor = FetchDescriptor<BookMetadata>()
        let savedMetadata = try context.fetch(metadataDescriptor)
        
        #expect(savedMetadata.count == 1)
        #expect(savedMetadata.first?.userBooks.count == 2)
    }
    
    @Test("Reading Status Auto-Dating - Should set dates correctly")
    func testReadingStatusAutoDating() async throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let metadata = BookMetadata(
            googleBooksID: "dating-test",
            title: "Dating Test",
            authors: ["Dating Author"]
        )
        
        let userBook = UserBook(readingStatus: .toRead, metadata: metadata)
        print("Test: After init (.toRead), dateStarted: \(String(describing: userBook.dateStarted))")
        #expect(userBook.dateStarted == nil) // Line 122
        #expect(userBook.dateCompleted == nil)
        
        // Change to reading
        userBook.readingStatus = .reading
        print("Test: After changing to .reading, dateStarted: \(String(describing: userBook.dateStarted))")
        #expect(userBook.dateStarted != nil) // Line 127 (previously reported as failing, let's confirm)
        #expect(userBook.dateCompleted == nil)
        
        // Change to read
        userBook.readingStatus = .read
        print("Test: After changing to .read, dateStarted: \(String(describing: userBook.dateStarted))")
        #expect(userBook.dateStarted != nil)
        #expect(userBook.dateCompleted != nil)
        
        context.insert(userBook)
        try context.save()
        
        let descriptor = FetchDescriptor<UserBook>()
        let savedBooks = try context.fetch(descriptor)
        let savedBook = savedBooks.first!
        
        print("Test: After save and fetch, savedBook.dateStarted: \(String(describing: savedBook.dateStarted))")
        #expect(savedBook.dateStarted != nil)
        #expect(savedBook.dateCompleted != nil)
    }
}