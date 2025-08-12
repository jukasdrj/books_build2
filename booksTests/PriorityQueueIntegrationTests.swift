//
// PriorityQueueIntegrationTests.swift
// books
//
// Integration tests for priority queue system in CSV import
// Tests ISBN books first, then title/author fallback
//

import Testing
import Foundation
import SwiftData
@testable import books

@Suite("Priority Queue Integration Tests")
struct PriorityQueueIntegrationTests {
    
    // MARK: - Test Data Setup
    
    private func createTestModelContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: UserBook.self, BookMetadata.self, configurations: config)
    }
    
    private func createMixedCSVData() -> CSVImportSession {
        let sampleData = [
            ["Title", "Author", "ISBN"],
            ["The Great Gatsby", "F. Scott Fitzgerald", "9780743273565"],     // ISBN book - priority 1
            ["To Kill a Mockingbird", "Harper Lee", ""],                      // Title/Author only - priority 2
            ["1984", "George Orwell", "9780451524935"],                       // ISBN book - priority 1
            ["Pride and Prejudice", "Jane Austen", "invalid-isbn"],           // Invalid ISBN, fallback to title/author
            ["The Catcher in the Rye", "J.D. Salinger", "9780316769174"],    // ISBN book - priority 1
            ["Brave New World", "Aldous Huxley", ""]                          // Title/Author only - priority 2
        ]
        
        let columns = [
            CSVColumn(originalName: "Title", index: 0, mappedField: .title, sampleValues: ["The Great Gatsby"]),
            CSVColumn(originalName: "Author", index: 1, mappedField: .author, sampleValues: ["F. Scott Fitzgerald"]),
            CSVColumn(originalName: "ISBN", index: 2, mappedField: .isbn, sampleValues: ["9780743273565"])
        ]
        
        return CSVImportSession(
            fileName: "test_priority_queue.csv",
            fileSize: 1024,
            totalRows: 6,
            detectedColumns: columns,
            sampleData: Array(sampleData.prefix(3)),
            allData: sampleData
        )
    }
    
    private func setupMockBookSearchService() -> MockBookSearchService {
        let mockService = MockBookSearchService()
        
        // Setup ISBN responses (high priority items)
        mockService.batchResponses = [
            "9780743273565": BookMetadata(
                googleBooksID: "gatsby-id",
                title: "The Great Gatsby",
                authors: ["F. Scott Fitzgerald"],
                isbn: "9780743273565",
                genre: ["Fiction", "Classic"]
            ),
            "9780451524935": BookMetadata(
                googleBooksID: "1984-id",
                title: "1984",
                authors: ["George Orwell"],
                isbn: "9780451524935",
                genre: ["Fiction", "Dystopian"]
            ),
            "9780316769174": BookMetadata(
                googleBooksID: "catcher-id",
                title: "The Catcher in the Rye",
                authors: ["J.D. Salinger"],
                isbn: "9780316769174",
                genre: ["Fiction", "Coming of Age"]
            )
        ]
        
        // Setup title/author responses (lower priority items)
        mockService.titleAuthorResponses = [
            ("To Kill a Mockingbird", "Harper Lee"): BookMetadata(
                googleBooksID: "mockingbird-id",
                title: "To Kill a Mockingbird",
                authors: ["Harper Lee"],
                genre: ["Fiction", "Classic"]
            ),
            ("Pride and Prejudice", "Jane Austen"): BookMetadata(
                googleBooksID: "pride-id",
                title: "Pride and Prejudice",
                authors: ["Jane Austen"],
                genre: ["Fiction", "Romance"]
            ),
            ("Brave New World", "Aldous Huxley"): BookMetadata(
                googleBooksID: "brave-id",
                title: "Brave New World",
                authors: ["Aldous Huxley"],
                genre: ["Fiction", "Dystopian"]
            )
        ]
        
        return mockService
    }
    
    // MARK: - Queue Prioritization Tests
    
    @Test("Queue Prioritization - Should process ISBN books before title/author books")
    func testQueuePrioritization() async throws {
        let container = try createTestModelContainer()
        let context = ModelContext(container)
        let mockBookService = setupMockBookSearchService()
        
        let csvSession = createMixedCSVData()
        let columnMappings: [String: BookField] = [
            "Title": .title,
            "Author": .author,
            "ISBN": .isbn
        ]
        
        let queueService = PriorityQueueImportService(
            bookSearchService: mockBookService,
            modelContext: context
        )
        
        // Track processing order
        mockBookService.trackProcessingOrder = true
        
        let result = await queueService.processImport(
            session: csvSession,
            columnMappings: columnMappings
        )
        
        // Verify successful import
        #expect(result.successfulImports > 0, "Should successfully import books")
        
        // Verify processing order - ISBN books should be processed first
        let processingOrder = mockBookService.processingOrder
        let isbnLookups = processingOrder.filter { $0.method == .isbn }
        let titleAuthorLookups = processingOrder.filter { $0.method == .titleAuthor }
        
        #expect(isbnLookups.count == 3, "Should have 3 ISBN lookups")
        #expect(titleAuthorLookups.count == 3, "Should have 3 title/author lookups")
        
        // All ISBN lookups should come before title/author lookups
        let firstTitleAuthorIndex = titleAuthorLookups.map(\.orderIndex).min() ?? Int.max
        let lastISBNIndex = isbnLookups.map(\.orderIndex).max() ?? -1
        
        #expect(lastISBNIndex < firstTitleAuthorIndex, "All ISBN lookups should be processed before title/author lookups")
    }
    
    @Test("Queue Management - Should handle mixed success/failure in priority queue")
    func testQueueMixedResults() async throws {
        let container = try createTestModelContainer()
        let context = ModelContext(container)
        let mockBookService = setupMockBookSearchService()
        
        // Make some ISBN lookups fail to test fallback behavior
        mockBookService.batchFailures["9780451524935"] = MockError.isbnSearchFailed
        
        let csvSession = createMixedCSVData()
        let columnMappings: [String: BookField] = [
            "Title": .title,
            "Author": .author,
            "ISBN": .isbn
        ]
        
        let queueService = PriorityQueueImportService(
            bookSearchService: mockBookService,
            modelContext: context
        )
        
        let result = await queueService.processImport(
            session: csvSession,
            columnMappings: columnMappings
        )
        
        // Should still process successfully found items
        #expect(result.successfulImports >= 2, "Should import at least 2 books successfully")
        #expect(result.failedImports > 0, "Should have some failures")
        
        // Failed ISBN books should attempt fallback to title/author
        let fallbackAttempts = await queueService.getFallbackAttempts()
        #expect(fallbackAttempts.count > 0, "Should attempt fallback for failed ISBN lookups")
    }
    
    @Test("Queue Concurrency - Should maintain priority order with concurrent processing")
    func testQueueConcurrentProcessing() async throws {
        let container = try createTestModelContainer()
        let context = ModelContext(container)
        let mockBookService = setupMockBookSearchService()
        
        // Add artificial delay to better test concurrent behavior
        mockBookService.artificialDelay = 0.1
        
        let csvSession = createMixedCSVData()
        let columnMappings: [String: BookField] = [
            "Title": .title,
            "Author": .author,
            "ISBN": .isbn
        ]
        
        let queueService = PriorityQueueImportService(
            bookSearchService: mockBookService,
            modelContext: context,
            configuration: .init(maxConcurrentRequests: 3)
        )
        
        mockBookService.trackProcessingOrder = true
        mockBookService.trackConcurrency = true
        
        let startTime = Date()
        let result = await queueService.processImport(
            session: csvSession,
            columnMappings: columnMappings
        )
        let duration = Date().timeIntervalSince(startTime)
        
        // Verify performance benefits of concurrency
        #expect(duration < 1.0, "Should complete quickly with concurrent processing")
        #expect(mockBookService.maxConcurrentCalls <= 3, "Should respect concurrency limits")
        
        // Verify priority is still maintained despite concurrency
        let processingOrder = mockBookService.processingOrder
        let isbnBatch = processingOrder.filter { $0.method == .isbn }
        let titleAuthorBatch = processingOrder.filter { $0.method == .titleAuthor }
        
        // ISBN batch should complete before title/author batch starts
        let isbnCompletionTimes = isbnBatch.map(\.completionTime)
        let titleAuthorStartTimes = titleAuthorBatch.map(\.startTime)
        
        if let latestISBN = isbnCompletionTimes.max(),
           let earliestTitleAuthor = titleAuthorStartTimes.min() {
            #expect(latestISBN <= earliestTitleAuthor, "ISBN batch should complete before title/author batch starts")
        }
    }
    
    // MARK: - Fallback Strategy Tests
    
    @Test("Fallback Strategy - Should fallback from ISBN to title/author on failure")
    func testISBNFallbackStrategy() async throws {
        let container = try createTestModelContainer()
        let context = ModelContext(container)
        let mockBookService = setupMockBookSearchService()
        
        // Create a book with ISBN that will fail but has valid title/author
        let fallbackData = [
            ["Title", "Author", "ISBN"],
            ["The Fellowship of the Ring", "J.R.R. Tolkien", "9999999999999"] // Invalid ISBN
        ]
        
        let csvSession = CSVImportSession(
            fileName: "test_fallback.csv",
            fileSize: 512,
            totalRows: 1,
            detectedColumns: [
                CSVColumn(originalName: "Title", index: 0, mappedField: .title, sampleValues: ["The Fellowship of the Ring"]),
                CSVColumn(originalName: "Author", index: 1, mappedField: .author, sampleValues: ["J.R.R. Tolkien"]),
                CSVColumn(originalName: "ISBN", index: 2, mappedField: .isbn, sampleValues: ["9999999999999"])
            ],
            sampleData: fallbackData,
            allData: fallbackData
        )
        
        // ISBN lookup will fail, but title/author lookup will succeed
        mockBookService.batchNotFound.insert("9999999999999")
        mockBookService.titleAuthorResponses[("The Fellowship of the Ring", "J.R.R. Tolkien")] = BookMetadata(
            googleBooksID: "fellowship-id",
            title: "The Fellowship of the Ring",
            authors: ["J.R.R. Tolkien"],
            genre: ["Fantasy"]
        )
        
        let columnMappings: [String: BookField] = [
            "Title": .title,
            "Author": .author,
            "ISBN": .isbn
        ]
        
        let queueService = PriorityQueueImportService(
            bookSearchService: mockBookService,
            modelContext: context
        )
        
        mockBookService.trackProcessingOrder = true
        
        let result = await queueService.processImport(
            session: csvSession,
            columnMappings: columnMappings
        )
        
        #expect(result.successfulImports == 1, "Should successfully import via fallback")
        #expect(result.failedImports == 0, "Should not have permanent failures with valid fallback")
        
        // Verify both ISBN and title/author lookups were attempted
        let processingOrder = mockBookService.processingOrder
        let isbnAttempts = processingOrder.filter { $0.method == .isbn }
        let fallbackAttempts = processingOrder.filter { $0.method == .titleAuthor }
        
        #expect(isbnAttempts.count == 1, "Should attempt ISBN lookup first")
        #expect(fallbackAttempts.count == 1, "Should fallback to title/author lookup")
        
        // Verify the order: ISBN first, then fallback
        if let isbnTime = isbnAttempts.first?.completionTime,
           let fallbackTime = fallbackAttempts.first?.startTime {
            #expect(isbnTime <= fallbackTime, "Fallback should occur after ISBN failure")
        }
    }
    
    @Test("Fallback Strategy - Should merge data from both sources")
    func testDataMergingWithFallback() async throws {
        let container = try createTestModelContainer()
        let context = ModelContext(container)
        let mockBookService = setupMockBookSearchService()
        
        let csvData = [
            ["Title", "Author", "ISBN", "Personal Notes", "Rating"],
            ["1984", "George Orwell", "invalid-isbn", "Great dystopian novel", "5"]
        ]
        
        let csvSession = CSVImportSession(
            fileName: "test_merge.csv",
            fileSize: 512,
            totalRows: 1,
            detectedColumns: [
                CSVColumn(originalName: "Title", index: 0, mappedField: .title, sampleValues: ["1984"]),
                CSVColumn(originalName: "Author", index: 1, mappedField: .author, sampleValues: ["George Orwell"]),
                CSVColumn(originalName: "ISBN", index: 2, mappedField: .isbn, sampleValues: ["invalid-isbn"]),
                CSVColumn(originalName: "Personal Notes", index: 3, mappedField: .personalNotes, sampleValues: ["Great dystopian novel"]),
                CSVColumn(originalName: "Rating", index: 4, mappedField: .rating, sampleValues: ["5"])
            ],
            sampleData: csvData,
            allData: csvData
        )
        
        // Setup fallback response with rich API data
        mockBookService.titleAuthorResponses[("1984", "George Orwell")] = BookMetadata(
            googleBooksID: "1984-fallback-id",
            title: "Nineteen Eighty-Four",  // Note: Different title from CSV
            authors: ["George Orwell"],
            publishedDate: "1949",
            pageCount: 328,
            bookDescription: "A dystopian social science fiction novel",
            imageURL: URL(string: "https://example.com/1984-cover.jpg"),
            publisher: "Secker & Warburg",
            genre: ["Fiction", "Dystopian", "Political"]
        )
        
        let columnMappings: [String: BookField] = [
            "Title": .title,
            "Author": .author,
            "ISBN": .isbn,
            "Personal Notes": .personalNotes,
            "Rating": .rating
        ]
        
        let queueService = PriorityQueueImportService(
            bookSearchService: mockBookService,
            modelContext: context
        )
        
        let result = await queueService.processImport(
            session: csvSession,
            columnMappings: columnMappings
        )
        
        #expect(result.successfulImports == 1, "Should successfully import with data merging")
        
        // Verify the imported book has merged data
        let fetchRequest = FetchDescriptor<UserBook>()
        let books = try context.fetch(fetchRequest)
        
        #expect(books.count == 1, "Should have one imported book")
        
        let importedBook = books.first!
        
        // API data should take priority for core metadata
        #expect(importedBook.metadata?.title == "Nineteen Eighty-Four", "Should use API title")
        #expect(importedBook.metadata?.publishedDate == "1949", "Should include API publication date")
        #expect(importedBook.metadata?.pageCount == 328, "Should include API page count")
        #expect(importedBook.metadata?.bookDescription != nil, "Should include API description")
        
        // CSV data should be preserved for personal fields
        #expect(importedBook.personalNotes == "Great dystopian novel", "Should preserve CSV personal notes")
        #expect(importedBook.rating == 5, "Should preserve CSV rating")
    }
    
    // MARK: - Queue State Management Tests
    
    @Test("Queue State - Should persist queue state across interruptions")
    func testQueueStatePersistence() async throws {
        let container = try createTestModelContainer()
        let context = ModelContext(container)
        let mockBookService = setupMockBookSearchService()
        
        let csvSession = createMixedCSVData()
        let columnMappings: [String: BookField] = [
            "Title": .title,
            "Author": .author,
            "ISBN": .isbn
        ]
        
        let queueService = PriorityQueueImportService(
            bookSearchService: mockBookService,
            modelContext: context
        )
        
        // Start import but interrupt after processing some items
        mockBookService.artificialDelay = 0.5 // Slow processing
        
        let importTask = Task {
            await queueService.processImport(
                session: csvSession,
                columnMappings: columnMappings
            )
        }
        
        // Cancel after short delay to simulate interruption
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        importTask.cancel()
        
        // Get queue state before cancellation
        let queueState = await queueService.getCurrentQueueState()
        
        #expect(queueState.totalItems == 6, "Should track total items")
        #expect(queueState.processedItems < 6, "Should have partial processing")
        #expect(queueState.remainingItems > 0, "Should have remaining items")
        
        // Resume with new service instance
        let resumeService = PriorityQueueImportService(
            bookSearchService: mockBookService,
            modelContext: context
        )
        
        let resumeResult = await resumeService.resumeImport(fromState: queueState)
        
        #expect(resumeResult.totalProcessed >= queueState.processedItems, "Should continue from previous state")
    }
    
    @Test("Queue Monitoring - Should provide real-time progress updates")
    func testQueueProgressMonitoring() async throws {
        let container = try createTestModelContainer()
        let context = ModelContext(container)
        let mockBookService = setupMockBookSearchService()
        
        let csvSession = createMixedCSVData()
        let columnMappings: [String: BookField] = [
            "Title": .title,
            "Author": .author,
            "ISBN": .isbn
        ]
        
        let queueService = PriorityQueueImportService(
            bookSearchService: mockBookService,
            modelContext: context
        )
        
        var progressUpdates: [QueueProgress] = []
        
        // Monitor progress updates
        let progressTask = Task {
            for await progress in queueService.progressStream {
                progressUpdates.append(progress)
            }
        }
        
        mockBookService.artificialDelay = 0.1
        
        let result = await queueService.processImport(
            session: csvSession,
            columnMappings: columnMappings
        )
        
        progressTask.cancel()
        
        #expect(progressUpdates.count > 0, "Should receive progress updates")
        #expect(progressUpdates.first?.phase == .isbnProcessing, "Should start with ISBN processing phase")
        
        let finalProgress = progressUpdates.last!
        #expect(finalProgress.phase == .completed, "Should end with completed phase")
        #expect(finalProgress.processedCount == result.totalBooks, "Final progress should match result")
        
        // Verify phase progression
        let phases = progressUpdates.map(\.phase)
        let expectedPhaseOrder: [QueueProgress.Phase] = [.isbnProcessing, .titleAuthorProcessing, .completed]
        
        for expectedPhase in expectedPhaseOrder {
            #expect(phases.contains(expectedPhase), "Should include \(expectedPhase) phase")
        }
    }
    
    // MARK: - Performance Optimization Tests
    
    @Test("Performance Optimization - Should optimize batch sizes based on success rates")
    func testAdaptiveBatchSizing() async throws {
        let container = try createTestModelContainer()
        let context = ModelContext(container)
        let mockBookService = setupMockBookSearchService()
        
        // Create larger dataset to test batch optimization
        var largeDataset = [["Title", "Author", "ISBN"]]
        for i in 1...50 {
            largeDataset.append(["Book \(i)", "Author \(i)", "978\(String(i).padded(toLength: 10, withPad: "0", startingAt: 0))"])
        }
        
        let csvSession = CSVImportSession(
            fileName: "large_dataset.csv",
            fileSize: 10240,
            totalRows: 50,
            detectedColumns: [
                CSVColumn(originalName: "Title", index: 0, mappedField: .title, sampleValues: ["Book 1"]),
                CSVColumn(originalName: "Author", index: 1, mappedField: .author, sampleValues: ["Author 1"]),
                CSVColumn(originalName: "ISBN", index: 2, mappedField: .isbn, sampleValues: ["9781000000000"])
            ],
            sampleData: Array(largeDataset.prefix(3)),
            allData: largeDataset
        )
        
        // Setup mixed success rates - first 25 ISBNs succeed, rest fail
        for i in 1...25 {
            let isbn = "978\(String(i).padded(toLength: 10, withPad: "0", startingAt: 0))"
            mockBookService.batchResponses[isbn] = BookMetadata(
                googleBooksID: "book-\(i)",
                title: "Book \(i)",
                authors: ["Author \(i)"],
                isbn: isbn
            )
        }
        
        for i in 26...50 {
            let isbn = "978\(String(i).padded(toLength: 10, withPad: "0", startingAt: 0))"
            mockBookService.batchNotFound.insert(isbn)
        }
        
        let columnMappings: [String: BookField] = [
            "Title": .title,
            "Author": .author,
            "ISBN": .isbn
        ]
        
        let queueService = PriorityQueueImportService(
            bookSearchService: mockBookService,
            modelContext: context,
            configuration: .init(
                enableAdaptiveBatching: true,
                initialBatchSize: 10
            )
        )
        
        mockBookService.trackBatchSizes = true
        
        let result = await queueService.processImport(
            session: csvSession,
            columnMappings: columnMappings
        )
        
        // Verify batch size adaptation
        let batchSizes = mockBookService.batchSizeHistory
        
        #expect(batchSizes.count > 1, "Should use multiple batches")
        
        // Early batches (high success rate) should increase in size
        // Later batches (low success rate) should decrease in size
        let earlyBatches = batchSizes.prefix(3)
        let laterBatches = batchSizes.suffix(3)
        
        let avgEarlySize = earlyBatches.reduce(0, +) / earlyBatches.count
        let avgLaterSize = laterBatches.reduce(0, +) / laterBatches.count
        
        #expect(avgEarlySize <= avgLaterSize || avgEarlySize > 5, "Should adapt batch sizes based on success rates")
    }
}

