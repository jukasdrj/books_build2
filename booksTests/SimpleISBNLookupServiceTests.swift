//
// SimpleISBNLookupServiceTests.swift
// books
//
// Comprehensive unit tests for the new SimpleISBNLookupService
// Swift 6 testing patterns with async/await and actor isolation
//

import Testing
import Foundation
@testable import books

@Suite("Simple ISBN Lookup Service Tests")
struct SimpleISBNLookupServiceTests {
    
    // MARK: - Test Data Helpers
    
    private func createMockBookMetadata(
        isbn: String,
        title: String = "Test Book",
        authors: [String] = ["Test Author"]
    ) -> BookMetadata {
        return BookMetadata(
            googleBooksID: "test-\(isbn)",
            title: title,
            authors: authors,
            publishedDate: "2024",
            pageCount: 200,
            bookDescription: "Test description",
            imageURL: URL(string: "https://example.com/cover.jpg"),
            language: "en",
            publisher: "Test Publisher",
            isbn: isbn,
            genre: ["Fiction"]
        )
    }
    
    private func createISBNTestData() -> [String] {
        return [
            "9780134685991", // Clean ISBN-13
            "0134685997",    // ISBN-10
            "978-0-13-468599-1", // ISBN-13 with hyphens
            "0-13-468599-7", // ISBN-10 with hyphens
            "invalid-isbn"   // Invalid format for error testing
        ]
    }
    
    // MARK: - Service Initialization Tests
    
    @Test("Service Initialization - Should create service with BookSearchService dependency")
    func testServiceInitialization() async {
        let mockBookService = MockBookSearchService()
        let service = SimpleISBNLookupService(bookSearchService: mockBookService)
        
        #expect(service != nil, "Service should initialize successfully")
        
        // Test service is ready for operations
        let isReady = await service.isReady()
        #expect(isReady == true, "Service should be ready after initialization")
    }
    
    @Test("Service Configuration - Should use proper configuration defaults")
    func testServiceConfiguration() async {
        let mockBookService = MockBookSearchService()
        let service = SimpleISBNLookupService(bookSearchService: mockBookService)
        
        let config = await service.configuration
        #expect(config.maxConcurrentRequests >= 3, "Should allow reasonable concurrency")
        #expect(config.maxConcurrentRequests <= 8, "Should limit concurrency to prevent API abuse")
        #expect(config.requestTimeout > 0, "Should have positive timeout")
        #expect(config.retryAttempts >= 2, "Should allow retries")
    }
    
    // MARK: - Single ISBN Lookup Tests
    
    @Test("Single ISBN Lookup - Should successfully lookup valid ISBN")
    func testSingleISBNLookupSuccess() async throws {
        let mockBookService = MockBookSearchService()
        let testISBN = "9780134685991"
        let expectedMetadata = createMockBookMetadata(isbn: testISBN, title: "Swift Programming")
        
        mockBookService.searchByISBNResult = expectedMetadata
        
        let service = SimpleISBNLookupService(bookSearchService: mockBookService)
        let result = await service.lookupISBN(testISBN)
        
        switch result {
        case .success(let metadata):
            #expect(metadata.isbn == testISBN, "Returned metadata should have correct ISBN")
            #expect(metadata.title == "Swift Programming", "Should return correct title")
        case .failure(let error):
            throw error
        case .notFound:
            throw SimpleISBNLookupError.unexpectedResult("Expected success but got not found")
        }
    }
    
    @Test("Single ISBN Lookup - Should handle not found gracefully")
    func testSingleISBNLookupNotFound() async {
        let mockBookService = MockBookSearchService()
        let testISBN = "9999999999999" // Non-existent ISBN
        
        mockBookService.searchByISBNResult = nil // No result
        
        let service = SimpleISBNLookupService(bookSearchService: mockBookService)
        let result = await service.lookupISBN(testISBN)
        
        switch result {
        case .notFound(let isbn):
            #expect(isbn == testISBN, "Should return the original ISBN")
        case .success:
            #expect(Bool(false), "Should not succeed for non-existent ISBN")
        case .failure:
            #expect(Bool(false), "Should return .notFound, not .failure for missing books")
        }
    }
    
