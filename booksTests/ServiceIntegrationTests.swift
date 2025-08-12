import XCTest
import SwiftData
@testable import books

/// Integration tests for service interactions using modern Swift patterns
@MainActor
final class ServiceIntegrationTests: BookTrackerTestSuite {
    
    var mockBookSearchService: MockBookSearchService!
    var mockImageCache: MockImageCache!
    var mockHapticFeedback: MockHapticFeedback!
    
    override func setUp() async throws {
        try await super.setUp()
        
        mockBookSearchService = MockBookSearchService()
        mockImageCache = MockImageCache()
        mockHapticFeedback = MockHapticFeedback()
    }
    
    override func tearDown() async throws {
        mockBookSearchService = nil
        mockImageCache = nil
        mockHapticFeedback = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Book Search and Addition Integration
    
    func testBookSearchToLibraryAddition() async throws {
        // Setup mock search result
        let searchResult = BookSearchResult(
            googleBooksID: "test-google-id",
            title: "Integration Test Book",
            authors: ["Integration Author"],
            publishedDate: "2024",
            description: "A book for testing integration",
            pageCount: 250,
            categories: ["Fiction"],
            imageLinks: BookImageLinks(
                smallThumbnail: "https://example.com/small.jpg",
                thumbnail: "https://example.com/thumb.jpg"
            ),
            language: "en",
            previewLink: "https://books.google.com/preview",
            infoLink: "https://books.google.com/info"
        )
        
        mockBookSearchService.searchBooksResult = [searchResult]
        
        // Perform search
        let searchResults = try await mockBookSearchService.searchBooks(query: "integration test")
        XCTAssertEqual(searchResults.count, 1)
        XCTAssertEqual(mockBookSearchService.searchCallCount, 1)
        
        // Convert search result to BookMetadata
        let bookMetadata = BookMetadata(
            googleBooksID: searchResult.googleBooksID,
            title: searchResult.title,
            authors: searchResult.authors,
            publishedDate: searchResult.publishedDate,
            pageCount: searchResult.pageCount,
            bookDescription: searchResult.description,
            imageURL: searchResult.imageLinks?.thumbnail.flatMap(URL.init),
            language: searchResult.language,
            previewLink: searchResult.previewLink.flatMap(URL.init),
            infoLink: searchResult.infoLink.flatMap(URL.init),
            genre: searchResult.categories
        )
        
        // Add to user's library
        let userBook = UserBook(
            readingStatus: .toRead,
            metadata: bookMetadata
        )
        
        modelContext.insert(bookMetadata)
        modelContext.insert(userBook)
        try saveContext()
        
        // Verify integration
        let libraryBooks = try fetchAllUserBooks()
        XCTAssertEqual(libraryBooks.count, 1)
        XCTAssertEqual(libraryBooks.first?.metadata?.title, "Integration Test Book")
    }
    
    // MARK: - ISBN Lookup Integration
    
    func testISBNLookupToBookCreation() async throws {
        let testISBN = "9780143127741"
        
        // Setup mock ISBN lookup result
        let mockMetadata = BookMetadata(
            googleBooksID: "isbn-lookup-test",
            title: "ISBN Lookup Book",
            authors: ["ISBN Author"],
            publishedDate: "2023",
            pageCount: 300,
            bookDescription: "Found via ISBN lookup",
            language: "en",
            isbn: testISBN
        )
        
        let lookupResult = ISBNLookupResult(
            isbn: testISBN,
            metadata: mockMetadata,
            success: true,
            error: nil,
            responseTime: 0.5
        )
        
        mockConcurrentLookupService.singleLookupResult = lookupResult
        
        // Perform ISBN lookup
        let result = await mockConcurrentLookupService.lookupSingleISBN(testISBN)
        
        XCTAssertTrue(result.success)
        XCTAssertNotNil(result.metadata)
        XCTAssertEqual(result.isbn, testISBN)
        
        // Create UserBook from lookup result
        if let metadata = result.metadata {
            let userBook = UserBook(
                readingStatus: .toRead,
                metadata: metadata
            )
            
            modelContext.insert(metadata)
            modelContext.insert(userBook)
            try saveContext()
            
            let libraryBooks = try fetchAllUserBooks()
            XCTAssertEqual(libraryBooks.count, 1)
            XCTAssertEqual(libraryBooks.first?.metadata?.isbn, testISBN)
        }
    }
    
    func testBatchISBNLookupIntegration() async throws {
        let testISBNs = [
            "9780143127741",
            "9780525520344", 
            "9780374280109"
        ]
        
        // Setup mock batch results
        let mockResults = testISBNs.enumerated().map { index, isbn in
            ISBNLookupResult(
                isbn: isbn,
                metadata: BookMetadata(
                    googleBooksID: "batch-\(index)",
                    title: "Batch Book \(index + 1)",
                    authors: ["Batch Author \(index + 1)"],
                    publishedDate: "2024",
                    isbn: isbn
                ),
                success: true,
                error: nil,
                responseTime: Double.random(in: 0.1...1.0)
            )
        }
        
        mockConcurrentLookupService.lookupResults = mockResults
        
        // Perform batch lookup
        let results = await mockConcurrentLookupService.lookupMultipleISBNs(testISBNs)
        
        XCTAssertEqual(results.count, testISBNs.count)
        XCTAssertEqual(mockConcurrentLookupService.lookupCallCount, 1)
        
        // Process results and add to library
        for result in results where result.success {
            if let metadata = result.metadata {
                let userBook = UserBook(
                    readingStatus: .toRead,
                    metadata: metadata
                )
                
                modelContext.insert(metadata)
                modelContext.insert(userBook)
            }
        }
        
        try saveContext()
        
        let libraryBooks = try fetchAllUserBooks()
        XCTAssertEqual(libraryBooks.count, testISBNs.count)
    }
    
    // MARK: - Image Cache Integration
    
    func testImageCacheWithBookCovers() async throws {
        let coverURL = "https://books.google.com/covers/test.jpg"
        let testImage = UIImage(systemName: "book.fill")!
        
        // Cache an image
        await mockImageCache.cacheImage(testImage, for: coverURL)
        
        // Verify cache hit
        let cachedImage = await mockImageCache.image(for: coverURL)
        XCTAssertNotNil(cachedImage)
        XCTAssertEqual(mockImageCache.cacheAccessCount, 1)
        
        // Verify cache size
        let cacheSize = await mockImageCache.cacheSize()
        XCTAssertEqual(cacheSize, 1)
        
        // Test cache miss
        let missingImage = await mockImageCache.image(for: "https://nonexistent.com/image.jpg")
        XCTAssertNil(missingImage)
        XCTAssertEqual(mockImageCache.cacheAccessCount, 2)
    }
    
    // MARK: - Reading Status Transitions with Haptic Feedback
    
    func testReadingStatusWithHapticIntegration() async throws {
        let userBook = createTestUserBook(readingStatus: .toRead)
        
        // Transition to reading
        userBook.readingStatus = .reading
        mockHapticFeedback.bookMarkedAsRead() // This would normally be triggered by the model
        
        XCTAssertEqual(userBook.readingStatus, .reading)
        
        // Transition to read
        userBook.readingStatus = .read
        mockHapticFeedback.bookMarkedAsRead()
        
        XCTAssertEqual(userBook.readingStatus, .read)
        XCTAssertEqual(userBook.readingProgress, 1.0)
        XCTAssertEqual(mockHapticFeedback.readFeedbackCount, 2)
    }
    
    func testRatingChangeWithHapticFeedback() async throws {
        let userBook = createTestUserBook()
        
        userBook.rating = 5
        mockHapticFeedback.ratingChanged()
        
        XCTAssertEqual(userBook.rating, 5)
        XCTAssertEqual(mockHapticFeedback.ratingChangedCount, 1)
    }
    
    // MARK: - Error Handling Integration
    
    func testSearchErrorHandling() async throws {
        mockBookSearchService.shouldThrowError = true
        
        do {
            _ = try await mockBookSearchService.searchBooks(query: "error test")
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is MockError)
            mockHapticFeedback.errorOccurred()
            XCTAssertEqual(mockHapticFeedback.errorCount, 1)
        }
    }
    
