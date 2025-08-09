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
    
    // MARK: - Private Properties
    private(set) var modelContext: ModelContext
    private let csvParser: CSVParser
    private var importTask: Task<Void, Never>?
    
    // MARK: - Performance Optimization Properties
    private var cachedUserBooks: [UserBook]? = nil
    private var cachedMetadata: [String: BookMetadata] = [:] // Cache by googleBooksID
    private let batchSize = 50 // Process and save in batches
    private let duplicateCheckCache = NSCache<NSString, NSNumber>() // Fast duplicate checking
    
    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.csvParser = CSVParser()
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
        
        // Initialize progress tracking
        var progress = ImportProgress(sessionId: session.id)
        progress.currentStep = .preparing
        progress.startTime = Date()
        
        self.importProgress = progress
        self.isImporting = true
        self.importResult = nil
        
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
        // Clear caches
        cachedUserBooks = nil
        cachedMetadata.removeAll()
        duplicateCheckCache.removeAllObjects()
    }
    
    // MARK: - Private Implementation
    
    private func performImport(session: CSVImportSession, columnMappings: [String: BookField]) async {
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
            // Step 1: Parse CSV into books
            progress.currentStep = .parsing
            progress.message = "Parsing CSV file (\(session.totalRows) rows)..."
            importProgress = progress
            
            let parsedBooks = csvParser.parseBooks(from: session, columnMappings: columnMappings)
            progress.totalBooks = parsedBooks.count
            importProgress = progress
            
            // Small delay to show parsing step
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            
            // Check if cancelled
            if Task.isCancelled {
                progress.isCancelled = true
                progress.currentStep = .cancelled
                progress.endTime = Date()
                importProgress = progress
                isImporting = false
                return
            }
            
            // Step 2: Validate books and prepare caches
            progress.currentStep = .validating
            progress.message = "Validating book data and loading existing library..."
            importProgress = progress
            
            // Pre-fetch all existing UserBooks for efficient duplicate checking
            if cachedUserBooks == nil {
                cachedUserBooks = try await fetchAllUserBooks()
                progress.message = "Loaded \(cachedUserBooks?.count ?? 0) existing books for duplicate checking"
                importProgress = progress
            }
            
            let validBooks = parsedBooks.filter { book in
                let isValid = book.isValid
                if !isValid {
                    let error = ImportError(
                        rowIndex: book.rowIndex,
                        bookTitle: book.title,
                        errorType: .validationError,
                        message: "Invalid book data: \(book.validationErrors.joined(separator: ", "))",
                        suggestions: ["Check that title and author are not empty", "Verify data format matches expected values"]
                    )
                    errors.append(error)
                    failCount += 1
                }
                return isValid
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
            
            // Step 3: Import books with batch processing and ISBN-first strategy
            progress.currentStep = .importing
            progress.message = "Importing \(validBooks.count) books..."
            importProgress = progress
            
            let batchStartTime = Date()
            var booksToInsert: [UserBook] = []
            var metadataToInsert: [BookMetadata] = []
            
            for (index, parsedBook) in validBooks.enumerated() {
                // Check for cancellation
                if Task.isCancelled {
                    progress.isCancelled = true
                    progress.currentStep = .cancelled
                    progress.endTime = Date()
                    importProgress = progress
                    isImporting = false
                    return
                }
                
                do {
                    let result = try await importSingleBookOptimized(parsedBook)
                    
                    switch result {
                    case .success(let bookData):
                        booksToInsert.append(bookData.userBook)
                        if bookData.isNewMetadata {
                            metadataToInsert.append(bookData.metadata)
                        }
                        importedBookIds.append(bookData.userBook.id)
                        successCount += 1
                        
                        // Track whether we used API or CSV data
                        if parsedBook.isbn != nil && !parsedBook.isbn!.isEmpty && bookData.fromAPI {
                            apiSuccessCount += 1
                        } else {
                            apiFallbackCount += 1
                        }
                        
                    case .duplicate(let method):
                        duplicateCount += 1
                        switch method {
                        case .isbn:
                            duplicatesISBN += 1
                        case .googleBooksID:
                            duplicatesGoogleID += 1
                        case .titleAuthor:
                            duplicatesTitleAuthor += 1
                        }
                    case .failure(let error):
                        errors.append(error)
                        failCount += 1
                    }
                    
                } catch {
                    let importError = ImportError(
                        rowIndex: parsedBook.rowIndex,
                        bookTitle: parsedBook.title,
                        errorType: .storageError,
                        message: "Failed to process book: \(error.localizedDescription)",
                        suggestions: ["Try importing again", "Check device storage space", "Ensure stable internet connection for ISBN lookups"]
                    )
                    errors.append(importError)
                    failCount += 1
                    apiFallbackCount += 1
                }
                
                // Batch processing: Save every batchSize books or at the end
                if booksToInsert.count >= batchSize || index == validBooks.count - 1 {
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
                        for book in booksToInsert {
                            let importError = ImportError(
                                rowIndex: nil,
                                bookTitle: book.metadata?.title,
                                errorType: .storageError,
                                message: "Failed to save batch: \(error.localizedDescription)",
                                suggestions: ["Check device storage", "Try smaller import batches"]
                            )
                            errors.append(importError)
                            failCount += booksToInsert.count
                            successCount -= booksToInsert.count
                        }
                    }
                    
                    // Clear batch arrays
                    booksToInsert.removeAll()
                    metadataToInsert.removeAll()
                }
                
                // Update progress with enhanced stats and timing info
                let batchElapsed = Date().timeIntervalSince(batchStartTime)
                let avgTimePerBook = batchElapsed / Double(index + 1)
                let estimatedRemaining = avgTimePerBook * Double(validBooks.count - index - 1)
                
                progress.processedBooks = index + 1
                progress.successfulImports = successCount
                progress.duplicatesSkipped = duplicateCount
                progress.duplicatesISBN = duplicatesISBN
                progress.duplicatesGoogleID = duplicatesGoogleID
                progress.duplicatesTitleAuthor = duplicatesTitleAuthor
                progress.failedImports = failCount
                progress.errors = errors
                progress.message = "Processing book \(index + 1) of \(validBooks.count) (Est. \(Int(estimatedRemaining))s remaining)"
                progress.estimatedTimeRemaining = estimatedRemaining
                importProgress = progress
                
                // Adaptive delay: less delay for cached operations, more for API calls
                if index % 10 == 0 { // Only delay every 10th book to speed up
                    let delayNanoseconds: UInt64 = parsedBook.isbn != nil ? 100_000_000 : 10_000_000 // 0.1s for API calls, 0.01s otherwise
                    try await Task.sleep(nanoseconds: delayNanoseconds)
                }
            }
            
            // Step 4: Complete
            progress.currentStep = .completing
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
            
            // Create enhanced summary that mentions ISBN strategy
            var enhancedSummary = ""
            if successCount > 0 {
                enhancedSummary += "\(successCount) imported"
                if apiSuccessCount > 0 {
                    enhancedSummary += " (\(apiSuccessCount) with fresh metadata)"
                }
            }
            if duplicateCount > 0 {
                if !enhancedSummary.isEmpty { enhancedSummary += ", " }
                enhancedSummary += "\(duplicateCount) duplicates skipped"
            }
            if failCount > 0 {
                if !enhancedSummary.isEmpty { enhancedSummary += ", " }
                enhancedSummary += "\(failCount) failed"
            }
            
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
                importedBookIds: importedBookIds
            )
        }
        
        isImporting = false
    }
    
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
    
    /// Optimized version of importSingleBook that returns more data for batch processing
    private func importSingleBookOptimized(_ parsedBook: ParsedBook) async throws -> OptimizedImportResult {
        // ONLY process books with valid ISBNs
        guard let isbn = parsedBook.isbn, !isbn.isEmpty else {
            print("[CSV Import] Skipping book without ISBN: \(parsedBook.title ?? "Unknown")")
            return .failure(ImportError(
                rowIndex: parsedBook.rowIndex,
                bookTitle: parsedBook.title,
                errorType: .validationError,
                message: "No ISBN found - cannot verify book identity",
                suggestions: ["Add ISBN to CSV", "Manually add this book through search"]
            ))
        }
        
        let cleanISBN = isbn.replacingOccurrences(of: "-", with: "")
                            .replacingOccurrences(of: " ", with: "")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for duplicates using ISBN
        let existingBooks = cachedUserBooks ?? []
        for existingBook in existingBooks {
            if let existingISBN = existingBook.metadata?.isbn?.replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: ""),
               existingISBN == cleanISBN {
                print("[CSV Import] Duplicate detected by ISBN: \(cleanISBN)")
                return .duplicate(.isbn)
            }
        }
        
        // Update progress message
        if var progress = importProgress {
            progress.message = "Looking up ISBN: \(cleanISBN)..."
            importProgress = progress
        }
        
        // Fetch metadata from API using ISBN
        var bookMetadata: BookMetadata
        var fromAPI = false
        
        // Check metadata cache first
        if let cached = cachedMetadata["isbn:\(cleanISBN)"] {
            bookMetadata = cached
            fromAPI = true
            print("[CSV Import] Using cached metadata for ISBN: \(cleanISBN)")
        } else {
            // Fetch from Google Books API
            do {
                if let apiMetadata = try await fetchMetadataFromISBN(isbn) {
                    // Success! Use API metadata exclusively
                    bookMetadata = apiMetadata
                    fromAPI = true
                    
                    // Cache the metadata
                    cachedMetadata[apiMetadata.googleBooksID] = apiMetadata
                    cachedMetadata["isbn:\(cleanISBN)"] = apiMetadata
                    
                    print("[CSV Import] Successfully fetched metadata for ISBN: \(cleanISBN)")
                } else {
                    // ISBN not found in Google Books
                    print("[CSV Import] ISBN not found in Google Books: \(cleanISBN)")
                    return .failure(ImportError(
                        rowIndex: parsedBook.rowIndex,
                        bookTitle: parsedBook.title,
                        errorType: .networkError,
                        message: "ISBN \(cleanISBN) not found in Google Books",
                        suggestions: ["Verify ISBN is correct", "Book may not be in Google Books database"]
                    ))
                }
            } catch {
                // API error
                print("[CSV Import] API error for ISBN \(cleanISBN): \(error.localizedDescription)")
                return .failure(ImportError(
                    rowIndex: parsedBook.rowIndex,
                    bookTitle: parsedBook.title,
                    errorType: .networkError,
                    message: "Failed to fetch book data: \(error.localizedDescription)",
                    suggestions: ["Check internet connection", "Try again later"]
                ))
            }
        }
        
        // Determine reading status from CSV (user data we trust)
        let readingStatus: ReadingStatus
        if let statusString = parsedBook.readingStatus {
            readingStatus = GoodreadsColumnMappings.mapReadingStatus(statusString)
        } else {
            readingStatus = .toRead
        }
        
        // Check if metadata with this googleBooksID already exists in cache or context
        let googleBooksIDToFind = bookMetadata.googleBooksID
        var finalMetadata: BookMetadata
        var isNewMetadata = false
        
        // Check cached metadata first
        if let cached = cachedMetadata[googleBooksIDToFind] {
            finalMetadata = cached
        } else {
            // Check in context
            let existingMetadataQuery = FetchDescriptor<BookMetadata>(
                predicate: #Predicate<BookMetadata> { metadata in
                    metadata.googleBooksID == googleBooksIDToFind
                }
            )
            
            if let existing = try? modelContext.fetch(existingMetadataQuery).first {
                finalMetadata = existing
                // Cache it
                cachedMetadata[googleBooksIDToFind] = existing
            } else {
                // New metadata - will be inserted in batch
                finalMetadata = bookMetadata
                isNewMetadata = true
                // Cache it
                cachedMetadata[googleBooksIDToFind] = bookMetadata
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
        
        // Set date completed if book is read (user data from CSV)
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
    // REMOVED: Old importSingleBook method - We only use the optimized version that requires ISBN
    
    /// Fetch fresh metadata from Google Books API using ISBN
    private func fetchMetadataFromISBN(_ isbn: String) async throws -> BookMetadata? {
        // Clean ISBN (remove hyphens, spaces)
        let cleanISBN = isbn.replacingOccurrences(of: "-", with: "")
                            .replacingOccurrences(of: " ", with: "")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Add logging for debugging
        print("[CSV Import] Searching for book with ISBN: \(cleanISBN)")
        
        // Rate limiting: add small delay to avoid hitting API limits
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Pass clean ISBN without prefix - let BookSearchService handle formatting
        let searchResult = await BookSearchService.shared.search(query: cleanISBN)
        
        switch searchResult {
        case .success(let books):
            if let book = books.first {
                print("[CSV Import] Found book via ISBN: \(book.title) - Has image: \(book.imageURL != nil)")
                return book
            } else {
                print("[CSV Import] No results for ISBN: \(cleanISBN)")
                return nil
            }
        case .failure(let error):
            print("[CSV Import] ISBN search failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    // REMOVED: fetchMetadataByTitleAuthor - We only trust ISBN lookups
    // REMOVED: findBestMatch - No title/author fuzzy matching needed
    // REMOVED: calculateTitleSimilarity - Not needed without title matching
    // REMOVED: normalizeForComparison - Not needed without text matching
    // REMOVED: enrichMetadataWithCSVData - We don't mix CSV data with API data
    // REMOVED: createMetadataFromCSV - We never create metadata from CSV
    
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
