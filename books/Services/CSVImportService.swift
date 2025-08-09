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
    }
    
    // MARK: - Private Implementation
    
    private func performImport(session: CSVImportSession, columnMappings: [String: BookField]) async {
        var progress = importProgress!
        var errors: [ImportError] = []
        var importedBookIds: [UUID] = []
        var successCount = 0
        var duplicateCount = 0
        var failCount = 0
        var apiSuccessCount = 0
        var apiFallbackCount = 0
        
        do {
            // Step 1: Parse CSV into books
            progress.currentStep = .parsing
            importProgress = progress
            
            let parsedBooks = csvParser.parseBooks(from: session, columnMappings: columnMappings)
            progress.totalBooks = parsedBooks.count
            importProgress = progress
            
            // Small delay to show parsing step
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Check if cancelled
            if Task.isCancelled {
                progress.isCancelled = true
                progress.currentStep = .cancelled
                progress.endTime = Date()
                importProgress = progress
                isImporting = false
                return
            }
            
            // Step 2: Validate books
            progress.currentStep = .validating
            importProgress = progress
            
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
            
            try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            
            // Check if cancelled
            if Task.isCancelled {
                progress.isCancelled = true
                progress.currentStep = .cancelled
                progress.endTime = Date()
                importProgress = progress
                isImporting = false
                return
            }
            
            // Step 3: Import books with ISBN-first strategy
            progress.currentStep = .importing
            importProgress = progress
            
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
                    let result = try await importSingleBook(parsedBook)
                    
                    switch result {
                    case .success(let bookId):
                        importedBookIds.append(bookId)
                        successCount += 1
                        
                        // Track whether we used API or CSV data
                        if parsedBook.isbn != nil && !parsedBook.isbn!.isEmpty {
                            apiSuccessCount += 1
                        } else {
                            apiFallbackCount += 1
                        }
                        
                    case .duplicate:
                        duplicateCount += 1
                    case .failure(let error):
                        errors.append(error)
                        failCount += 1
                    }
                    
                } catch {
                    let importError = ImportError(
                        rowIndex: parsedBook.rowIndex,
                        bookTitle: parsedBook.title,
                        errorType: .storageError,
                        message: "Failed to save book: \(error.localizedDescription)",
                        suggestions: ["Try importing again", "Check device storage space", "Ensure stable internet connection for ISBN lookups"]
                    )
                    errors.append(importError)
                    failCount += 1
                    apiFallbackCount += 1
                }
                
                // Update progress with enhanced stats
                progress.processedBooks = index + 1
                progress.successfulImports = successCount
                progress.duplicatesSkipped = duplicateCount
                progress.failedImports = failCount
                progress.errors = errors
                importProgress = progress
                
                // Variable delay based on whether we made an API call
                let delayNanoseconds: UInt64 = parsedBook.isbn != nil ? 150_000_000 : 50_000_000 // 0.15s for API calls, 0.05s otherwise
                try await Task.sleep(nanoseconds: delayNanoseconds)
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
    
    private func importSingleBook(_ parsedBook: ParsedBook) async throws -> ImportBookResult {
        // Check for duplicates by title and author first
        if await checkForDuplicate(title: parsedBook.title, author: parsedBook.author) {
            return .duplicate
        }
        
        // Enhanced Image-First Strategy: Try multiple approaches to get cover images
        var bookMetadata: BookMetadata
        
        // Strategy 1: ISBN lookup for fresh metadata with images
        if let isbn = parsedBook.isbn, !isbn.isEmpty {
            do {
                if let apiMetadata = try await fetchMetadataFromISBN(isbn) {
                    // Success! Use fresh API metadata with images
                    bookMetadata = apiMetadata
                    
                    // Preserve cultural data from CSV if API doesn't have it
                    enrichMetadataWithCSVData(&bookMetadata, from: parsedBook)
                } else {
                    // ISBN lookup failed, try title/author search
                    bookMetadata = try await fetchMetadataByTitleAuthor(parsedBook) ?? createMetadataFromCSV(parsedBook)
                }
            } catch {
                // API error, try title/author search as fallback
                bookMetadata = try await fetchMetadataByTitleAuthor(parsedBook) ?? createMetadataFromCSV(parsedBook)
            }
        } else {
            // No ISBN, try title/author search for images
            bookMetadata = try await fetchMetadataByTitleAuthor(parsedBook) ?? createMetadataFromCSV(parsedBook)
        }
        
        // Determine reading status
        let readingStatus: ReadingStatus
        if let statusString = parsedBook.readingStatus {
            readingStatus = GoodreadsColumnMappings.mapReadingStatus(statusString)
        } else {
            readingStatus = .toRead
        }
        
        // Check if metadata with this googleBooksID already exists
        let googleBooksIDToFind = bookMetadata.googleBooksID
        let existingMetadataQuery = FetchDescriptor<BookMetadata>(
            predicate: #Predicate<BookMetadata> { metadata in
                metadata.googleBooksID == googleBooksIDToFind
            }
        )
        
        let existingMetadata = try? modelContext.fetch(existingMetadataQuery).first
        
        // Use existing metadata if found, otherwise insert new metadata
        var finalMetadata: BookMetadata
        if let existing = existingMetadata {
            finalMetadata = existing
            // Optionally enrich existing metadata with any new CSV data
            enrichMetadataWithCSVData(&finalMetadata, from: parsedBook)
        } else {
            // Insert new metadata first to establish its identity in the context
            modelContext.insert(bookMetadata)
            finalMetadata = bookMetadata
        }
        
        // Create UserBook with preserved Goodreads user data
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
        
        // Insert UserBook into context after metadata is already inserted
        modelContext.insert(userBook)
        
        return .success(userBook.id)
    }
    
    /// Fetch fresh metadata from Google Books API using ISBN
    private func fetchMetadataFromISBN(_ isbn: String) async throws -> BookMetadata? {
        // Clean ISBN (remove hyphens, spaces)
        let cleanISBN = isbn.replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "")
        
        // Rate limiting: add small delay to avoid hitting API limits
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Use existing BookSearchService to query by ISBN
        let searchResult = await BookSearchService.shared.search(query: "isbn:\(cleanISBN)")
        
        switch searchResult {
        case .success(let books):
            return books.first // Return the first matching book
        case .failure(_):
            return nil // Failed to fetch from API
        }
    }
    
    /// Enhanced: Fetch metadata by title and author as fallback
    private func fetchMetadataByTitleAuthor(_ parsedBook: ParsedBook) async throws -> BookMetadata? {
        guard let title = parsedBook.title?.trimmingCharacters(in: .whitespacesAndNewlines),
              !title.isEmpty else {
            return nil
        }
        
        // Construct search query
        var searchQuery = title
        if let author = parsedBook.author?.trimmingCharacters(in: .whitespacesAndNewlines), !author.isEmpty {
            // Take first author name for cleaner search
            let firstAuthor = author.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? author
            searchQuery += " author:\(firstAuthor)"
        }
        
        // Rate limiting: add delay to avoid hitting API limits
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Use existing BookSearchService to search by title and author
        let searchResult = await BookSearchService.shared.search(query: searchQuery)
        
        switch searchResult {
        case .success(let books):
            // Try to find the best match based on title similarity
            return findBestMatch(books: books, targetTitle: title, targetAuthor: parsedBook.author)
        case .failure(_):
            return nil
        }
    }
    
    /// Find the best matching book from search results
    private func findBestMatch(books: [BookMetadata], targetTitle: String, targetAuthor: String?) -> BookMetadata? {
        guard !books.isEmpty else { return nil }
        
        let normalizedTargetTitle = normalizeForComparison(targetTitle)
        let normalizedTargetAuthor = targetAuthor?.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Score each book and return the best match
        let scoredBooks = books.map { book -> (book: BookMetadata, score: Double) in
            let titleScore = calculateTitleSimilarity(
                normalizeForComparison(book.title),
                normalizedTargetTitle
            )
            
            let authorScore: Double
            if let targetAuthor = normalizedTargetAuthor,
               let bookAuthor = book.authors.first {
                authorScore = calculateTitleSimilarity(
                    normalizeForComparison(bookAuthor),
                    normalizeForComparison(targetAuthor)
                )
            } else {
                authorScore = 0.0
            }
            
            // Weighted scoring: title is more important than author
            let combinedScore = (titleScore * 0.7) + (authorScore * 0.3)
            return (book: book, score: combinedScore)
        }
        
        // Return the highest scoring book if it's above threshold
        let bestMatch = scoredBooks.max(by: { $0.score < $1.score })
        if let bestMatch = bestMatch, bestMatch.score > 0.6 { // 60% similarity threshold
            return bestMatch.book
        }
        
        return nil
    }
    
    /// Calculate title similarity using basic string matching
    private func calculateTitleSimilarity(_ title1: String, _ title2: String) -> Double {
        let words1 = Set(title1.components(separatedBy: .whitespacesAndNewlines))
        let words2 = Set(title2.components(separatedBy: .whitespacesAndNewlines))
        
        let intersection = words1.intersection(words2)
        let union = words1.union(words2)
        
        guard !union.isEmpty else { return 0.0 }
        return Double(intersection.count) / Double(union.count)
    }
    
    /// Normalize string for comparison
    private func normalizeForComparison(_ text: String) -> String {
        return text.lowercased()
            .replacingOccurrences(of: "[^a-z0-9\\s]", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Enrich API metadata with cultural data from CSV
    private func enrichMetadataWithCSVData(_ metadata: inout BookMetadata, from parsedBook: ParsedBook) {
        if metadata.originalLanguage == nil && parsedBook.originalLanguage != nil {
            metadata.originalLanguage = parsedBook.originalLanguage
        }
        if metadata.authorNationality == nil && parsedBook.authorNationality != nil {
            metadata.authorNationality = parsedBook.authorNationality
        }
        if metadata.translator == nil && parsedBook.translator != nil {
            metadata.translator = parsedBook.translator
        }
    }
    
    /// Create metadata from CSV data (fallback method)
    private func createMetadataFromCSV(_ parsedBook: ParsedBook) -> BookMetadata {
        let authors = parsedBook.author?.components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty } ?? []
        
        return BookMetadata(
            googleBooksID: "import-\(UUID().uuidString)", // Prefix to distinguish imports
            title: parsedBook.title ?? "",
            authors: authors,
            publishedDate: parsedBook.publishedDate,
            pageCount: parsedBook.pageCount,
            bookDescription: parsedBook.description,
            imageURL: nil, // No image from CSV
            language: parsedBook.language,
            previewLink: nil,
            infoLink: nil,
            publisher: parsedBook.publisher,
            isbn: parsedBook.isbn,
            genre: parsedBook.genre,
            originalLanguage: parsedBook.originalLanguage,
            authorNationality: parsedBook.authorNationality,
            translator: parsedBook.translator
        )
    }
    
    private func checkForDuplicate(title: String?, author: String?) async -> Bool {
        guard let title = title?.trimmingCharacters(in: .whitespacesAndNewlines),
              let author = author?.trimmingCharacters(in: .whitespacesAndNewlines),
              !title.isEmpty, !author.isEmpty else {
            return false
        }
        
        // Query existing books
        let descriptor = FetchDescriptor<UserBook>()
        let existingBooks = try? modelContext.fetch(descriptor)
        
        return existingBooks?.contains { book in
            guard let existingTitle = book.metadata?.title,
                  let existingAuthors = book.metadata?.authors else {
                return false
            }
            
            let titleMatch = existingTitle.lowercased() == title.lowercased()
            let authorMatch = existingAuthors.contains { existingAuthor in
                existingAuthor.lowercased().contains(author.lowercased()) ||
                author.lowercased().contains(existingAuthor.lowercased())
            }
            
            return titleMatch && authorMatch
        } ?? false
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
            sampleData: sampleData
        )
    }
}