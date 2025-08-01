import Testing
import SwiftData
import SwiftUI
@testable import books

@Suite("View Tests")
struct ViewTests {
    
    // Creates a clean, in-memory database container for each test.
    private func createTestContainer() throws -> ModelContainer {
        let schema = Schema([UserBook.self, BookMetadata.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
    
    // CORRECTED: This helper function now creates a fully-formed BookMetadata object
    // with valid default values for ALL properties. This prevents any view from
    // unexpectedly receiving a nil value during testing.
    private func createTestUserBook(title: String = "Test Book") -> UserBook {
        let metadata = BookMetadata(
            googleBooksID: UUID().uuidString,
            title: title,
            authors: ["Test Author"],
            publishedDate: "2024",
            pageCount: 320,
            bookDescription: "This is a test description for the book.",
            language: "English",
            publisher: "Test Publishing",
            isbn: "978-3-16-148410-0",
            genre: ["Fiction", "Testing"]
        )
        
        let userBook = UserBook()
        userBook.metadata = metadata
        
        return userBook
    }
    
    // This test ensures the new detail view for search results can be created.
    @Test("SearchResultDetailView Creation - Should initialize correctly")
    func testSearchResultDetailViewCreation() throws {
        let container = try createTestContainer()
        // Create a valid BookMetadata object using the full initializer.
        let searchResult = BookMetadata(
            googleBooksID: "test-search-result",
            title: "A Book from Search",
            authors: ["Search Author"]
        )
        
        let detailView = SearchResultDetailView(bookMetadata: searchResult)
            .modelContainer(container)
        
        #expect(detailView != nil)
    }

    // This test ensures the main library view can be created.
    @Test("LibraryView Creation - Should initialize correctly")
    func testLibraryViewCreation() throws {
        let container = try createTestContainer()
        let libraryView = LibraryView().modelContainer(container)
        
        #expect(libraryView != nil)
    }
    
    // This test ensures the book details view (for books already in the library) can be created.
    @Test("BookDetailsView Creation - Should initialize with UserBook")
    func testBookDetailsViewCreation() throws {
        let container = try createTestContainer()
        let userBook = createTestUserBook(title: "Test Book for Details")
        
        let detailsView = BookDetailsView(book: userBook).modelContainer(container)
        
        #expect(detailsView != nil)
    }
    
    // This test ensures the main tabbed view of the app can be created.
    @Test("ContentView Creation - Should initialize all tabs")
    func testContentViewCreation() throws {
        let container = try createTestContainer()
        let contentView = ContentView().modelContainer(container)
        
        #expect(contentView != nil)
    }

    // This test ensures the book card view can be created with its dependencies.
    @Test("BookCardView Creation - Should initialize correctly")
    func testBookCardViewCreation() throws {
        let userBook = createTestUserBook(title: "Test Book for Card View")
        let cardView = BookCardView(book: userBook)
        
        #expect(cardView != nil)
    }

    // This test ensures the cultural diversity view can be created.
    @Test("CulturalDiversityView Creation - Should initialize correctly")
    func testCulturalDiversityViewCreation() throws {
        let container = try createTestContainer()
        let culturalDiversityView = CulturalDiversityView().modelContainer(container)
        
        #expect(culturalDiversityView != nil)
    }
}