    @Test("Single ISBN Lookup - Should handle network errors appropriately")
    func testSingleISBNLookupNetworkError() async {
        let mockBookService = MockBookSearchService()
        let testISBN = "9780134685991"
        
        mockBookService.shouldThrowError = true
        
        let service = SimpleISBNLookupService(bookSearchService: mockBookService)
        let result = await service.lookupISBN(testISBN)
        
        switch result {
        case .failure(let error):
            #expect(error is MockError, "Should propagate network error")
        case .success:
            #expect(Bool(false), "Should not succeed when network fails")
        case .notFound:
            #expect(Bool(false), "Should return error, not not-found for network issues")
        }
    }
    
    @Test("Single ISBN Lookup - Should normalize ISBN formats")
    func testISBNNormalization() async {
        let mockBookService = MockBookSearchService()
        let testCases = [
            ("978-0-13-468599-1", "9780134685991"), // Remove hyphens from ISBN-13
            ("0-13-468599-7", "0134685997"),        // Remove hyphens from ISBN-10
            ("  9780134685991  ", "9780134685991"), // Trim whitespace
        ]
        
        let service = SimpleISBNLookupService(bookSearchService: mockBookService)
        
        for (input, expected) in testCases {
            let normalized = await service.normalizeISBN(input)
            #expect(normalized == expected, "ISBN '\(input)' should normalize to '\(expected)' but got '\(normalized)'")
        }
    }
    
    // MARK: - Batch ISBN Lookup Tests
    
    @Test("Batch ISBN Lookup - Should process multiple ISBNs concurrently")
    func testBatchISBNLookup() async {
        let mockBookService = MockBookSearchService()
        let testISBNs = ["9780134685991", "9780321267481", "9780135166307"]
        
        // Setup mock responses
        mockBookService.batchResponses = testISBNs.reduce(into: [String: BookMetadata]()) { dict, isbn in
            dict[isbn] = createMockBookMetadata(isbn: isbn, title: "Book \(isbn)")
        }
        
        let service = SimpleISBNLookupService(bookSearchService: mockBookService)
        let results = await service.lookupISBNs(testISBNs)
        
        #expect(results.count == testISBNs.count, "Should return result for each ISBN")
        
        // Verify all successful lookups
        let successCount = results.compactMap { result in
            if case .success = result { return result }
            return nil
        }.count
        
        #expect(successCount == testISBNs.count, "All ISBNs should be found")
        
        // Verify concurrent execution (mock should track concurrent calls)
        #expect(mockBookService.maxConcurrentCalls > 1, "Should execute lookups concurrently")
    }
    
    @Test("Batch ISBN Lookup - Should maintain order in results")
    func testBatchISBNLookupOrder() async {
        let mockBookService = MockBookSearchService()
        let testISBNs = ["isbn1", "isbn2", "isbn3", "isbn4", "isbn5"]
        
        // Add artificial delay to test ordering
        mockBookService.artificialDelay = 0.1
        
        // Setup mock responses with titles that include the ISBN for verification
        mockBookService.batchResponses = testISBNs.reduce(into: [String: BookMetadata]()) { dict, isbn in
            dict[isbn] = createMockBookMetadata(isbn: isbn, title: "Title-\(isbn)")
        }
        
        let service = SimpleISBNLookupService(bookSearchService: mockBookService)
        let results = await service.lookupISBNs(testISBNs)
        
        // Verify results are in same order as input
        for (index, result) in results.enumerated() {
            let expectedISBN = testISBNs[index]
            switch result {
            case .success(let metadata):
                #expect(metadata.isbn == expectedISBN, "Result at index \(index) should correspond to ISBN \(expectedISBN)")
            case .failure(let isbn, _):
                #expect(isbn == expectedISBN, "Failed result at index \(index) should correspond to ISBN \(expectedISBN)")
            case .notFound(let isbn):
                #expect(isbn == expectedISBN, "Not found result at index \(index) should correspond to ISBN \(expectedISBN)")
            }
        }
    }
    
