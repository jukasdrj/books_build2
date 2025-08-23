// CSVImportService Integration with Batch API Support
// This shows how to integrate the new batch functionality into your existing CSV import service

import Foundation
import SwiftData

extension CSVImportService {
    
    // MARK: - Enhanced Import with Batch Processing
    
    /// Enhanced import method that uses batch API for improved performance
    func importBooksWithBatchOptimization(
        from session: CSVImportSession, 
        columnMappings: [String: BookField]
    ) {
        // Cancel any existing import
        cancelImport()
        
        // Store session and mappings for persistence
        currentSession = session
        currentColumnMappings = columnMappings
        
        // Initialize progress tracking
        var progress = ImportProgress(sessionId: session.id)
        progress.currentStep = .preparing
        progress.startTime = Date()
        progress.useBatchAPI = true // Flag for batch processing
        
        self.importProgress = progress
        self.isImporting = true
        self.importResult = nil
        
        // Post notification that import has started
        NotificationCenter.default.post(
            name: .csvImportDidStart,
            object: self,
            userInfo: ["session": session, "batchMode": true]
        )
        
        // Request background task capability
        let backgroundTaskStarted = BackgroundTaskManager.shared.beginBackgroundTask(for: session.id)
        if backgroundTaskStarted {
            print("[CSVImportService] Background task started for batch import")
        }
        
        // Start batch import task
        importTask = Task {
            await performBatchImport(session: session, columnMappings: columnMappings)
        }
    }
    
    /// Main batch import processing
    private func performBatchImport(
        session: CSVImportSession,
        columnMappings: [String: BookField]
    ) async {
        do {
            // Step 1: Parse and validate CSV data
            await updateProgress(step: .parsing, message: "Parsing CSV data...")
            
            let csvBooks = try await parseCSVData(session: session, columnMappings: columnMappings)
            
            await updateProgress(step: .validating, message: "Validating book data...")
            
            // Step 2: Separate books with and without ISBNs for optimal processing
            let (booksWithISBN, booksWithoutISBN) = separateBooksByISBN(csvBooks)
            
            await updateProgress(
                step: .processing, 
                message: "Processing \(booksWithISBN.count) books with ISBN via batch API..."
            )
            
            // Step 3: Batch process books with ISBNs (primary queue)
            var allResults: [ProcessedBook] = []
            
            if !booksWithISBN.isEmpty {
                let batchResults = await processBooksWithBatchAPI(booksWithISBN)
                allResults.append(contentsOf: batchResults)
            }
            
            // Step 4: Process books without ISBNs individually (fallback queue)
            if !booksWithoutISBN.isEmpty {
                await updateProgress(
                    step: .processing, 
                    message: "Processing \(booksWithoutISBN.count) books without ISBN individually..."
                )
                
                let individualResults = await processBooksIndividually(booksWithoutISBN)
                allResults.append(contentsOf: individualResults)
            }
            
            // Step 5: Save to database in batches
            await updateProgress(step: .saving, message: "Saving books to library...")
            await saveBooksToDatabase(allResults)
            
            // Step 6: Complete import
            await completeImport(
                totalBooks: csvBooks.count,
                successfulBooks: allResults.filter { $0.success }.count,
                failedBooks: allResults.filter { !$0.success }.count
            )
            
        } catch {
            await handleImportError(error)
        }
    }
    
    /// Process books with ISBNs using the new batch API
    private func processBooksWithBatchAPI(_ csvBooks: [CSVBookData]) async -> [ProcessedBook] {
        var processedBooks: [ProcessedBook] = []
        
        // Process in optimal batch sizes
        let batchSize = BookSearchService.BatchConfig.csvImportBatchSize
        let batches = csvBooks.chunked(into: batchSize)
        
        for (batchIndex, batch) in batches.enumerated() {
            let batchProgress = Double(batchIndex) / Double(batches.count)
            
            await updateProgress(
                step: .processing,
                message: "Processing batch \(batchIndex + 1) of \(batches.count)...",
                percentage: batchProgress
            )
            
            // Use BookSearchService batch lookup
            let batchResults = await BookSearchService.shared.batchLookupForCSVImport(batch) { batchProgress in
                Task { @MainActor in
                    // Update fine-grained progress within batch
                    let overallProgress = (Double(batchIndex) + batchProgress.percentage) / Double(batches.count)
                    self.updateProgressSync(percentage: overallProgress)
                }
            }
            
            // Convert batch results to ProcessedBook format
            for (csvBook, lookupResult) in zip(batch, batchResults) {
                let processedBook = createProcessedBook(
                    from: csvBook,
                    lookupResult: lookupResult
                )
                processedBooks.append(processedBook)
                
                // Update running statistics
                await updateRunningStatistics(processedBook)
            }
            
            // Add small delay between batches to be respectful to the API
            if batchIndex < batches.count - 1 {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
            }
        }
        
        return processedBooks
    }
    