    func testISBNLookupErrorRecovery() async throws {
        let validISBN = "9780143127741"
        let invalidISBN = "invalid-isbn"
        
        // Setup mixed results
        let mixedResults = [
            ISBNLookupResult(
                isbn: validISBN,
                metadata: BookMetadata(
                    googleBooksID: "valid-result",
                    title: "Valid Book",
                    authors: ["Valid Author"],
                    publishedDate: "2024"
                ),
                success: true,
                error: nil,
                responseTime: 0.3
            ),
            ISBNLookupResult(
                isbn: invalidISBN,
                metadata: nil,
                success: false,
                error: NSError(domain: "TestError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Book not found"]),
                responseTime: 0.1
            )
        ]
        
        mockConcurrentLookupService.lookupResults = mixedResults
        
        let results = await mockConcurrentLookupService.lookupMultipleISBNs([validISBN, invalidISBN])
        
        let successfulResults = results.filter { $0.success }
        let failedResults = results.filter { !$0.success }
        
        XCTAssertEqual(successfulResults.count, 1)
        XCTAssertEqual(failedResults.count, 1)
        
        // Only create books for successful lookups
        for result in successfulResults {
            if let metadata = result.metadata {
                let userBook = UserBook(metadata: metadata)
                modelContext.insert(metadata)
                modelContext.insert(userBook)
            }
        }
        
