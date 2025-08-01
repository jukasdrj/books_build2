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
            language: "English",
            publisher: "Test Publisher",
            isbn: "9781234567890",
            genre: ["Fiction", "Test", "Programming"],
            originalLanguage: "Klingon",
            authorNationality: "Qo'noS",
            translator: "Worf"
        )
        
        let userBook = UserBook(readingStatus: .reading)
        userBook.metadata = metadata
        userBook.rating = 4
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
    }
}