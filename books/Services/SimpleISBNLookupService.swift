//
//  SimpleISBNLookupService.swift
//  books
//
//  Created by Claude on 8/11/25.
//

import Foundation

/// Simple, reliable ISBN lookup service with concurrent batch processing
/// 
/// This service provides straightforward ISBN lookup functionality by leveraging
/// the existing BookSearchService which already supports ISBN queries.
/// Enhanced with concurrent processing and smart rate limiting for optimal performance.
///
/// Key Features:
/// - Uses existing working BookSearchService
/// - Simple async/await interface
/// - Concurrent batch processing with TaskGroup
/// - Smart rate limiting integration
/// - Basic error handling and result parsing
/// - Thread-safe and lightweight
/// - ISBN cleaning and validation
/// - Proper Swift 6 concurrency support
/// - Progress callbacks for UI updates
@MainActor
class SimpleISBNLookupService: ObservableObject {
    
    // MARK: - Dependencies
    
    private let bookSearchService: BookSearchService
    private let rateLimiter: RateLimiter
    
    // MARK: - Configuration
    
    private let maxConcurrentLookups: Int
    private let batchSize: Int
    
    // MARK: - Statistics
    
    @Published private(set) var totalLookups = 0
    @Published private(set) var successfulLookups = 0
    @Published private(set) var failedLookups = 0
    @Published private(set) var concurrentLookups = 0
    @Published private(set) var rateLimitEvents = 0
    
    // MARK: - Initialization
    
    init(
        bookSearchService: BookSearchService? = nil,
        maxConcurrentLookups: Int = 4, // Conservative default for reliability
        batchSize: Int = 10
    ) {
        self.bookSearchService = bookSearchService ?? BookSearchService.shared
        self.rateLimiter = RateLimiter.googleBooks
        self.maxConcurrentLookups = maxConcurrentLookups
        self.batchSize = batchSize
    }
    
    // MARK: - Public Interface
    
    /// Look up book metadata for a single ISBN
    /// - Parameter isbn: The ISBN to look up (will be cleaned automatically)
    /// - Returns: Result containing BookMetadata on success or BookError on failure
    func lookupISBN(_ isbn: String) async -> Result<BookMetadata, BookSearchService.BookError> {
        // Clean and validate ISBN
        let cleanISBN = cleanISBN(isbn)
        guard isValidISBN(cleanISBN) else {
            await updateStats(success: false)
            return .failure(.invalidURL) // Use existing error type for invalid ISBN
        }
        
        // Wait for rate limiting permission
        let waitedForPermission = await rateLimiter.waitForPermission()
        if !waitedForPermission {
            await incrementRateLimitEvents()
        }
        
        // Use BookSearchService with isbn: query format
        let query = "isbn:\(cleanISBN)"
        
        let result = await bookSearchService.search(
            query: query,
            sortBy: .relevance,
            maxResults: 1,
            includeTranslations: true
        )
        
        switch result {
        case .success(let books):
            if let firstBook = books.first {
                await rateLimiter.reportSuccess()
                await updateStats(success: true)
                return .success(firstBook)
            } else {
                // No books found for ISBN
                await updateStats(success: false)
                return .failure(.noData)
            }
        case .failure(let error):
            // Report rate limit errors to the rate limiter
            if isRateLimitError(error) {
                await rateLimiter.reportRateLimitError()
                await incrementRateLimitEvents()
            }
            await updateStats(success: false)
            return .failure(error)
        }
    }
    
    /// Look up multiple ISBNs concurrently with rate limiting
    /// - Parameters:
    ///   - isbns: Array of ISBNs to look up
    ///   - progressCallback: Optional callback for progress updates
    /// - Returns: Array of results (preserves input order)
    func lookupISBNs(
        _ isbns: [String],
        progressCallback: ((Int, Int) -> Void)? = nil
    ) async -> [Result<BookMetadata, BookSearchService.BookError>] {
        guard !isbns.isEmpty else { return [] }
        
        // Process ISBNs in batches to control concurrency
        var allResults: [Result<BookMetadata, BookSearchService.BookError>] = []
        let batches = isbns.chunked(into: batchSize)
        var completedCount = 0
        
        for batch in batches {
            let batchResults = await processBatchConcurrently(batch)
            allResults.append(contentsOf: batchResults)
            
            completedCount += batch.count
            progressCallback?(completedCount, isbns.count)
        }
        
        return allResults
    }
    
    /// Process a batch of ISBNs concurrently with controlled concurrency
    /// - Parameter isbns: Batch of ISBNs to process
    /// - Returns: Results in the same order as input
    private func processBatchConcurrently(
        _ isbns: [String]
    ) async -> [Result<BookMetadata, BookSearchService.BookError>] {
        
        // Create indexed pairs to maintain order
        let indexedISBNs = isbns.enumerated().map { (index: $0, isbn: $1) }
        var results: [(index: Int, result: Result<BookMetadata, BookSearchService.BookError>)] = []
        
        await withTaskGroup(of: (Int, Result<BookMetadata, BookSearchService.BookError>).self) { group in
            var activeTasks = 0
            var nextIndex = 0
            
            // Start initial tasks up to concurrency limit
            while nextIndex < indexedISBNs.count && activeTasks < maxConcurrentLookups {
                let item = indexedISBNs[nextIndex]
                group.addTask { [weak self] in
                    await self?.updateConcurrentCount(delta: 1)
                    let result = await self?.lookupISBN(item.isbn) ?? .failure(.invalidURL)
                    await self?.updateConcurrentCount(delta: -1)
                    return (item.index, result)
                }
                activeTasks += 1
                nextIndex += 1
            }
            
            // Process results as they complete and start new tasks
            for await (index, result) in group {
                results.append((index: index, result: result))
                activeTasks -= 1
                
                // Start next task if available
                if nextIndex < indexedISBNs.count {
                    let item = indexedISBNs[nextIndex]
                    group.addTask { [weak self] in
                        await self?.updateConcurrentCount(delta: 1)
                        let result = await self?.lookupISBN(item.isbn) ?? .failure(.invalidURL)
                        await self?.updateConcurrentCount(delta: -1)
                        return (item.index, result)
                    }
                    nextIndex += 1
                    activeTasks += 1
                }
            }
        }
        
        // Sort results back to original order and extract just the results
        return results
            .sorted { $0.index < $1.index }
            .map { $0.result }
    }
    