    @Test("Batch ISBN Lookup - Should handle mixed success and failure results")
    func testBatchISBNLookupMixedResults() async {
        let mockBookService = MockBookSearchService()
        let testISBNs = [
            "9780134685991", // Should succeed
            "invalid-isbn",  // Should fail
            "9999999999999"  // Should be not found
        ]
        
        // Setup mixed responses
        mockBookService.batchResponses["9780134685991"] = createMockBookMetadata(isbn: "9780134685991")
        mockBookService.batchFailures["invalid-isbn"] = MockError.isbnSearchFailed
        mockBookService.batchNotFound.insert("9999999999999")
        
        let service = SimpleISBNLookupService(bookSearchService: mockBookService)
        let results = await service.lookupISBNs(testISBNs)
        
        #expect(results.count == 3, "Should return 3 results")
        
        // Verify result types
        switch results[0] {
        case .success: break // Expected
        default: #expect(Bool(false), "First result should be success")
        }
        
        switch results[1] {
        case .failure: break // Expected
        default: #expect(Bool(false), "Second result should be failure")
        }
        
        switch results[2] {
        case .notFound: break // Expected
        default: #expect(Bool(false), "Third result should be not found")
        }
    }
    
    // MARK: - Concurrency and Performance Tests
    
    @Test("Concurrency Control - Should respect max concurrent requests")
    func testConcurrencyControl() async {
        let mockBookService = MockBookSearchService()
        let testISBNs = Array(1...20).map { "isbn\($0)" }
        
        // Setup responses for all ISBNs
        mockBookService.batchResponses = testISBNs.reduce(into: [String: BookMetadata]()) { dict, isbn in
            dict[isbn] = createMockBookMetadata(isbn: isbn)
        }
        
        // Add delay to observe concurrency behavior
        mockBookService.artificialDelay = 0.2
        mockBookService.trackConcurrency = true
        
        let service = SimpleISBNLookupService(
            bookSearchService: mockBookService,
            configuration: .init(maxConcurrentRequests: 5)
        )
        
        let startTime = Date()
        let results = await service.lookupISBNs(testISBNs)
        let duration = Date().timeIntervalSince(startTime)
        
        #expect(results.count == testISBNs.count, "Should return all results")
        #expect(mockBookService.maxConcurrentCalls <= 5, "Should not exceed max concurrent requests")
        
        // With 5 concurrent requests and 0.2s delay, 20 requests should take approximately 0.8s (4 batches)
        #expect(duration < 1.5, "Should complete reasonably quickly with concurrency")
        #expect(duration > 0.6, "Should take some time due to artificial delay")
    }
    
    @Test("Rate Limiting - Should respect rate limits")
    func testRateLimiting() async {
        let mockBookService = MockBookSearchService()
        let testISBNs = Array(1...10).map { "isbn\($0)" }
        
        mockBookService.batchResponses = testISBNs.reduce(into: [String: BookMetadata]()) { dict, isbn in
            dict[isbn] = createMockBookMetadata(isbn: isbn)
        }
        
        let service = SimpleISBNLookupService(
            bookSearchService: mockBookService,
            configuration: .init(
                maxConcurrentRequests: 3,
                rateLimitPerSecond: 5.0,
                enableRateLimiting: true
            )
        )
        
        let startTime = Date()
        let results = await service.lookupISBNs(testISBNs)
        let duration = Date().timeIntervalSince(startTime)
        
        #expect(results.count == testISBNs.count, "Should return all results")
        
        // With rate limit of 5 requests per second, 10 requests should take at least 2 seconds
        #expect(duration >= 1.8, "Should respect rate limiting")
    }
    
    // MARK: - Error Handling and Retry Tests
    