        try saveContext()
        
        let libraryBooks = try fetchAllUserBooks()
        XCTAssertEqual(libraryBooks.count, 1)
        XCTAssertEqual(libraryBooks.first?.metadata?.title, "Valid Book")
    }
    
    // MARK: - Performance Integration Tests
    
    func testConcurrentOperationsPerformance() async throws {
        let startTime = Date()
        
        // Simulate concurrent operations
        async let searchTask = mockBookSearchService.searchBooks(query: "performance test")
        async let isbnTask = mockConcurrentLookupService.lookupMultipleISBNs(["123", "456", "789"])
        async let cacheTask = mockImageCache.image(for: "https://example.com/image.jpg")
        
        // Wait for all operations to complete
        let (searchResults, isbnResults, cachedImage) = try await (searchTask, isbnTask, cacheTask)
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Verify operations completed
        XCTAssertNotNil(searchResults)
        XCTAssertNotNil(isbnResults)
        // cachedImage can be nil for cache miss
        
        // Performance should be reasonable (under 1 second for mocked operations)
        XCTAssertLessThan(duration, 1.0)
    }
    
    // MARK: - Data Consistency Integration
    
    func testDataConsistencyAcrossServices() async throws {
        let googleBooksID = "consistency-test-id"
        let isbn = "9780143127741"
        
        // Create metadata from search service
        let searchMetadata = BookMetadata(
            googleBooksID: googleBooksID,
            title: "Consistency Test Book",
            authors: ["Test Author"],
            publishedDate: "2024",
            pageCount: 250,
            bookDescription: "Testing data consistency",
            language: "en",
            isbn: isbn
        )
        
        // Create the same book via ISBN lookup
        let isbnMetadata = BookMetadata(
            googleBooksID: googleBooksID, // Same ID
            title: "Consistency Test Book", // Same data
            authors: ["Test Author"],
            publishedDate: "2024",
            pageCount: 250,
            bookDescription: "Testing data consistency",
            language: "en",
            isbn: isbn
        )
        
        // Verify they represent the same book
        XCTAssertEqual(searchMetadata.googleBooksID, isbnMetadata.googleBooksID)
        XCTAssertEqual(searchMetadata.title, isbnMetadata.title)
        XCTAssertEqual(searchMetadata.isbn, isbnMetadata.isbn)
        
        // Only insert one copy to avoid duplicates
        modelContext.insert(searchMetadata)
        
        let userBook = UserBook(metadata: searchMetadata)
        modelContext.insert(userBook)
        
        try saveContext()
        
        let libraryBooks = try fetchAllUserBooks()
        XCTAssertEqual(libraryBooks.count, 1)
    }
    
    // MARK: - Memory Management Integration
    
    func testMemoryManagementWithLargeDataSets() async throws {
        let largeISBNList = (0..<100).map { "978012345\(String(format: "%04d", $0))" }
        
        // Simulate processing large amounts of data
        let results = await mockConcurrentLookupService.lookupMultipleISBNs(largeISBNList)
        
        XCTAssertEqual(results.count, largeISBNList.count)
        
        // Clear cache to free memory
        await mockImageCache.clearCache()
        let cacheSize = await mockImageCache.cacheSize()
        XCTAssertEqual(cacheSize, 0)
    }
}