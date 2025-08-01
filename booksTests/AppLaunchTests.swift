import Testing
import SwiftData
import SwiftUI
@testable import books

@Suite("App Launch Tests")
struct AppLaunchTests {
    
    private func createTestContainer() throws -> ModelContainer {
        let schema = Schema([UserBook.self, BookMetadata.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }
    
    private func createTestUserBook(
        title: String = "Test Book",
        authors: [String] = ["Test Author"],
        status: ReadingStatus = .toRead
    ) -> UserBook {
        let metadata = BookMetadata(
            googleBooksID: UUID().uuidString,
            title: title,
            authors: authors,
            publishedDate: "2024",
            pageCount: 300,
            bookDescription: "A test book description",
            language: "English",
            publisher: "Test Publisher",
            isbn: "1234567890123",
            genre: ["Fiction", "Test"],
            authorNationality: "American"
        )
        
        let userBook = UserBook(readingStatus: status, owned: true)
        userBook.metadata = metadata
        
        if status == .read {
            userBook.dateCompleted = Date()
            userBook.rating = 4
        } else if status == .reading {
            userBook.dateStarted = Calendar.current.date(byAdding: .day, value: -10, to: Date())
        }
        
        return userBook
    }
    
    @Test("App Startup - Should create ModelContainer without crashing")
    func testAppStartup() async throws {
        let schema = Schema([UserBook.self, BookMetadata.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        
        // Test that we can create a context from the container
        _ = ModelContext(container)
        
        // Verify the container has the expected schema
        #expect(container.schema.entities.count == 2)
        #expect(container.schema.entities.contains { $0.name == "UserBook" })
        #expect(container.schema.entities.contains { $0.name == "BookMetadata" })
    }
    
    @Test("ContentView Creation - Should initialize without errors")
    func testContentViewCreation() async throws {
        let container = try createTestContainer()
        let contentView = await ContentView().modelContainer(container)
        
        let hostingController = await UIHostingController(rootView: contentView)
        await #expect(hostingController.view != nil)
    }
    
    @Test("Sample Data Creation - Should add books without errors")
    func testSampleDataCreation() async throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let sampleBooks = [
            createTestUserBook(title: "The Swift Programming Language", authors: ["Apple Inc."], status: .read),
            createTestUserBook(title: "SwiftUI Fundamentals", authors: ["John Doe"], status: .reading),
            createTestUserBook(title: "iOS Development Guide", authors: ["Jane Smith"], status: .toRead)
        ]
        
        for userBook in sampleBooks {
            context.insert(userBook)
        }
        try context.save()
        
        let fetchDescriptor = FetchDescriptor<UserBook>()
        let books = try context.fetch(fetchDescriptor)
        
        #expect(books.count == 3)
        #expect(books.contains { $0.metadata?.title == "The Swift Programming Language" })
    }
    
    @Test("Enhanced Sample Data Validation - Should preserve all book properties")
    func testSampleDataWithValidation() async throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let testBook = createTestUserBook(title: "Test Validation Book", authors: ["Validation Author"], status: .reading)
        testBook.notes = "Test notes for validation"
        testBook.tags = ["validation", "test"]
        testBook.isFavorited = true
        
        context.insert(testBook)
        try context.save()
        
        let descriptor = FetchDescriptor<UserBook>()
        let savedBooks = try context.fetch(descriptor)
        #expect(savedBooks.count == 1)
        
        let savedBook = savedBooks.first!
        #expect(savedBook.metadata?.title == "Test Validation Book")
        #expect(savedBook.readingStatus == .reading)
        #expect(savedBook.notes == "Test notes for validation")
        #expect(savedBook.isFavorited == true)
        #expect(savedBook.metadata?.isbn == "1234567890123")
        #expect(savedBook.metadata?.genre.contains("Fiction") == true)
    }
    
    @Test("BookMetadata Model - Should handle comprehensive metadata")
    func testBookMetadataModel() async throws {
        let container = try createTestContainer()
        let context = ModelContext(container)
        
        let metadata = BookMetadata(
            googleBooksID: "comprehensive-test-123",
            title: "Comprehensive Metadata Test",
            authors: ["Primary Author", "Secondary Author"],
            publishedDate: "2024-01-01",
            pageCount: 450,
            bookDescription: "A comprehensive test of all metadata fields.",
            imageURL: URL(string: "https://example.com/cover.jpg"),
            language: "English",
            publisher: "Comprehensive Test Publishing",
            isbn: "9781234567890",
            genre: ["Technology", "Programming", "Software Development"]
        )
        
        let userBook = UserBook(readingStatus: .toRead)
        userBook.metadata = metadata
        
        context.insert(userBook)
        try context.save()
        
        let metadataDescriptor = FetchDescriptor<BookMetadata>()
        let savedMetadata = try context.fetch(metadataDescriptor)
        #expect(savedMetadata.count == 1)
        
        let saved = savedMetadata.first!
        #expect(saved.title == "Comprehensive Metadata Test")
        #expect(saved.genre.count == 3)
    }
}