    /// Process books without ISBNs using individual title/author search
    private func processBooksIndividually(_ csvBooks: [CSVBookData]) async -> [ProcessedBook] {
        var processedBooks: [ProcessedBook] = []
        
        for (index, csvBook) in csvBooks.enumerated() {
            let progress = Double(index) / Double(csvBooks.count)
            
            await updateProgress(
                step: .processing,
                message: "Searching for \"\(csvBook.title)\"...",
                percentage: progress
            )
            
            // Search by title and author
            let searchQuery = buildSearchQuery(from: csvBook)
            let searchResult = await BookSearchService.shared.searchWithFallback(
                query: searchQuery,
                maxResults: 3,
                includeTranslations: true
            )
            
            let processedBook: ProcessedBook
            
            switch searchResult {
            case .success(let books):
                if let bestMatch = findBestMatch(csvBook: csvBook, searchResults: books) {
                    processedBook = createProcessedBook(
                        from: csvBook,
                        bookMetadata: bestMatch,
                        source: "title-author-search"
                    )
                } else {
                    processedBook = createProcessedBook(
                        from: csvBook,
                        error: "No matching books found"
                    )
                }
                
            case .failure(let error):
                processedBook = createProcessedBook(
                    from: csvBook,
                    error: error.localizedDescription
                )
            }
            
            processedBooks.append(processedBook)
            await updateRunningStatistics(processedBook)
            
            // Small delay between individual requests
            try? await Task.sleep(nanoseconds: 250_000_000) // 0.25 second
        }
        
        return processedBooks
    }
    
    // MARK: - Helper Methods
    
    private func separateBooksByISBN(_ csvBooks: [CSVBookData]) -> ([CSVBookData], [CSVBookData]) {
        let booksWithISBN = csvBooks.filter { book in
            guard let isbn = book.isbn?.trimmingCharacters(in: .whitespacesAndNewlines) else { return false }
            let cleanedISBN = isbn.replacingOccurrences(of: "=", with: "")
                .replacingOccurrences(of: "-", with: "")
            return !cleanedISBN.isEmpty && (cleanedISBN.count == 10 || cleanedISBN.count == 13)
        }
        
        let booksWithoutISBN = csvBooks.filter { book in
            guard let isbn = book.isbn?.trimmingCharacters(in: .whitespacesAndNewlines) else { return true }
            let cleanedISBN = isbn.replacingOccurrences(of: "=", with: "")
                .replacingOccurrences(of: "-", with: "")
            return cleanedISBN.isEmpty || (cleanedISBN.count != 10 && cleanedISBN.count != 13)
        }
        
        return (booksWithISBN, booksWithoutISBN)
    }
    
    private func createProcessedBook(
        from csvBook: CSVBookData,
        lookupResult: BookSearchService.ISBNLookupResult
    ) -> ProcessedBook {
        if lookupResult.found, let metadata = lookupResult.bookMetadata {
            return createProcessedBook(
                from: csvBook,
                bookMetadata: metadata,
                source: "batch-api"
            )
        } else {
            return createProcessedBook(
                from: csvBook,
                error: lookupResult.error ?? "Book not found"
            )
        }
    }
    
    private func createProcessedBook(
        from csvBook: CSVBookData,
        bookMetadata: BookMetadata? = nil,
        source: String = "unknown",
        error: String? = nil
    ) -> ProcessedBook {
        
        if let metadata = bookMetadata {
            // Create UserBook from CSV data + API metadata
            let userBook = UserBook(
                title: metadata.title,
                authors: metadata.authors,
                isbn: metadata.isbn,
                googleBooksID: metadata.googleBooksID
            )
            
            // Apply CSV-specific data
            applyCsvDataToUserBook(userBook, from: csvBook)
            
            return ProcessedBook(
                csvBook: csvBook,
                userBook: userBook,
                bookMetadata: metadata,
                success: true,
                source: source,
                error: nil
            )
        } else {
            // Create minimal UserBook from CSV data only
            let userBook = UserBook(
                title: csvBook.title,
                authors: [csvBook.author].compactMap { $0 },
                isbn: csvBook.isbn
            )
            
            applyCsvDataToUserBook(userBook, from: csvBook)
            
            return ProcessedBook(
                csvBook: csvBook,
                userBook: userBook,
                bookMetadata: nil,
                success: false,
                source: "csv-only",
                error: error
            )
        }
    }
    
    private func applyCsvDataToUserBook(_ userBook: UserBook, from csvBook: CSVBookData) {
        // Apply reading status from CSV
        if let status = csvBook.readingStatus {
            userBook.readingStatus = ReadingStatus(rawValue: status) ?? .wantToRead
        }
        
        // Apply rating from CSV
        if let rating = csvBook.rating, rating > 0 {
            userBook.personalRating = rating
        }
        
        // Apply dates from CSV
        userBook.dateAdded = csvBook.dateAdded ?? Date()
        userBook.dateRead = csvBook.dateRead
        userBook.dateStarted = csvBook.dateStarted
        
        // Apply notes from CSV
        if let notes = csvBook.notes, !notes.isEmpty {
            userBook.personalNotes = notes
        }
        
        // Apply reading progress based on status
        switch userBook.readingStatus {
        case .completed:
            userBook.readingProgress = 1.0
        case .currentlyReading:
            userBook.readingProgress = 0.3 // Estimate
        default:
            userBook.readingProgress = 0.0
        }
    }
    
