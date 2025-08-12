import Foundation
import SwiftData
import SwiftUI
@testable import books

// MARK: - Service Protocols for Testing

/// Protocol for book search functionality to enable mocking in tests
protocol BookSearchServiceProtocol {
    func searchBooks(query: String) async throws -> [BookSearchResult]
    func getBookDetails(googleBooksID: String) async throws -> BookMetadata?
    func searchByISBN(_ isbn: String) async throws -> BookMetadata?
}

/// Protocol for CSV import functionality
protocol CSVImportServiceProtocol {
    func previewCSV(from fileURL: URL) async throws -> CSVPreviewResult
    func importBooks(from fileURL: URL, columnMapping: [String: String], modelContext: ModelContext) async throws -> CSVImportResult
    func validateCSVFormat(_ fileURL: URL) async throws -> Bool
}


/// Protocol for image caching functionality
protocol ImageCacheProtocol {
    func image(for url: String) async -> UIImage?
    func cacheImage(_ image: UIImage, for url: String) async
    func clearCache() async
    func cacheSize() async -> Int
}

/// Protocol for library reset functionality
protocol LibraryResetServiceProtocol {
    func countItemsToDelete() async
    func exportLibraryData(format: LibraryResetService.ExportFormat) async throws -> URL
    func resetLibrary() async throws
    var booksToDelete: Int { get }
    var metadataToDelete: Int { get }
    var resetState: LibraryResetService.ResetState { get }
    var exportProgress: Double { get }
}

/// Protocol for haptic feedback functionality
protocol HapticFeedbackProtocol {
    func bookMarkedAsRead()
    func bookAddedToLibrary()
    func ratingChanged()
    func importCompleted()
    func errorOccurred()
}

// MARK: - Mock Implementations for Testing

/// Mock implementation of BookSearchService for testing
class MockBookSearchService: BookSearchServiceProtocol {
    var searchBooksResult: [BookSearchResult] = []
    var getBookDetailsResult: BookMetadata?
    var searchByISBNResult: BookMetadata?
    var shouldThrowError = false
    var searchQuery: String?
    var searchCallCount = 0
    
    // Properties moved from extensions to avoid "extensions cannot contain stored properties" error
    var artificialDelay: TimeInterval = 0
    var trackConcurrency = false
    var maxConcurrentCalls = 0
    var callCount = 0
    var failurePattern: [Bool] = []
    var errorToThrow: Error?
    
    // Performance tracking properties
    var trackPerformance: Bool = false
    
    // Batch operation support
    private var _batchResponses: [String: BookMetadata] = [:]
    private var _batchFailures: [String: Error] = [:]
    private var _batchNotFound: Set<String> = []
    private var _currentConcurrentCalls = 0
    
    var batchResponses: [String: BookMetadata] {
        get { _batchResponses }
        set { _batchResponses = newValue }
    }
    var batchFailures: [String: Error] {
        get { _batchFailures }
        set { _batchFailures = newValue }
    }
    var batchNotFound: Set<String> {
        get { _batchNotFound }
        set { _batchNotFound = newValue }
    }
    
    // Performance metrics
    var concurrencyEfficiency: Double {
        guard trackPerformance else { return 0.8 }
        return Double.random(in: 0.7...0.95)
    }
    
    var concurrencyAdjustments: Int {
        guard trackPerformance else { return 0 }
        return Int.random(in: 0...5)
    }
    
    var averageConcurrencyLevel: Double {
        guard trackPerformance else { return Double(maxConcurrentCalls) }
        return Double(maxConcurrentCalls) * Double.random(in: 0.7...1.0)
    }
    
    func searchBooks(query: String) async throws -> [BookSearchResult] {
        searchQuery = query
        searchCallCount += 1
        
        if shouldThrowError {
            throw MockError.searchFailed
        }
        
        return searchBooksResult
    }
    
    func getBookDetails(googleBooksID: String) async throws -> BookMetadata? {
        if shouldThrowError {
            throw MockError.detailsFailed
        }
        
        return getBookDetailsResult
    }
    
    @MainActor
    func searchByISBN(_ isbn: String) async throws -> BookMetadata? {
        callCount += 1
        
        if trackConcurrency {
            _currentConcurrentCalls += 1
            maxConcurrentCalls = max(maxConcurrentCalls, _currentConcurrentCalls)
        }
        
        if artificialDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(artificialDelay * 1_000_000_000))
        }
        
        if trackConcurrency {
            _currentConcurrentCalls -= 1
        }
        
        // Handle failure pattern for retry testing
        if !failurePattern.isEmpty {
            let shouldFail = failurePattern[min(callCount - 1, failurePattern.count - 1)]
            if shouldFail {
                throw errorToThrow ?? MockError.isbnSearchFailed
            }
        }
        
        if shouldThrowError {
            throw errorToThrow ?? MockError.isbnSearchFailed
        }
        
        if let failure = batchFailures[isbn] {
            throw failure
        }
        
        if batchNotFound.contains(isbn) {
            return nil
        }
        
        return batchResponses[isbn] ?? searchByISBNResult
    }
}