    /// Look up multiple ISBNs sequentially (legacy method for compatibility)
    /// - Parameters:
    ///   - isbns: Array of ISBNs to look up
    ///   - progressCallback: Optional callback for progress updates
    /// - Returns: Array of results (preserves input order)
    func lookupISBNsSequentially(
        _ isbns: [String],
        progressCallback: ((Int, Int) -> Void)? = nil
    ) async -> [Result<BookMetadata, BookSearchService.BookError>] {
        var results: [Result<BookMetadata, BookSearchService.BookError>] = []
        
        for (index, isbn) in isbns.enumerated() {
            let result = await lookupISBN(isbn)
            results.append(result)
            
            // Report progress
            progressCallback?(index + 1, isbns.count)
            
            // Small delay to be respectful to API (rate limiter handles this now)
            try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
        }
        
        return results
    }
    
    /// Reset statistics counters
    func resetStats() {
        totalLookups = 0
        successfulLookups = 0
        failedLookups = 0
        concurrentLookups = 0
        rateLimitEvents = 0
    }
    
    // MARK: - Statistics
    
    var successRate: Double {
        guard totalLookups > 0 else { return 0 }
        return Double(successfulLookups) / Double(totalLookups)
    }
    
    var rateLimitRate: Double {
        guard totalLookups > 0 else { return 0 }
        return Double(rateLimitEvents) / Double(totalLookups)
    }
    
    var currentConcurrency: Int {
        return concurrentLookups
    }
    
    /// Get detailed performance statistics
    func getPerformanceStats() async -> PerformanceStats {
        let rateLimiterStatus = await rateLimiter.getStatus()
        return PerformanceStats(
            totalLookups: totalLookups,
            successfulLookups: successfulLookups,
            failedLookups: failedLookups,
            successRate: successRate,
            currentConcurrency: concurrentLookups,
            rateLimitEvents: rateLimitEvents,
            rateLimitRate: rateLimitRate,
            rateLimiterStatus: rateLimiterStatus
        )
    }
    
    // MARK: - Private Implementation
    
    private func updateStats(success: Bool) async {
        totalLookups += 1
        if success {
            successfulLookups += 1
        } else {
            failedLookups += 1
        }
    }
    
    private func updateConcurrentCount(delta: Int) async {
        concurrentLookups += delta
        concurrentLookups = max(0, concurrentLookups) // Ensure non-negative
    }
    
    private func incrementRateLimitEvents() async {
        rateLimitEvents += 1
    }
    
    private func isRateLimitError(_ error: BookSearchService.BookError) -> Bool {
        switch error {
        case .networkError:
            return true // Network errors might be rate limits
        default:
            return false
        }
    }
    
    /// Clean ISBN by removing common formatting characters
    private func cleanISBN(_ isbn: String) -> String {
        return isbn
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ":", with: "")
    }
    
    /// Validate ISBN format (basic check for 10 or 13 digits)
    private func isValidISBN(_ isbn: String) -> Bool {
        let digits = isbn.filter { $0.isNumber || $0.lowercased() == "x" }
        return digits.count == 10 || digits.count == 13
    }
}

// MARK: - Convenience Extensions

extension SimpleISBNLookupService {
    
    /// Convenience method that returns optional BookMetadata instead of Result
    func findBook(isbn: String) async -> BookMetadata? {
        let result = await lookupISBN(isbn)
        switch result {
        case .success(let book):
            return book
        case .failure:
            return nil
        }
    }
    
    /// Check if an ISBN exists in the database
    func isbnExists(_ isbn: String) async -> Bool {
        let result = await lookupISBN(isbn)
        return result.isSuccess
    }
}

// MARK: - Performance Statistics

struct PerformanceStats {
    let totalLookups: Int
    let successfulLookups: Int
    let failedLookups: Int
    let successRate: Double
    let currentConcurrency: Int
    let rateLimitEvents: Int
    let rateLimitRate: Double
    let rateLimiterStatus: RateLimiterStatus
    
    var description: String {
        return """
        ISBN Lookup Performance:
        - Total: \(totalLookups) lookups
        - Success: \(successfulLookups) (\(Int(successRate * 100))%)
        - Failed: \(failedLookups)
        - Current Concurrency: \(currentConcurrency)
        - Rate Limited: \(rateLimitEvents) (\(Int(rateLimitRate * 100))%)
        - Rate Limiter: \(rateLimiterStatus.description)
        """
    }
}

// MARK: - Array Extension for Chunking

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Result Extension

private extension Result {
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
}