    private func buildSearchQuery(from csvBook: CSVBookData) -> String {
        var queryParts: [String] = []
        
        if !csvBook.title.isEmpty {
            queryParts.append("intitle:\"\(csvBook.title)\"")
        }
        
        if let author = csvBook.author, !author.isEmpty {
            queryParts.append("inauthor:\"\(author)\"")
        }
        
        return queryParts.joined(separator: " ")
    }
    
    private func findBestMatch(csvBook: CSVBookData, searchResults: [BookMetadata]) -> BookMetadata? {
        // Simple scoring algorithm - can be enhanced
        var bestMatch: BookMetadata?
        var bestScore = 0.0
        
        for result in searchResults.prefix(3) { // Only consider top 3 results
            var score = 0.0
            
            // Title similarity
            let titleSimilarity = stringSimilarity(csvBook.title.lowercased(), result.title.lowercased())
            score += titleSimilarity * 0.7
            
            // Author similarity
            if let csvAuthor = csvBook.author {
                let authorSimilarity = result.authors.map { author in
                    stringSimilarity(csvAuthor.lowercased(), author.lowercased())
                }.max() ?? 0.0
                score += authorSimilarity * 0.3
            }
            
            if score > bestScore && score > 0.6 { // Minimum threshold
                bestScore = score
                bestMatch = result
            }
        }
        
        return bestMatch
    }
    
    private func stringSimilarity(_ s1: String, _ s2: String) -> Double {
        // Simple similarity calculation - can be enhanced with more sophisticated algorithms
        let longer = s1.count > s2.count ? s1 : s2
        let shorter = s1.count > s2.count ? s2 : s1
        
        if longer.count == 0 { return 1.0 }
        
        let editDistance = levenshteinDistance(shorter, longer)
        return Double(longer.count - editDistance) / Double(longer.count)
    }
    
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let a = Array(s1)
        let b = Array(s2)
        
        var dist = Array(0...b.count)
        
        for i in 1...a.count {
            var prev = dist[0]
            dist[0] = i
            
            for j in 1...b.count {
                let temp = dist[j]
                dist[j] = a[i-1] == b[j-1] ? prev : min(min(dist[j], dist[j-1]), prev) + 1
                prev = temp
            }
        }
        
        return dist[b.count]
    }
    
    private func updateRunningStatistics(_ processedBook: ProcessedBook) async {
        await MainActor.run {
            guard var progress = self.importProgress else { return }
            
            if processedBook.success {
                progress.successfulImports += 1
            } else {
                progress.failedImports += 1
            }
            
            progress.processedBooks += 1
            self.importProgress = progress
        }
    }
    
    @MainActor
    private func updateProgressSync(percentage: Double) {
        guard var progress = self.importProgress else { return }
        progress.percentage = percentage
        self.importProgress = progress
    }
    
    // MARK: - Enhanced Progress Tracking
    
    private func updateProgress(
        step: ImportStep, 
        message: String, 
        percentage: Double? = nil
    ) async {
        await MainActor.run {
            guard var progress = self.importProgress else { return }
            
            progress.currentStep = step
            progress.currentMessage = message
            
            if let percentage = percentage {
                progress.percentage = percentage
            }
            
            // Update step-specific progress
            switch step {
            case .parsing:
                progress.percentage = 0.1
            case .validating:
                progress.percentage = 0.2
            case .processing:
                // Use provided percentage or calculate based on processed books
                if percentage == nil {
                    let processed = Double(progress.processedBooks)
                    let total = Double(progress.totalBooks)
                    progress.percentage = total > 0 ? 0.2 + (processed / total) * 0.7 : 0.2
                }
            case .saving:
                progress.percentage = 0.9
            case .completed:
                progress.percentage = 1.0
            default:
                break
            }
            
            progress.lastUpdated = Date()
            self.importProgress = progress
        }
    }
    
    // MARK: - Support Types
    
    struct ProcessedBook {
        let csvBook: CSVBookData
        let userBook: UserBook
        let bookMetadata: BookMetadata?
        let success: Bool
        let source: String
        let error: String?
    }
}

// MARK: - Enhanced ImportProgress

extension ImportProgress {
    /// Flag to indicate if batch API is being used
    var useBatchAPI: Bool {
        get { additionalData["useBatchAPI"] as? Bool ?? false }
        set { additionalData["useBatchAPI"] = newValue }
    }
    
    /// Batch processing statistics
    var batchStats: BatchStatistics? {
        get { 
            guard let data = additionalData["batchStats"] as? Data else { return nil }
            return try? JSONDecoder().decode(BatchStatistics.self, from: data)
        }
        set { 
            if let stats = newValue {
                additionalData["batchStats"] = try? JSONEncoder().encode(stats)
            } else {
                additionalData.removeValue(forKey: "batchStats")
            }
        }
    }
}

struct BatchStatistics: Codable {
    let totalBatches: Int
    let completedBatches: Int
    let averageBatchSize: Double
    let averageBatchTime: TimeInterval
    let cacheHitRate: Double
    let batchSuccessRate: Double
}

// MARK: - Array Extension

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}