    @Test("Error Handling - Should categorize errors correctly")
    func testErrorCategorization() async {
        let mockBookService = MockBookSearchService()
        let service = SimpleISBNLookupService(bookSearchService: mockBookService)
        
        let testCases: [(MockError, SimpleISBNLookupError.Category)] = [
            (.searchFailed, .networkError),
            (.isbnSearchFailed, .apiError),
            (.validationFailed, .clientError)
        ]
        
        for (mockError, expectedCategory) in testCases {
            mockBookService.shouldThrowError = true
            mockBookService.errorToThrow = mockError
            
            let result = await service.lookupISBN("test-isbn")
            
            switch result {
            case .failure(_, let error):
                let category = await service.categorizeError(error)
                #expect(category == expectedCategory, "Error \(mockError) should be categorized as \(expectedCategory)")
            default:
                #expect(Bool(false), "Should return failure for error case")
            }
        }
    }
    
    @Test("Retry Logic - Should retry transient failures")
    func testRetryLogic() async {
        let mockBookService = MockBookSearchService()
        let testISBN = "9780134685991"
        
        // Fail first two attempts, succeed on third
        mockBookService.failurePattern = [true, true, false]
        mockBookService.searchByISBNResult = createMockBookMetadata(isbn: testISBN)
        
        let service = SimpleISBNLookupService(
            bookSearchService: mockBookService,
            configuration: .init(retryAttempts: 3, retryDelay: 0.1)
        )
        
        let result = await service.lookupISBN(testISBN)
        
        switch result {
        case .success(let metadata):
            #expect(metadata.isbn == testISBN, "Should eventually succeed with retries")
            #expect(mockBookService.callCount == 3, "Should make exactly 3 attempts")
        case .failure, .notFound:
            #expect(Bool(false), "Should succeed after retries")
        }
    }
    
    @Test("Circuit Breaker - Should trip on repeated failures")
    func testCircuitBreaker() async {
        let mockBookService = MockBookSearchService()
        mockBookService.shouldThrowError = true
        
        let service = SimpleISBNLookupService(
            bookSearchService: mockBookService,
            configuration: .init(
                enableCircuitBreaker: true,
                circuitBreakerThreshold: 3,
                circuitBreakerTimeout: 1.0
            )
        )
        
        let testISBNs = Array(1...5).map { "isbn\($0)" }
        
        // First few requests should fail and trip the circuit breaker
        var failureCount = 0
        for isbn in testISBNs {
            let result = await service.lookupISBN(isbn)
            if case .failure = result {
                failureCount += 1
            }
        }
        
        #expect(failureCount >= 3, "Should have multiple failures")
        
        let circuitBreakerStatus = await service.circuitBreakerStatus
        #expect(circuitBreakerStatus.isOpen, "Circuit breaker should be open after repeated failures")
    }
    
    // MARK: - Caching Tests
    
    @Test("Caching - Should cache successful lookups")
    func testCaching() async {
        let mockBookService = MockBookSearchService()
        let testISBN = "9780134685991"
        let expectedMetadata = createMockBookMetadata(isbn: testISBN)
        
        mockBookService.searchByISBNResult = expectedMetadata
        
        let service = SimpleISBNLookupService(
            bookSearchService: mockBookService,
            configuration: .init(enableCaching: true)
        )
        
        // First lookup
        let result1 = await service.lookupISBN(testISBN)
        #expect(mockBookService.callCount == 1, "Should make one API call")
        
        // Second lookup should use cache
        let result2 = await service.lookupISBN(testISBN)
        #expect(mockBookService.callCount == 1, "Should not make additional API calls for cached items")
        
        // Verify both results are successful
        switch (result1, result2) {
        case (.success(let metadata1), .success(let metadata2)):
            #expect(metadata1.isbn == testISBN, "First result should have correct ISBN")
            #expect(metadata2.isbn == testISBN, "Cached result should have correct ISBN")
            #expect(metadata1.title == metadata2.title, "Cached result should match original")
        default:
            #expect(Bool(false), "Both lookups should succeed")
        }
    }
    
