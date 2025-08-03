//
// UPDATED: booksTests/ViewTests.swift
//
import Testing
import SwiftData
import SwiftUI
@testable import books

@Suite("View Tests")
struct ViewTests {
    
    private func createTestContainer() throws -> ModelContainer {
        let schema = Schema([UserBook.self, BookMetadata.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
    
    private func createTestUserBook(title: String = "Test Book") -> UserBook {
        let metadata = BookMetadata(
            googleBooksID: UUID().uuidString,
            title: title,
            authors: ["Test Author"],
            publishedDate: "2024",
            pageCount: 320,
            bookDescription: "This is a test description for the book.",
            language: "en",
            publisher: "Test Publishing",
            isbn: "978-3-16-148410-0",
            genre: ["Fiction", "Testing"]
        )
        
        let userBook = UserBook(metadata: metadata)
        return userBook
    }
    
    @Test("SearchResultDetailView Creation - Should initialize correctly")
    func testSearchResultDetailViewCreation() throws {
        let container = try createTestContainer()
        let searchResult = BookMetadata(
            googleBooksID: "test-search-result",
            title: "A Book from Search",
            authors: ["Search Author"]
        )
        
        let detailView = SearchResultDetailView(bookMetadata: searchResult)
            .modelContainer(container)
        
        #expect(detailView != nil)
    }

    @Test("LibraryView Creation - Should initialize correctly")
    func testLibraryViewCreation() throws {
        let container = try createTestContainer()
        let libraryView = LibraryView().modelContainer(container)
        
        #expect(libraryView != nil)
    }
    
    @Test("WishlistLibraryView Creation - Should initialize correctly")
    func testWishlistLibraryViewCreation() throws {
        let container = try createTestContainer()
        let wishlistView = WishlistLibraryView().modelContainer(container)
        
        #expect(wishlistView != nil)
    }
    
    @Test("BookDetailsView Creation - Should initialize with UserBook")
    func testBookDetailsViewCreation() throws {
        let container = try createTestContainer()
        let userBook = createTestUserBook(title: "Test Book for Details")
        
        let detailsView = BookDetailsView(book: userBook).modelContainer(container)
        
        #expect(detailsView != nil)
    }
    
    @Test("ContentView Creation - Should initialize all tabs")
    func testContentViewCreation() throws {
        let container = try createTestContainer()
        let contentView = ContentView().modelContainer(container)
        
        #expect(contentView != nil)
    }

    @Test("BookCardView Creation - Should initialize correctly")
    func testBookCardViewCreation() throws {
        let userBook = createTestUserBook(title: "Test Book for Card View")
        let cardView = BookCardView(book: userBook)
        
        #expect(cardView != nil)
    }

    @Test("CulturalDiversityView Creation - Should initialize correctly")
    func testCulturalDiversityViewCreation() throws {
        let container = try createTestContainer()
        let culturalDiversityView = CulturalDiversityView().modelContainer(container)
        
        #expect(culturalDiversityView != nil)
    }
    
    @Test("SearchView Creation - Should initialize correctly")
    func testSearchViewCreation() throws {
        let container = try createTestContainer()
        let searchView = SearchView().modelContainer(container)
        
        #expect(searchView != nil)
    }
    
    @Test("StatsView Creation - Should initialize correctly")
    func testStatsViewCreation() throws {
        let container = try createTestContainer()
        let statsView = StatsView().modelContainer(container)
        
        #expect(statsView != nil)
    }
    
    @Test("BookMetadata Hashable - Should provide stable hashing")
    func testBookMetadataHashable() throws {
        let metadata1 = BookMetadata(
            googleBooksID: "test-id-123",
            title: "Test Book",
            authors: ["Test Author"]
        )
        
        let metadata2 = BookMetadata(
            googleBooksID: "test-id-123",
            title: "Different Title", // Different title but same ID
            authors: ["Different Author"]
        )
        
        let metadata3 = BookMetadata(
            googleBooksID: "different-id-456",
            title: "Test Book", // Same title but different ID
            authors: ["Test Author"]
        )
        
        // Same googleBooksID should be equal and have same hash
        #expect(metadata1 == metadata2)
        #expect(metadata1.hashValue == metadata2.hashValue)
        
        // Different googleBooksID should not be equal
        #expect(metadata1 != metadata3)
        #expect(metadata2 != metadata3)
    }
    
    @Test("BookFormat Enum - Should have correct cases and icons")
    func testBookFormatEnum() throws {
        let allCases = BookFormat.allCases
        #expect(allCases.count == 3)
        
        #expect(BookFormat.physical.rawValue == "Physical")
        #expect(BookFormat.ebook.rawValue == "E-book")
        #expect(BookFormat.audiobook.rawValue == "Audiobook")
        
        #expect(BookFormat.physical.icon == "book.closed")
        #expect(BookFormat.ebook.icon == "ipad")
        #expect(BookFormat.audiobook.icon == "headphones")
    }
    
    @Test("CulturalRegion Enum - Should have correct properties")
    func testCulturalRegionEnum() throws {
        let allCases = CulturalRegion.allCases
        #expect(allCases.count == 10)
        
        #expect(CulturalRegion.africa.rawValue == "Africa")
        #expect(CulturalRegion.asia.rawValue == "Asia")
        #expect(CulturalRegion.indigenous.rawValue == "Indigenous")
        
        // Test that each region has an icon and color
        for region in allCases {
            #expect(!region.icon.isEmpty)
            #expect(region.color != nil)
        }
    }
}