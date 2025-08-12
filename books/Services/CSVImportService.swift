//
//  CSVImportService.swift
//  books
//
//  Service for handling CSV import operations
//

import Foundation
import SwiftData
import Combine

@MainActor
class CSVImportService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var importProgress: ImportProgress?
    @Published var importResult: ImportResult?
    @Published var isImporting: Bool = false
    
    // MARK: - Background Processing Properties
    @Published var isBackgroundCapable: Bool = true
    @Published var backgroundTaskRemaining: TimeInterval = 0
    
    // MARK: - Private Properties
    private(set) var modelContext: ModelContext
    private let csvParser: CSVParser
    private var importTask: Task<Void, Never>?
    
    // MARK: - Performance Optimization Properties
    private var cachedUserBooks: [UserBook]? = nil
    private var cachedMetadata: [String: BookMetadata] = [:] // Cache by googleBooksID
    private var batchSize: Int { ConcurrentImportConfig.current.databaseBatchSize } // Dynamic batch size
    private let duplicateCheckCache = NSCache<NSString, NSNumber>() // Fast duplicate checking
    
    // MARK: - ISBN Lookup Service
    private let simpleISBNLookupService: SimpleISBNLookupService
    
    // MARK: - Priority Queue System
    private var primaryQueue: [QueuedBook] = []      // Books with ISBNs - process first
    private var fallbackQueue: [QueuedBook] = []     // Books without ISBNs - process second
    private var processedBookIds: Set<UUID> = []     // Track books that were already processed
    private var currentQueuePhase: ImportQueue? = nil // Track which queue is being processed
    
    // MARK: - Background Processing
    private var currentSession: CSVImportSession?
    private var currentColumnMappings: [String: BookField] = [:]
    
    // MARK: - Initialization
    init(modelContext: ModelContext, config: ConcurrentImportConfig = ConcurrentImportConfig.current) {
        self.modelContext = modelContext
        self.csvParser = CSVParser()
        self.simpleISBNLookupService = SimpleISBNLookupService(
            maxConcurrentLookups: config.maxConcurrentLookups,
            batchSize: config.concurrentBatchSize
        )
        
        // Set up background task monitoring
        setupBackgroundTaskObservers()
        
        // Check for resumable imports on initialization
        checkForResumableImport()
    }
    
    // MARK: - Public Interface
    
    /// Parse CSV file and return session for preview
    func parseCSVFile(from url: URL) async throws -> CSVImportSession {
        return try csvParser.parseCSV(from: url)
    }
    
    /// Import books from CSV session with column mappings
    func importBooks(from session: CSVImportSession, columnMappings: [String: BookField]) {
        // Cancel any existing import
        cancelImport()
        
        // Store session and mappings for persistence
        currentSession = session
        currentColumnMappings = columnMappings
        
        // Initialize progress tracking
        var progress = ImportProgress(sessionId: session.id)
        progress.currentStep = .preparing
        progress.startTime = Date()
        
        self.importProgress = progress
        self.isImporting = true
        self.importResult = nil
        
        // Request background task capability
        let backgroundTaskStarted = BackgroundTaskManager.shared.beginBackgroundTask(for: session.id)
        if backgroundTaskStarted {
            print("[CSVImportService] Background task started for import")
        } else {
            print("[CSVImportService] Warning: Could not start background task")
        }
        
        // Save initial import state (with empty queues initially)
        ImportStateManager.shared.saveImportState(
            progress: progress,
            session: session,
            columnMappings: columnMappings,
            primaryQueue: [],
            fallbackQueue: [],
            processedBookIds: processedBookIds,
            currentQueuePhase: currentQueuePhase
        )
        
        // Start import task
        importTask = Task {
            await performImport(session: session, columnMappings: columnMappings)
        }
    }
    
    /// Cancel the current import operation
    func cancelImport() {
        importTask?.cancel()
        importTask = nil
        
        if var progress = importProgress {
            progress.isCancelled = true
            progress.currentStep = .cancelled
            progress.endTime = Date()
            importProgress = progress
        }
        
        isImporting = false
    }
    
    /// Reset import state
    func resetImport() {
        importProgress = nil
        importResult = nil
        isImporting = false
        importTask = nil
        currentSession = nil
        currentColumnMappings = [:]
        
        // Clear caches
        cachedUserBooks = nil
        cachedMetadata.removeAll()
        duplicateCheckCache.removeAllObjects()
        
        // Clear queues
        primaryQueue.removeAll()
        fallbackQueue.removeAll()
        
        // Reset lookup service statistics
        simpleISBNLookupService.resetStats()
        
        // Clear persisted state
        ImportStateManager.shared.clearImportState()
        
        // End background task
        BackgroundTaskManager.shared.endBackgroundTask()
    }
    
    /// Resume import from persisted state
    func resumeImportIfAvailable() -> Bool {
        guard let resumableInfo = ImportStateManager.shared.getResumableImportInfo(),
              ImportStateManager.shared.canResumeImport(),
              let state = ImportStateManager.shared.loadImportState() else {
            return false
        }
        
        print("[CSVImportService] Resuming import for session: \(resumableInfo.sessionId)")
        
        // Restore session and mappings
        currentSession = state.session
        currentColumnMappings = state.columnMappings
        
        // Restore processed books tracking
        processedBookIds = state.processedBookIds ?? []
        currentQueuePhase = state.currentQueuePhase
        
        // Restore queues with processed books filtered out
        if let savedPrimaryQueue = state.primaryQueue {
            primaryQueue = savedPrimaryQueue.filter { !processedBookIds.contains($0.parsedBook.id) }
            print("[CSVImportService] Restored primary queue: \(primaryQueue.count) remaining")
        }
        if let savedFallbackQueue = state.fallbackQueue {
            fallbackQueue = savedFallbackQueue.filter { !processedBookIds.contains($0.parsedBook.id) }
            print("[CSVImportService] Restored fallback queue: \(fallbackQueue.count) remaining")
        }
        
        // Restore progress
        importProgress = state.progress
        isImporting = true
        
        // Request background task capability
        _ = BackgroundTaskManager.shared.beginBackgroundTask(for: resumableInfo.sessionId)
        
        // Resume the import from where it left off
        importTask = Task {
            await performImport(session: state.session, columnMappings: state.columnMappings, resume: true)
        }
        
        return true
    }
    
    // MARK: - Private Implementation
    
    private func performImport(session: CSVImportSession, columnMappings: [String: BookField], resume: Bool = false) async {
        var progress = importProgress!
        var errors: [ImportError] = []
        var importedBookIds: [UUID] = []
        var successCount = 0
        var duplicateCount = 0
        var duplicatesISBN = 0
        var duplicatesGoogleID = 0
        var duplicatesTitleAuthor = 0
        var failCount = 0
        var apiSuccessCount = 0
        var apiFallbackCount = 0
        
        do {
            // Step 1: Parse CSV into books and populate queues
            if !resume || (primaryQueue.isEmpty && fallbackQueue.isEmpty) {
                progress.currentStep = .parsing
                progress.message = "Parsing CSV file (\(session.totalRows) rows) and organizing into priority queues..."
                importProgress = progress
                
                let parsedBooks = csvParser.parseBooks(from: session, columnMappings: columnMappings)
                progress.totalBooks = parsedBooks.count
                
                // Split books into priority queues
                await populateQueues(from: parsedBooks, errors: &errors, failCount: &failCount)
                
                // Update progress with queue information
                progress.primaryQueueSize = primaryQueue.count
                progress.fallbackQueueSize = fallbackQueue.count
                progress.message = "Organized books: \(primaryQueue.count) with ISBN (primary), \(fallbackQueue.count) without ISBN (fallback)"
                importProgress = progress
                
                // Save queue state for resume capability
                ImportStateManager.shared.updateProgress(
                    progress,
                    primaryQueue: primaryQueue,
                    fallbackQueue: fallbackQueue,
                    processedBookIds: processedBookIds,
                    currentQueuePhase: currentQueuePhase
                )
                
                // Small delay to show parsing step
                try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            }
            
            // Check if cancelled
            if Task.isCancelled {
                progress.isCancelled = true
                progress.currentStep = .cancelled
                progress.endTime = Date()
                importProgress = progress
                isImporting = false
                return
            }
            
            // Step 2: Validate and prepare caches
            progress.currentStep = .validating
            progress.message = "Loading existing library for duplicate checking..."
            importProgress = progress
            
            // Pre-fetch all existing UserBooks for efficient duplicate checking
            if cachedUserBooks == nil {
                cachedUserBooks = try await fetchAllUserBooks()
                progress.message = "Loaded \(cachedUserBooks?.count ?? 0) existing books for duplicate checking"
                importProgress = progress
            }
            
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            // Check if cancelled
            if Task.isCancelled {
                progress.isCancelled = true
                progress.currentStep = .cancelled
                progress.endTime = Date()
                importProgress = progress
                isImporting = false
                return
            }
            
            // Step 3: Process priority queues
            progress.currentStep = .importing
            importProgress = progress
            
            let batchStartTime = Date()
            var booksToInsert: [UserBook] = []
            var metadataToInsert: [BookMetadata] = []
            
            // Process primary queue first (books with ISBNs)
            if !primaryQueue.isEmpty {
                currentQueuePhase = .primary // Track current phase for resume
                progress.currentQueueType = .primary
                progress.message = "Processing primary queue: \(primaryQueue.count) books with ISBNs (fast lookups)..."
                importProgress = progress
                
                await processPrimaryQueue(
                    progress: &progress,
                    errors: &errors,
                    booksToInsert: &booksToInsert,
                    metadataToInsert: &metadataToInsert,
                    successCount: &successCount,
                    duplicateCount: &duplicateCount,
                    duplicatesISBN: &duplicatesISBN,
                    duplicatesGoogleID: &duplicatesGoogleID,
                    duplicatesTitleAuthor: &duplicatesTitleAuthor,
                    failCount: &failCount,
                    apiSuccessCount: &apiSuccessCount,
                    apiFallbackCount: &apiFallbackCount,
                    importedBookIds: &importedBookIds,
                    batchStartTime: batchStartTime
                )
            }
            
            // Process fallback queue second (books without ISBNs)
            if !fallbackQueue.isEmpty {
                currentQueuePhase = .fallback // Track current phase for resume
                progress.currentQueueType = .fallback
                progress.message = "Processing fallback queue: \(fallbackQueue.count) books without ISBNs (title/author search)..."
                importProgress = progress
                
                await processFallbackQueue(
                    progress: &progress,
                    errors: &errors,
                    booksToInsert: &booksToInsert,
                    metadataToInsert: &metadataToInsert,
                    successCount: &successCount,
                    duplicateCount: &duplicateCount,
                    duplicatesISBN: &duplicatesISBN,
                    duplicatesGoogleID: &duplicatesGoogleID,
                    duplicatesTitleAuthor: &duplicatesTitleAuthor,
                    failCount: &failCount,
                    apiSuccessCount: &apiSuccessCount,
                    apiFallbackCount: &apiFallbackCount,
                    importedBookIds: &importedBookIds,
                    batchStartTime: batchStartTime
                )
            }
            
            // Step 4: Complete
            progress.currentStep = .completing
            progress.currentQueueType = nil
            progress.message = "Finalizing import..."
            importProgress = progress
            
            try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            
            // Save any pending changes with proper error handling
            do {
                try modelContext.save()
            } catch {
                let saveError = ImportError(
                    rowIndex: nil,
                    bookTitle: nil,
                    errorType: .storageError,
                    message: "Failed to save imported books: \(error.localizedDescription)",
                    suggestions: ["Check device storage space", "Close other apps to free memory", "Try importing smaller batches"]
                )
                errors.append(saveError)
                progress.currentStep = .failed
                progress.endTime = Date()
                progress.errors = errors
                importProgress = progress
                isImporting = false
                return
            }
            
            progress.currentStep = .completed
            progress.endTime = Date()
            
        } catch {
            let importError = ImportError(
                rowIndex: nil,
                bookTitle: nil,
                errorType: .fileError,
                message: "Import failed: \(error.localizedDescription)",
                suggestions: ["Check file format", "Try with a smaller file", "Verify file permissions", "Ensure stable internet connection"]
            )
            errors.append(importError)
            
            progress.currentStep = .failed
            progress.endTime = Date()
            progress.errors = errors
        }
        
        // Finalize with enhanced results
        importProgress = progress
        
        if let endTime = progress.endTime, let startTime = progress.startTime {
            let duration = endTime.timeIntervalSince(startTime)
            
            // Get service statistics
            let lookupService = simpleISBNLookupService
            let performanceStats = await lookupService.getPerformanceStats()
            
            // Update final progress message with performance summary
            let perfStats = performanceStats
            let booksPerSecond = duration > 0 ? Double(successCount) / duration : 0
            progress.message = "Import completed! \(Int(booksPerSecond * 60)) books/min, \(Int(perfStats.successRate * 100))% API success rate, \(Int(perfStats.rateLimitRate * 100))% rate limited"
            
            importResult = ImportResult(
                sessionId: session.id,
                totalBooks: progress.totalBooks,
                successfulImports: successCount,
                failedImports: failCount,
                duplicatesSkipped: duplicateCount,
                duplicatesISBN: duplicatesISBN,
                duplicatesGoogleID: duplicatesGoogleID,
                duplicatesTitleAuthor: duplicatesTitleAuthor,
                duration: duration,
                errors: errors,
                importedBookIds: importedBookIds,
                retryAttempts: lookupService.totalLookups,
                successfulRetries: lookupService.successfulLookups,
                failedRetries: lookupService.failedLookups,
                maxRetryAttempts: 3, // Our max retry attempts per book
                circuitBreakerTriggered: false,
                finalFailureReasons: [:]
            )
        }
        
        isImporting = false
    }
    
    // MARK: - Queue Management
    
    /// Populate priority queues from parsed books
    private func populateQueues(from parsedBooks: [ParsedBook], errors: inout [ImportError], failCount: inout Int) async {
        primaryQueue.removeAll()
        fallbackQueue.removeAll()
        
        for parsedBook in parsedBooks {
            // Validate book first
            guard parsedBook.isValid else {
                let error = ImportError(
                    rowIndex: parsedBook.rowIndex,
                    bookTitle: parsedBook.title,
                    errorType: .validationError,
                    message: "Invalid book data: \(parsedBook.validationErrors.joined(separator: ", "))",
                    suggestions: ["Check that title and author are not empty", "Verify data format matches expected values"]
                )
                errors.append(error)
                failCount += 1
                continue
            }
            
            // Check if book has ISBN for primary queue
            if let isbn = parsedBook.isbn, !isbn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let queuedBook = QueuedBook(parsedBook: parsedBook, queueType: .primary)
                primaryQueue.append(queuedBook)
            } else {
                let queuedBook = QueuedBook(parsedBook: parsedBook, queueType: .fallback)
                fallbackQueue.append(queuedBook)
            }
        }
    }
    
    // MARK: - Result Types
    
    private enum ImportBookResult {
        case success(UUID)
        case duplicate
        case failure(ImportError)
    }
    
    private struct ImportBookData {
        let userBook: UserBook
        let metadata: BookMetadata
        let isNewMetadata: Bool
        let fromAPI: Bool
    }
    
    private enum OptimizedImportResult {
        case success(ImportBookData)
        case duplicate(DuplicateDetectionService.DuplicateDetectionMethod)
        case failure(ImportError)
    }
    
    // MARK: - Primary Queue Processing (ISBN-based)
    
    /// Process primary queue (books with ISBNs) using concurrent SimpleISBNLookupService
    private func processPrimaryQueue(
        progress: inout ImportProgress,
        errors: inout [ImportError],
        booksToInsert: inout [UserBook],
        metadataToInsert: inout [BookMetadata],
        successCount: inout Int,
        duplicateCount: inout Int,
        duplicatesISBN: inout Int,
        duplicatesGoogleID: inout Int,
        duplicatesTitleAuthor: inout Int,
        failCount: inout Int,
        apiSuccessCount: inout Int,
        apiFallbackCount: inout Int,
        importedBookIds: inout [UUID],
        batchStartTime: Date
    ) async {
        
        guard !primaryQueue.isEmpty else { return }
        
        // Extract ISBNs for concurrent processing
        let isbnsToLookup = primaryQueue.compactMap { queuedBook in
            queuedBook.parsedBook.isbn?.trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter { !$0.isEmpty }
        
        if isbnsToLookup.isEmpty {
            // No valid ISBNs, process individually
            await processPrimaryQueueSequentially(
                progress: &progress,
                errors: &errors,
                booksToInsert: &booksToInsert,
                metadataToInsert: &metadataToInsert,
                successCount: &successCount,
                duplicateCount: &duplicateCount,
                duplicatesISBN: &duplicatesISBN,
                duplicatesGoogleID: &duplicatesGoogleID,
                duplicatesTitleAuthor: &duplicatesTitleAuthor,
                failCount: &failCount,
                apiSuccessCount: &apiSuccessCount,
                apiFallbackCount: &apiFallbackCount,
                importedBookIds: &importedBookIds,
                batchStartTime: batchStartTime
            )
            return
        }
        
        // Update progress message for concurrent processing
        let config = ConcurrentImportConfig.current
        let concurrencyInfo = "up to \(config.maxConcurrentLookups) concurrent"
        let rateLimitInfo = config.useRateLimiting ? "rate-limited @\(config.apiRequestsPerSecond)/s" : "unlimited"
        progress.message = "Primary queue: Processing \(isbnsToLookup.count) ISBNs concurrently (\(concurrencyInfo), \(rateLimitInfo))..."
        importProgress = progress
        
        // Process ISBNs concurrently using the enhanced lookup service
        let lookupResults = await simpleISBNLookupService.lookupISBNs(isbnsToLookup) { [self] completed, total in
            // Update progress during concurrent lookup with performance info
            let partialProgress = Double(completed) / Double(total)
            let successRate = simpleISBNLookupService.successRate
            let rateLimitRate = simpleISBNLookupService.rateLimitRate
            var currentProgress = importProgress ?? ImportProgress(sessionId: UUID())
            currentProgress.message = "Primary queue: \(completed)/\(total) ISBNs (\(Int(partialProgress * 100))%) | Success: \(Int(successRate * 100))% | Rate limited: \(Int(rateLimitRate * 100))%"
            importProgress = currentProgress
        }
        
        // Process results and match them back to original books
        await processConcurrentLookupResults(
            lookupResults: lookupResults,
            originalQueue: primaryQueue,
            progress: &progress,
            errors: &errors,
            booksToInsert: &booksToInsert,
            metadataToInsert: &metadataToInsert,
            successCount: &successCount,
            duplicateCount: &duplicateCount,
            duplicatesISBN: &duplicatesISBN,
            duplicatesGoogleID: &duplicatesGoogleID,
            duplicatesTitleAuthor: &duplicatesTitleAuthor,
            failCount: &failCount,
            apiSuccessCount: &apiSuccessCount,
            importedBookIds: &importedBookIds
        )
        
        // Save any remaining books
        if !booksToInsert.isEmpty {
            await saveBatch(&booksToInsert, &metadataToInsert, &errors, &failCount, &successCount)
        }
        
        // Clear processed books from primary queue
        primaryQueue.removeAll()
    }
    
    /// Process concurrent lookup results and match them to original books
    private func processConcurrentLookupResults(
        lookupResults: [Result<BookMetadata, BookSearchService.BookError>],
        originalQueue: [QueuedBook],
        progress: inout ImportProgress,
        errors: inout [ImportError],
        booksToInsert: inout [UserBook],
        metadataToInsert: inout [BookMetadata],
        successCount: inout Int,
        duplicateCount: inout Int,
        duplicatesISBN: inout Int,
        duplicatesGoogleID: inout Int,
        duplicatesTitleAuthor: inout Int,
        failCount: inout Int,
        apiSuccessCount: inout Int,
        importedBookIds: inout [UUID]
    ) async {
        
        // Match results back to original queued books
        var resultIndex = 0
        
        for queuedBook in originalQueue {
            // Check for cancellation
            if Task.isCancelled {
                progress.isCancelled = true
                progress.currentStep = .cancelled
                progress.endTime = Date()
                importProgress = progress
                isImporting = false
                return
            }
            
            let parsedBook = queuedBook.parsedBook
            
            // Skip books without ISBN (shouldn't happen in primary queue but safety check)
            guard let isbn = parsedBook.isbn?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !isbn.isEmpty else {
                let error = ImportError(
                    rowIndex: parsedBook.rowIndex,
                    bookTitle: parsedBook.title,
                    errorType: .validationError,
                    message: "Book in primary queue missing ISBN",
                    suggestions: ["Verify CSV data integrity"]
                )
                errors.append(error)
                failCount += 1
                continue
            }
            
            // Get the corresponding lookup result
            guard resultIndex < lookupResults.count else {
                let error = ImportError(
                    rowIndex: parsedBook.rowIndex,
                    bookTitle: parsedBook.title,
                    errorType: .storageError,
                    message: "Missing lookup result for book",
                    suggestions: ["Try importing again"]
                )
                errors.append(error)
                failCount += 1
                continue
            }
            
            let lookupResult = lookupResults[resultIndex]
            resultIndex += 1
            
            do {
                switch lookupResult {
                case .success(let metadata):
                    let result = try await createUserBookFromMetadata(metadata, parsedBook: parsedBook, fromAPI: true)
                    
                    switch result {
                    case .success(let bookData):
                        booksToInsert.append(bookData.userBook)
                        if bookData.isNewMetadata {
                            metadataToInsert.append(bookData.metadata)
                        }
                        importedBookIds.append(bookData.userBook.id)
                        processedBookIds.insert(parsedBook.id) // Track processed book for resume
                        successCount += 1
                        apiSuccessCount += 1
                        progress.primaryQueueProcessed += 1
                        
                    case .duplicate(let method):
                        duplicateCount += 1
                        processedBookIds.insert(parsedBook.id) // Track processed book for resume
                        switch method {
                        case .isbn:
                            duplicatesISBN += 1
                        case .googleBooksID:
                            duplicatesGoogleID += 1
                        case .titleAuthor:
                            duplicatesTitleAuthor += 1
                        }
                        progress.primaryQueueProcessed += 1
                        
                    case .failure(let error):
                        errors.append(error)
                        failCount += 1
                        processedBookIds.insert(parsedBook.id) // Track processed book for resume
                        progress.primaryQueueProcessed += 1
                    }
                    
                case .failure(let lookupError):
                    let error = ImportError(
                        rowIndex: parsedBook.rowIndex,
                        bookTitle: parsedBook.title,
                        errorType: .networkError,
                        message: "Failed to lookup ISBN \(isbn): \(lookupError.localizedDescription)",
                        suggestions: ["Check internet connection", "Verify ISBN is correct", "Try again later"]
                    )
                    errors.append(error)
                    failCount += 1
                    progress.primaryQueueProcessed += 1
                }
                
            } catch {
                let importError = ImportError(
                    rowIndex: parsedBook.rowIndex,
                    bookTitle: parsedBook.title,
                    errorType: .storageError,
                    message: "Failed to process book: \(error.localizedDescription)",
                    suggestions: ["Try importing again", "Check device storage space", "Ensure stable internet connection"]
                )
                errors.append(importError)
                failCount += 1
                progress.primaryQueueProcessed += 1
            }
            
            // Batch processing: Save every batchSize books
            if booksToInsert.count >= batchSize {
                await saveBatch(&booksToInsert, &metadataToInsert, &errors, &failCount, &successCount)
            }
        }
    }
    
    /// Fallback sequential processing for primary queue (used when concurrent processing isn't suitable)
    private func processPrimaryQueueSequentially(
        progress: inout ImportProgress,
        errors: inout [ImportError],
        booksToInsert: inout [UserBook],
        metadataToInsert: inout [BookMetadata],
        successCount: inout Int,
        duplicateCount: inout Int,
        duplicatesISBN: inout Int,
        duplicatesGoogleID: inout Int,
        duplicatesTitleAuthor: inout Int,
        failCount: inout Int,
        apiSuccessCount: inout Int,
        apiFallbackCount: inout Int,
        importedBookIds: inout [UUID],
        batchStartTime: Date
    ) async {
        
        var retryQueue: [QueuedBook] = []
        
        for (index, var queuedBook) in primaryQueue.enumerated() {
            // Check for cancellation
            if Task.isCancelled {
                progress.isCancelled = true
                progress.currentStep = .cancelled
                progress.endTime = Date()
                importProgress = progress
                isImporting = false
                return
            }
            
            let parsedBook = queuedBook.parsedBook
            
            do {
                let result = try await processBookWithISBN(parsedBook)
                
                switch result {
                case .success(let bookData):
                    booksToInsert.append(bookData.userBook)
                    if bookData.isNewMetadata {
                        metadataToInsert.append(bookData.metadata)
                    }
                    importedBookIds.append(bookData.userBook.id)
                    processedBookIds.insert(parsedBook.id) // Track processed book for resume
                    successCount += 1
                    apiSuccessCount += 1
                    progress.primaryQueueProcessed += 1
                    
                case .duplicate(let method):
                    duplicateCount += 1
                    processedBookIds.insert(parsedBook.id) // Track processed book for resume
                    switch method {
                    case .isbn:
                        duplicatesISBN += 1
                    case .googleBooksID:
                        duplicatesGoogleID += 1
                    case .titleAuthor:
                        duplicatesTitleAuthor += 1
                    }
                    progress.primaryQueueProcessed += 1
                    
                case .failure(let error):
                    // Check if we can retry this book
                    if queuedBook.incrementRetry() {
                        // Add to retry queue for later processing
                        retryQueue.append(queuedBook)
                    } else {
                        // Max retries reached
                        errors.append(error)
                        failCount += 1
                        progress.primaryQueueProcessed += 1
                    }
                }
                
            } catch {
                let importError = ImportError(
                    rowIndex: parsedBook.rowIndex,
                    bookTitle: parsedBook.title,
                    errorType: .storageError,
                    message: "Failed to process book: \(error.localizedDescription)",
                    suggestions: ["Try importing again", "Check device storage space", "Ensure stable internet connection"]
                )
                errors.append(importError)
                failCount += 1
                progress.primaryQueueProcessed += 1
            }
            
            // Batch processing: Save every batchSize books
            if booksToInsert.count >= batchSize {
                await saveBatch(&booksToInsert, &metadataToInsert, &errors, &failCount, &successCount)
            }
            
            // Update progress
            updateBatchProgress(
                &progress,
                currentIndex: index + 1,
                totalItems: primaryQueue.count,
                queueType: .primary,
                successCount: successCount,
                duplicateCount: duplicateCount,
                failCount: failCount,
                batchStartTime: batchStartTime
            )
        }
        
        // Save any remaining books
        if !booksToInsert.isEmpty {
            await saveBatch(&booksToInsert, &metadataToInsert, &errors, &failCount, &successCount)
        }
        
        // Process retry queue
        primaryQueue = retryQueue
    }
    // MARK: - Fallback Queue Processing (Title/Author-based)
    
    /// Process fallback queue (books without ISBNs) using title/author search
    private func processFallbackQueue(
        progress: inout ImportProgress,
        errors: inout [ImportError],
        booksToInsert: inout [UserBook],
        metadataToInsert: inout [BookMetadata],
        successCount: inout Int,
        duplicateCount: inout Int,
        duplicatesISBN: inout Int,
        duplicatesGoogleID: inout Int,
        duplicatesTitleAuthor: inout Int,
        failCount: inout Int,
        apiSuccessCount: inout Int,
        apiFallbackCount: inout Int,
        importedBookIds: inout [UUID],
        batchStartTime: Date
    ) async {
        
        var retryQueue: [QueuedBook] = []
        
        for (index, var queuedBook) in fallbackQueue.enumerated() {
            // Check for cancellation
            if Task.isCancelled {
                progress.isCancelled = true
                progress.currentStep = .cancelled
                progress.endTime = Date()
                importProgress = progress
                isImporting = false
                return
            }
            
            let parsedBook = queuedBook.parsedBook
            
            do {
                let result = try await processBookWithTitleAuthor(parsedBook)
                
                switch result {
                case .success(let bookData):
                    booksToInsert.append(bookData.userBook)
                    if bookData.isNewMetadata {
                        metadataToInsert.append(bookData.metadata)
                    }
                    importedBookIds.append(bookData.userBook.id)
                    processedBookIds.insert(parsedBook.id) // Track processed book for resume
                    successCount += 1
                    apiFallbackCount += 1
                    progress.fallbackQueueProcessed += 1
                    
                case .duplicate(let method):
                    duplicateCount += 1
                    processedBookIds.insert(parsedBook.id) // Track processed book for resume
                    switch method {
                    case .isbn:
                        duplicatesISBN += 1
                    case .googleBooksID:
                        duplicatesGoogleID += 1
                    case .titleAuthor:
                        duplicatesTitleAuthor += 1
                    }
                    progress.fallbackQueueProcessed += 1
                    
                case .failure(let error):
                    // Check if we can retry this book
                    if queuedBook.incrementRetry() {
                        // Add to retry queue for later processing
                        retryQueue.append(queuedBook)
                    } else {
                        // Max retries reached
                        errors.append(error)
                        failCount += 1
                        progress.fallbackQueueProcessed += 1
                    }
                }
                
            } catch {
                let importError = ImportError(
                    rowIndex: parsedBook.rowIndex,
                    bookTitle: parsedBook.title,
                    errorType: .storageError,
                    message: "Failed to process book: \(error.localizedDescription)",
                    suggestions: ["Try importing again", "Check device storage space", "Ensure stable internet connection"]
                )
                errors.append(importError)
                failCount += 1
                progress.fallbackQueueProcessed += 1
            }
            
            // Batch processing: Save every batchSize books
            if booksToInsert.count >= batchSize {
                await saveBatch(&booksToInsert, &metadataToInsert, &errors, &failCount, &successCount)
            }
            
            // Update progress
            updateBatchProgress(
                &progress,
                currentIndex: index + 1,
                totalItems: fallbackQueue.count,
                queueType: .fallback,
                successCount: successCount,
                duplicateCount: duplicateCount,
                failCount: failCount,
                batchStartTime: batchStartTime
            )
        }
        
        // Save any remaining books
        if !booksToInsert.isEmpty {
            await saveBatch(&booksToInsert, &metadataToInsert, &errors, &failCount, &successCount)
        }
        
        // Process retry queue
        fallbackQueue = retryQueue
        
        // Clear processed books from fallback queue
        fallbackQueue.removeAll()
    }
    
    // MARK: - Book Processing Methods
    
    /// Process a book using ISBN lookup
    private func processBookWithISBN(_ parsedBook: ParsedBook) async throws -> OptimizedImportResult {
        guard let isbn = parsedBook.isbn, !isbn.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(ImportError(
                rowIndex: parsedBook.rowIndex,
                bookTitle: parsedBook.title,
                errorType: .validationError,
                message: "No ISBN provided for primary queue book",
                suggestions: ["This book should have been placed in fallback queue"]
            ))
        }
        
        let cleanISBN = cleanISBN(isbn)
        
        // Check for duplicates using ISBN first
        if let duplicate = checkForISBNDuplicate(cleanISBN) {
            return .duplicate(duplicate)
        }
        
        // Update progress message
        if var progress = importProgress {
            progress.message = "Primary queue: Looking up ISBN \(cleanISBN)..."
            importProgress = progress
        }
        
        // Use SimpleISBNLookupService for ISBN lookup
        let lookupResult = await simpleISBNLookupService.lookupISBN(cleanISBN)
        
        switch lookupResult {
        case .success(let metadata):
            return try await createUserBookFromMetadata(metadata, parsedBook: parsedBook, fromAPI: true)
            
        case .failure(let error):
            return .failure(ImportError(
                rowIndex: parsedBook.rowIndex,
                bookTitle: parsedBook.title,
                errorType: .networkError,
                message: "Failed to lookup ISBN \(cleanISBN): \(error.localizedDescription)",
                suggestions: ["Check internet connection", "Verify ISBN is correct", "Try again later"]
            ))
        }
    }
    
    /// Process a book using title/author search
    private func processBookWithTitleAuthor(_ parsedBook: ParsedBook) async throws -> OptimizedImportResult {
        guard let title = parsedBook.title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let author = parsedBook.author, !author.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(ImportError(
                rowIndex: parsedBook.rowIndex,
                bookTitle: parsedBook.title,
                errorType: .validationError,
                message: "Missing title or author for fallback queue book",
                suggestions: ["Ensure title and author are present in CSV"]
            ))
        }
        
        // Check for duplicates using title/author first
        if let duplicate = checkForTitleAuthorDuplicate(title: title, author: author) {
            return .duplicate(duplicate)
        }
        
        // Update progress message
        if var progress = importProgress {
            progress.message = "Fallback queue: Searching for \"\(title)\" by \(author)..."
            importProgress = progress
        }
        
        // Search using title and author
        let searchQuery = "\(title) \(author)"
        let searchResult = await BookSearchService.shared.search(
            query: searchQuery,
            sortBy: .relevance,
            maxResults: 1,
            includeTranslations: true
        )
        
        switch searchResult {
        case .success(let books):
            if let firstBook = books.first {
                return try await createUserBookFromMetadata(firstBook, parsedBook: parsedBook, fromAPI: true)
            } else {
                return .failure(ImportError(
                    rowIndex: parsedBook.rowIndex,
                    bookTitle: parsedBook.title,
                    errorType: .networkError,
                    message: "No results found for \"\(title)\" by \(author)",
                    suggestions: ["Check spelling of title and author", "Book may not be in Google Books database", "Add ISBN if available"]
                ))
            }
            
        case .failure(let error):
            return .failure(ImportError(
                rowIndex: parsedBook.rowIndex,
                bookTitle: parsedBook.title,
                errorType: .networkError,
                message: "Failed to search for \"\(title)\" by \(author): \(error.localizedDescription)",
                suggestions: ["Check internet connection", "Try again later"]
            ))
        }
    }
    
    // MARK: - Helper Methods
    
    /// Clean ISBN by removing formatting characters
    private func cleanISBN(_ isbn: String) -> String {
        return isbn
            .replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Check for duplicate using ISBN
    private func checkForISBNDuplicate(_ cleanISBN: String) -> DuplicateDetectionService.DuplicateDetectionMethod? {
        let existingBooks = cachedUserBooks ?? []
        for existingBook in existingBooks {
            if let existingISBN = existingBook.metadata?.isbn?.replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: ""),
               existingISBN == cleanISBN {
                return .isbn
            }
        }
        return nil
    }
    
    /// Check for duplicate using title and author
    private func checkForTitleAuthorDuplicate(title: String, author: String) -> DuplicateDetectionService.DuplicateDetectionMethod? {
        let existingBooks = cachedUserBooks ?? []
        let normalizedTitle = title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedAuthor = author.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        for existingBook in existingBooks {
            if let existingTitle = existingBook.metadata?.title.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
               let existingAuthor = existingBook.metadata?.authors.first?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
               existingTitle == normalizedTitle && existingAuthor == normalizedAuthor {
                return .titleAuthor
            }
        }
        return nil
    }
    
    /// Create UserBook from BookMetadata and ParsedBook data
    private func createUserBookFromMetadata(_ metadata: BookMetadata, parsedBook: ParsedBook, fromAPI: Bool) async throws -> OptimizedImportResult {
        // Check for Google Books ID duplicates
        let googleBooksIDToFind = metadata.googleBooksID
        let existingBooks = cachedUserBooks ?? []
        for existingBook in existingBooks {
            if existingBook.metadata?.googleBooksID == googleBooksIDToFind {
                return .duplicate(.googleBooksID)
            }
        }
        
        // Determine reading status from CSV
        let readingStatus: ReadingStatus
        if let statusString = parsedBook.readingStatus {
            readingStatus = GoodreadsColumnMappings.mapReadingStatus(statusString)
        } else {
            readingStatus = .toRead
        }
        
        // Check if metadata with this googleBooksID already exists in cache or context
        var finalMetadata: BookMetadata
        var isNewMetadata = false
        
        // Check cached metadata first
        if let cached = cachedMetadata[googleBooksIDToFind] {
            finalMetadata = cached
        } else {
            // Check in context
            let existingMetadataQuery = FetchDescriptor<BookMetadata>(
                predicate: #Predicate<BookMetadata> { bookMetadata in
                    bookMetadata.googleBooksID == googleBooksIDToFind
                }
            )
            
            if let existing = try? modelContext.fetch(existingMetadataQuery).first {
                finalMetadata = existing
                // Cache it
                cachedMetadata[googleBooksIDToFind] = existing
            } else {
                // New metadata
                finalMetadata = metadata
                isNewMetadata = true
                // Cache it
                cachedMetadata[googleBooksIDToFind] = metadata
            }
        }
        
        // Create UserBook with user data from CSV and metadata from API
        let userBook = UserBook(
            dateAdded: parsedBook.dateAdded ?? Date(),
            readingStatus: readingStatus,
            rating: parsedBook.rating,
            notes: parsedBook.personalNotes,
            tags: parsedBook.tags,
            metadata: finalMetadata
        )
        
        // Set date completed if book is read
        if readingStatus == .read {
            userBook.dateCompleted = parsedBook.dateRead ?? Date()
        }
        
        return .success(ImportBookData(
            userBook: userBook,
            metadata: finalMetadata,
            isNewMetadata: isNewMetadata,
            fromAPI: fromAPI
        ))
    }
    
    /// Save batch of books and metadata
    private func saveBatch(
        _ booksToInsert: inout [UserBook],
        _ metadataToInsert: inout [BookMetadata],
        _ errors: inout [ImportError],
        _ failCount: inout Int,
        _ successCount: inout Int
    ) async {
        // Insert metadata first
        for metadata in metadataToInsert {
            modelContext.insert(metadata)
        }
        
        // Then insert UserBooks
        for userBook in booksToInsert {
            modelContext.insert(userBook)
        }
        
        // Save the batch
        do {
            try modelContext.save()
            // Update cached books with new additions
            cachedUserBooks?.append(contentsOf: booksToInsert)
        } catch {
            // Handle batch save error
            let batchErrorCount = booksToInsert.count
            for book in booksToInsert {
                let importError = ImportError(
                    rowIndex: nil,
                    bookTitle: book.metadata?.title,
                    errorType: .storageError,
                    message: "Failed to save batch: \(error.localizedDescription)",
                    suggestions: ["Check device storage", "Try smaller import batches"]
                )
                errors.append(importError)
            }
            failCount += batchErrorCount
            successCount -= batchErrorCount
        }
        
        // Clear batch arrays
        booksToInsert.removeAll()
        metadataToInsert.removeAll()
    }
    
    /// Update progress during batch processing
    private func updateBatchProgress(
        _ progress: inout ImportProgress,
        currentIndex: Int,
        totalItems: Int,
        queueType: ImportQueue,
        successCount: Int,
        duplicateCount: Int,
        failCount: Int,
        batchStartTime: Date
    ) {
        let batchElapsed = Date().timeIntervalSince(batchStartTime)
        let estimatedRemaining: TimeInterval
        
        if currentIndex > 0 && batchElapsed > 0 {
            let avgTimePerBook = batchElapsed / Double(currentIndex)
            let remaining = avgTimePerBook * Double(totalItems - currentIndex)
            // Cap the estimated time to 24 hours to prevent overflow
            estimatedRemaining = min(remaining, 24 * 60 * 60)
        } else {
            estimatedRemaining = 0
        }
        
        progress.processedBooks = (progress.primaryQueueProcessed + progress.fallbackQueueProcessed)
        progress.successfulImports = successCount
        progress.duplicatesSkipped = duplicateCount
        progress.failedImports = failCount
        progress.estimatedTimeRemaining = estimatedRemaining
        
        // Create progress message with queue information
        let progressPercent = Double(currentIndex) / Double(totalItems) * 100.0
        progress.message = "\(queueType.displayName): \(currentIndex)/\(totalItems) (\(Int(progressPercent))%) - \(progress.queueProgressSummary)"
        
        importProgress = progress
        
        // Periodically save progress with queue state (every 10 books)
        if currentIndex % 10 == 0 {
            ImportStateManager.shared.updateProgress(
                progress,
                primaryQueue: primaryQueue,
                fallbackQueue: fallbackQueue,
                processedBookIds: processedBookIds,
                currentQueuePhase: currentQueuePhase
            )
        }
    }
    
    /// Fetch all UserBooks from the model context for duplicate checking (with caching)
    private func fetchAllUserBooks() async throws -> [UserBook] {
        // Return cached books if available
        if let cached = cachedUserBooks {
            return cached
        }
        
        // Otherwise fetch and cache
        let descriptor = FetchDescriptor<UserBook>()
        let books = try modelContext.fetch(descriptor)
        cachedUserBooks = books
        return books
    }
    
    // REMOVED: createTempMetadataForDuplicateCheck - Not needed since we only process books with ISBN
    
    // MARK: - Background Processing Support
    
    /// Set up observers for background task events
    private func setupBackgroundTaskObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBackgroundTaskWillExpire),
            name: .backgroundTaskWillExpire,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShouldResumePendingImports),
            name: .shouldResumePendingImports,
            object: nil
        )
    }
    
    @objc private func handleBackgroundTaskWillExpire() {
        print("[CSVImportService] Background task will expire - saving critical state")
        
        // Update progress with background expiration message
        if var progress = importProgress {
            progress.message = "Import paused - background time expired. Tap to resume when app reopens."
            importProgress = progress
            
            // Save current progress
            ImportStateManager.shared.updateProgress(
                progress,
                primaryQueue: primaryQueue,
                fallbackQueue: fallbackQueue,
                processedBookIds: processedBookIds,
                currentQueuePhase: currentQueuePhase
            )
        }
        
        // Gracefully pause the import
        pauseImportForBackground()
    }
    
    @objc private func handleShouldResumePendingImports() {
        print("[CSVImportService] Checking for pending imports to resume")
        _ = resumeImportIfAvailable()
    }
    
    /// Check for resumable import on service initialization
    private func checkForResumableImport() {
        // Check if there's a resumable import when the service starts
        if ImportStateManager.shared.hasActiveImport {
            print("[CSVImportService] Found resumable import on initialization")
            // Don't auto-resume here - let the UI handle this decision
        }
    }
    
    /// Pause import for background transition
    private func pauseImportForBackground() {
        // The import task will continue running as long as we have background time
        // State is being saved periodically, so we're ready for termination
        print("[CSVImportService] Import paused for background")
    }
    
    /// Get information about resumable import for UI
    func getResumableImportInfo() -> ResumableImportInfo? {
        return ImportStateManager.shared.getResumableImportInfo()
    }
    
    /// Check if import can be resumed
    func canResumeImport() -> Bool {
        return ImportStateManager.shared.canResumeImport()
    }
    
    /// Get current performance statistics
    func getPerformanceStats() async -> PerformanceStats? {
        return await simpleISBNLookupService.getPerformanceStats()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Preview Helpers

extension CSVImportService {
    /// Create sample import session for previews
    static func sampleSession() -> CSVImportSession {
        let sampleColumns = [
            CSVColumn(originalName: "Title", index: 0, mappedField: .title, sampleValues: ["The Great Gatsby", "1984", "To Kill a Mockingbird"]),
            CSVColumn(originalName: "Author", index: 1, mappedField: .author, sampleValues: ["F. Scott Fitzgerald", "George Orwell", "Harper Lee"]),
            CSVColumn(originalName: "My Rating", index: 2, mappedField: .rating, sampleValues: ["5", "4", "5"]),
            CSVColumn(originalName: "Date Read", index: 3, mappedField: .dateRead, sampleValues: ["2023/12/01", "2023/11/15", "2023/10/20"])
        ]
        
        let sampleData = [
            ["Title", "Author", "My Rating", "Date Read"],
            ["The Great Gatsby", "F. Scott Fitzgerald", "5", "2023/12/01"],
            ["1984", "George Orwell", "4", "2023/11/15"],
            ["To Kill a Mockingbird", "Harper Lee", "5", "2023/10/20"]
        ]
        
        return CSVImportSession(
            fileName: "goodreads_library_export.csv",
            fileSize: 15420,
            totalRows: 3,
            detectedColumns: sampleColumns,
            sampleData: sampleData,
            allData: sampleData  // For sample/preview, use same data
        )
    }
}