/// Mock implementation of CSVImportService for testing
class MockCSVImportService: CSVImportServiceProtocol {
    var previewResult: CSVPreviewResult?
    var importResult: CSVImportResult?
    var validationResult = true
    var shouldThrowError = false
    var importCallCount = 0
    
    func previewCSV(from fileURL: URL) async throws -> CSVPreviewResult {
        if shouldThrowError {
            throw MockError.previewFailed
        }
        
        return previewResult ?? CSVPreviewResult(
            books: [],
            mappedColumns: ["Title": 0, "Author": 1],
            totalRows: 0,
            estimatedImportTime: 0
        )
    }
    
    func importBooks(from fileURL: URL, columnMapping: [String: String], modelContext: ModelContext) async throws -> CSVImportResult {
        importCallCount += 1
        
        if shouldThrowError {
            throw MockError.importFailed
        }
        
        return importResult ?? CSVImportResult(
            successCount: 0,
            skippedBooks: [],
            errors: [],
            importDuration: 0
        )
    }
    
    func validateCSVFormat(_ fileURL: URL) async throws -> Bool {
        if shouldThrowError {
            throw MockError.validationFailed
        }
        
        return validationResult
    }
}


/// Mock implementation of ImageCache for testing
class MockImageCache: ImageCacheProtocol {
    private var cache: [String: UIImage] = [:]
    var cacheAccessCount = 0
    
    func image(for url: String) async -> UIImage? {
        cacheAccessCount += 1
        return cache[url]
    }
    
    func cacheImage(_ image: UIImage, for url: String) async {
        cache[url] = image
    }
    
    func clearCache() async {
        cache.removeAll()
    }
    
    func cacheSize() async -> Int {
        return cache.count
    }
}

/// Mock implementation of LibraryResetService for testing
class MockLibraryResetService: LibraryResetServiceProtocol {
    var booksToDelete: Int = 0
    var metadataToDelete: Int = 0
    var resetState: LibraryResetService.ResetState = .idle
    var exportProgress: Double = 0.0
    var shouldThrowError = false
    var exportURL: URL?
    
    func countItemsToDelete() async {
        // Mock implementation - would normally count from context
    }
    
    func exportLibraryData(format: LibraryResetService.ExportFormat) async throws -> URL {
        if shouldThrowError {
            throw MockError.exportFailed
        }
        
        exportProgress = 1.0
        return exportURL ?? URL(fileURLWithPath: "/tmp/test_export.csv")
    }
    
    func resetLibrary() async throws {
        if shouldThrowError {
            throw MockError.resetFailed
        }
        
        resetState = .completed
        booksToDelete = 0
        metadataToDelete = 0
    }
}

/// Mock implementation of HapticFeedback for testing
class MockHapticFeedback: HapticFeedbackProtocol {
    var readFeedbackCount = 0
    var addedFeedbackCount = 0
    var ratingChangedCount = 0
    var importCompletedCount = 0
    var errorCount = 0
    
    func bookMarkedAsRead() {
        readFeedbackCount += 1
    }
    
    func bookAddedToLibrary() {
        addedFeedbackCount += 1
    }
    
    func ratingChanged() {
        ratingChangedCount += 1
    }
    
    func importCompleted() {
        importCompletedCount += 1
    }
    
    func errorOccurred() {
        errorCount += 1
    }
}

// MARK: - Mock Error Types

enum MockError: Error, LocalizedError {
    case searchFailed
    case detailsFailed
    case isbnSearchFailed
    case previewFailed
    case importFailed
    case validationFailed
    case exportFailed
    case resetFailed
    
    var errorDescription: String? {
        switch self {
        case .searchFailed:
            return "Mock search failed"
        case .detailsFailed:
            return "Mock details retrieval failed"
        case .isbnSearchFailed:
            return "Mock ISBN search failed"
        case .previewFailed:
            return "Mock preview failed"
        case .importFailed:
            return "Mock import failed"
        case .validationFailed:
            return "Mock validation failed"
        case .exportFailed:
            return "Mock export failed"
        case .resetFailed:
            return "Mock reset failed"
        }
    }
}