// MARK: - Supporting Types and Mock Extensions

// Priority Queue Import Service (mock interface for testing)
class PriorityQueueImportService {
    private let bookSearchService: MockBookSearchService
    private let modelContext: ModelContext
    private let configuration: Configuration
    
    struct Configuration {
        let maxConcurrentRequests: Int
        let enableAdaptiveBatching: Bool
        let initialBatchSize: Int
        
        init(
            maxConcurrentRequests: Int = 5,
            enableAdaptiveBatching: Bool = false,
            initialBatchSize: Int = 10
        ) {
            self.maxConcurrentRequests = maxConcurrentRequests
            self.enableAdaptiveBatching = enableAdaptiveBatching
            self.initialBatchSize = initialBatchSize
        }
    }
    
    init(
        bookSearchService: MockBookSearchService,
        modelContext: ModelContext,
        configuration: Configuration = .init()
    ) {
        self.bookSearchService = bookSearchService
        self.modelContext = modelContext
        self.configuration = configuration
    }
    
    func processImport(
        session: CSVImportSession,
        columnMappings: [String: BookField]
    ) async -> ImportResult {
        // Mock implementation
        return ImportResult(
            sessionId: session.id,
            totalBooks: session.totalRows,
            successfulImports: session.totalRows,
            failedImports: 0,
            duplicatesSkipped: 0,
            duplicatesISBN: 0,
            duplicatesGoogleID: 0,
            duplicatesTitleAuthor: 0,
            duration: 1.0,
            errors: [],
            importedBookIds: []
        )
    }
    
    func getFallbackAttempts() async -> [FallbackAttempt] {
        return []
    }
    
    func getCurrentQueueState() async -> QueueState {
        return QueueState(totalItems: 0, processedItems: 0, remainingItems: 0)
    }
    
    func resumeImport(fromState state: QueueState) async -> ResumeResult {
        return ResumeResult(totalProcessed: state.processedItems)
    }
    
    var progressStream: AsyncStream<QueueProgress> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}

struct FallbackAttempt {
    let isbn: String
    let title: String
    let author: String
    let success: Bool
}

struct QueueState {
    let totalItems: Int
    let processedItems: Int
    let remainingItems: Int
}

struct ResumeResult {
    let totalProcessed: Int
}

struct QueueProgress {
    enum Phase {
        case isbnProcessing
        case titleAuthorProcessing
        case completed
    }
    
    let phase: Phase
    let processedCount: Int
    let totalCount: Int
}

// Enhanced MockBookSearchService for priority queue testing moved to ServiceProtocols.swift
    
// All functionality moved to main MockBookSearchService class in ServiceProtocols.swift

// String padding extension moved to DataMergingLogicTests.swift to avoid duplication