    @Test("Cache Management - Should handle cache operations correctly")
    func testCacheManagement() async {
        let mockBookService = MockBookSearchService()
        let service = SimpleISBNLookupService(bookSearchService: mockBookService)
        
        // Test cache size
        let initialSize = await service.cacheSize()
        #expect(initialSize == 0, "Cache should start empty")
        
        // Add items to cache
        let testMetadata = createMockBookMetadata(isbn: "test-isbn")
        await service.cacheMetadata(testMetadata, forISBN: "test-isbn")
        
        let sizeAfterAdd = await service.cacheSize()
        #expect(sizeAfterAdd == 1, "Cache should contain one item")
        
        // Clear cache
        await service.clearCache()
        
        let sizeAfterClear = await service.cacheSize()
        #expect(sizeAfterClear == 0, "Cache should be empty after clearing")
    }
}

// MARK: - Supporting Types and Extensions

enum SimpleISBNLookupError: Error, Equatable {
    case unexpectedResult(String)
    
    enum Category: Equatable {
        case networkError
        case apiError
        case clientError
    }
}

// Enhanced Mock BookSearchService for testing
// Note: All properties and methods moved to MockBookSearchService class in ServiceProtocols.swift
// to avoid duplicate declarations

// Configuration struct for SimpleISBNLookupService
struct SimpleISBNLookupConfiguration {
    let maxConcurrentRequests: Int
    let requestTimeout: TimeInterval
    let retryAttempts: Int
    let retryDelay: TimeInterval
    let rateLimitPerSecond: Double
    let enableRateLimiting: Bool
    let enableCircuitBreaker: Bool
    let circuitBreakerThreshold: Int
    let circuitBreakerTimeout: TimeInterval
    let enableCaching: Bool
    
    init(
        maxConcurrentRequests: Int = 5,
        requestTimeout: TimeInterval = 30.0,
        retryAttempts: Int = 2,
        retryDelay: TimeInterval = 1.0,
        rateLimitPerSecond: Double = 10.0,
        enableRateLimiting: Bool = false,
        enableCircuitBreaker: Bool = false,
        circuitBreakerThreshold: Int = 5,
        circuitBreakerTimeout: TimeInterval = 30.0,
        enableCaching: Bool = true
    ) {
        self.maxConcurrentRequests = maxConcurrentRequests
        self.requestTimeout = requestTimeout
        self.retryAttempts = retryAttempts
        self.retryDelay = retryDelay
        self.rateLimitPerSecond = rateLimitPerSecond
        self.enableRateLimiting = enableRateLimiting
        self.enableCircuitBreaker = enableCircuitBreaker
        self.circuitBreakerThreshold = circuitBreakerThreshold
        self.circuitBreakerTimeout = circuitBreakerTimeout
        self.enableCaching = enableCaching
    }
}

// Result type for SimpleISBNLookupService
enum SimpleISBNLookupResult {
    case success(BookMetadata)
    case failure(String, Error) // ISBN, Error
    case notFound(String)       // ISBN
    
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}

// Circuit breaker status for testing
struct CircuitBreakerStatus {
    let isOpen: Bool
    let failureCount: Int
    let lastFailureTime: Date?
}

// Mock SimpleISBNLookupService interface for compilation
class SimpleISBNLookupService {
    private let bookSearchService: MockBookSearchService
    private let configuration: SimpleISBNLookupConfiguration
    
    init(
        bookSearchService: MockBookSearchService,
        configuration: SimpleISBNLookupConfiguration = .init()
    ) {
        self.bookSearchService = bookSearchService
        self.configuration = configuration
    }
    
    func isReady() async -> Bool { return true }
    func lookupISBN(_ isbn: String) async -> SimpleISBNLookupResult {
        // Mock implementation
        return .notFound(isbn)
    }
    func lookupISBNs(_ isbns: [String]) async -> [SimpleISBNLookupResult] {
        return isbns.map { .notFound($0) }
    }
    func normalizeISBN(_ isbn: String) async -> String { return isbn }
    func categorizeError(_ error: Error) async -> SimpleISBNLookupError.Category { return .networkError }
    func cacheSize() async -> Int { return 0 }
    func clearCache() async { }
    func cacheMetadata(_ metadata: BookMetadata, forISBN isbn: String) async { }
    var circuitBreakerStatus: CircuitBreakerStatus { CircuitBreakerStatus(isOpen: false, failureCount: 0, lastFailureTime: nil) }
}