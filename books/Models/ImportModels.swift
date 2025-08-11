//
//  ImportModels.swift
//  books
//
//  Data models for CSV import functionality
//

import Foundation

// MARK: - CSV Import Data Models

/// Represents a raw CSV import session
struct CSVImportSession: Codable {
    let id: UUID = UUID()
    let fileName: String
    let fileSize: Int
    let totalRows: Int
    let detectedColumns: [CSVColumn]
    let sampleData: [[String]] // First 5-10 rows for preview
    let allData: [[String]] // All rows including header
    let createdAt: Date = Date()
    
    var isValidGoodreadsFormat: Bool {
        // Check if this looks like a Goodreads export
        let columnNames = detectedColumns.map { $0.originalName.lowercased() }
        let requiredColumns = ["title", "author"]
        return requiredColumns.allSatisfy { required in
            columnNames.contains { $0.contains(required) }
        }
    }
}

/// Represents a column in the CSV file
struct CSVColumn: Identifiable, Equatable, Codable {
    let id = UUID()
    let originalName: String        // Column name from CSV header
    let index: Int                  // Column position (0-based)
    var mappedField: BookField?     // What field this maps to in our app
    let sampleValues: [String]      // Sample values for user to see
    
    var isRequired: Bool {
        mappedField?.isRequired ?? false
    }
    
    var hasSampleData: Bool {
        !sampleValues.filter { !$0.isEmpty }.isEmpty
    }
}

/// Fields in our app that can be mapped from CSV
enum BookField: String, CaseIterable, Identifiable, Codable {
    case title = "title"
    case author = "author"
    case isbn = "isbn"
    case publisher = "publisher"
    case publishedDate = "publishedDate"
    case pageCount = "pageCount"
    case description = "description"
    case language = "language"
    case originalLanguage = "originalLanguage"
    case authorNationality = "authorNationality"
    case translator = "translator"
    case genre = "genre"
    case dateRead = "dateRead"
    case dateAdded = "dateAdded"
    case rating = "rating"
    case readingStatus = "readingStatus"
    case personalNotes = "personalNotes"
    case tags = "tags"
    case authorGender = "authorGender"
    case culturalThemes = "culturalThemes"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .title: return "Title"
        case .author: return "Author"
        case .isbn: return "ISBN"
        case .publisher: return "Publisher"
        case .publishedDate: return "Published Date"
        case .pageCount: return "Page Count"
        case .description: return "Description"
        case .language: return "Language"
        case .originalLanguage: return "Original Language"
        case .authorNationality: return "Author Nationality"
        case .translator: return "Translator"
        case .genre: return "Genre"
        case .dateRead: return "Date Read"
        case .dateAdded: return "Date Added"
        case .rating: return "Rating"
        case .readingStatus: return "Reading Status"
        case .personalNotes: return "Personal Notes"
        case .tags: return "Tags"
        case .authorGender: return "Author Gender"
        case .culturalThemes: return "Cultural Themes"
        }
    }
    
    var isRequired: Bool {
        switch self {
        case .title, .author: return true
        default: return false
        }
    }
    
    var expectedType: FieldType {
        switch self {
        case .title, .author, .isbn, .publisher, .description, .language, .originalLanguage, .authorNationality, .translator, .personalNotes:
            return .text
        case .publishedDate, .dateRead, .dateAdded:
            return .date
        case .pageCount, .rating:
            return .number
        case .readingStatus:
            return .enumeration(["Read", "Currently Reading", "Want to Read", "Did Not Finish"])
        case .genre, .tags, .culturalThemes: // UPDATED: Add culturalThemes to list type
            return .list
        case .authorGender:
            return .enumeration(AuthorGender.allCases.map { $0.rawValue })
        }
    }
}

enum FieldType: Codable {
    case text
    case number
    case date
    case enumeration([String])
    case list
}

/// Represents a parsed book from CSV before import
struct ParsedBook {
    let id = UUID()
    let rowIndex: Int
    var title: String?
    var author: String?
    var isbn: String?
    var publisher: String?
    var publishedDate: String?
    var pageCount: Int?
    var description: String?
    var language: String?
    var originalLanguage: String?
    var authorNationality: String?
    var translator: String?
    var genre: [String] = []
    var dateRead: Date?
    var dateAdded: Date?
    var rating: Int?
    var readingStatus: String?
    var personalNotes: String?
    var tags: [String] = []
    var authorGender: AuthorGender?
    var culturalThemes: [String] = []
    
    var isValid: Bool {
        guard let title = title?.trimmingCharacters(in: .whitespacesAndNewlines),
              !title.isEmpty else { return false }
        
        guard let author = author?.trimmingCharacters(in: .whitespacesAndNewlines),
              !author.isEmpty else { return false }
        
        return true
    }
    
    var validationErrors: [String] {
        var errors: [String] = []
        
        if title?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            errors.append("Missing title")
        }
        
        if author?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
            errors.append("Missing author")
        }
        
        if let rating = rating, !(1...5).contains(rating) {
            errors.append("Invalid rating (must be 1-5)")
        }
        
        if let pageCount = pageCount, pageCount <= 0 {
            errors.append("Invalid page count")
        }
        
        return errors
    }
}

/// Progress tracking for import operation
struct ImportProgress {
    let sessionId: UUID
    var currentStep: ImportStep = .preparing
    var totalBooks: Int = 0
    var processedBooks: Int = 0
    var successfulImports: Int = 0
    var failedImports: Int = 0
    var duplicatesSkipped: Int = 0
    var duplicatesISBN: Int = 0  // Duplicates found by ISBN
    var duplicatesGoogleID: Int = 0  // Duplicates found by Google Books ID
    var duplicatesTitleAuthor: Int = 0  // Duplicates found by title/author matching
    var startTime: Date?
    var endTime: Date?
    var isCancelled: Bool = false
    var errors: [ImportError] = []
    var message: String = ""  // Detailed progress message
    var estimatedTimeRemaining: TimeInterval = 0  // Estimated time to completion
    
    // Phase 2: Smart Retry Logic Statistics
    var retryAttempts: Int = 0  // Total retry attempts made
    var successfulRetries: Int = 0  // Retries that succeeded
    var failedRetries: Int = 0  // Retries that failed permanently
    var pendingRetries: Int = 0  // Current retry queue size
    var circuitBreakerTriggered: Bool = false  // Whether circuit breaker has been triggered
    var maxRetryAttempts: Int = 0  // Maximum retry attempts for any single request
    var finalFailureReasons: [String: Int] = [:]  // Categorized failure reasons
    
    var progress: Double {
        guard totalBooks > 0 else { return 0 }
        return Double(processedBooks) / Double(totalBooks)
    }
    
    var isComplete: Bool {
        processedBooks >= totalBooks || isCancelled
    }
    
    var duration: TimeInterval? {
        guard let startTime = startTime else { return nil }
        let endTime = self.endTime ?? Date()
        return endTime.timeIntervalSince(startTime)
    }
    
    /// Get retry success rate as percentage
    var retrySuccessRate: Double {
        guard retryAttempts > 0 else { return 0 }
        return Double(successfulRetries) / Double(retryAttempts) * 100.0
    }
    
    /// Get a detailed status message that includes retry information
    var detailedStatusMessage: String {
        var components: [String] = []
        
        if successfulImports > 0 {
            components.append("\(successfulImports) imported")
        }
        
        if duplicatesSkipped > 0 {
            components.append("\(duplicatesSkipped) duplicates skipped")
        }
        
        if retryAttempts > 0 {
            components.append("\(retryAttempts) retried (\(successfulRetries) succeeded)")
        }
        
        if failedImports > 0 {
            components.append("\(failedImports) failed")
        }
        
        return components.joined(separator: ", ")
    }
}

enum ImportStep: String, CaseIterable {
    case preparing = "Preparing import..."
    case parsing = "Parsing CSV file..."
    case validating = "Validating book data..."
    case importing = "Importing books..."
    case completing = "Finalizing import..."
    case completed = "Import completed!"
    case failed = "Import failed"
    case cancelled = "Import cancelled"
}

/// Detailed error information for import failures
struct ImportError: Identifiable, Equatable {
    let id = UUID()
    let rowIndex: Int?
    let bookTitle: String?
    let errorType: ImportErrorType
    let message: String
    let suggestions: [String]
    
    static func == (lhs: ImportError, rhs: ImportError) -> Bool {
        lhs.id == rhs.id
    }
}

enum ImportErrorType {
    case fileError          // File couldn't be read
    case parseError         // CSV format issues
    case validationError    // Invalid book data
    case duplicateError     // Book already exists
    case duplicateISBN      // Duplicate found by ISBN match
    case duplicateGoogleID  // Duplicate found by Google Books ID
    case duplicateTitleAuthor // Duplicate found by title/author fuzzy matching
    case networkError       // Failed to fetch additional data
    case storageError       // Failed to save to database
}

/// Result of the entire import operation
struct ImportResult {
    let sessionId: UUID
    let totalBooks: Int
    let successfulImports: Int
    let failedImports: Int
    let duplicatesSkipped: Int
    let duplicatesISBN: Int  // Duplicates found by ISBN
    let duplicatesGoogleID: Int  // Duplicates found by Google Books ID
    let duplicatesTitleAuthor: Int  // Duplicates found by title/author matching
    let duration: TimeInterval
    let errors: [ImportError]
    let importedBookIds: [UUID]
    
    // Phase 2: Smart Retry Logic Results
    let retryAttempts: Int
    let successfulRetries: Int
    let failedRetries: Int
    let maxRetryAttempts: Int
    let circuitBreakerTriggered: Bool
    let finalFailureReasons: [String: Int]
    
    init(sessionId: UUID, totalBooks: Int, successfulImports: Int, failedImports: Int, 
         duplicatesSkipped: Int, duplicatesISBN: Int, duplicatesGoogleID: Int, 
         duplicatesTitleAuthor: Int, duration: TimeInterval, errors: [ImportError], 
         importedBookIds: [UUID], retryAttempts: Int = 0, successfulRetries: Int = 0, 
         failedRetries: Int = 0, maxRetryAttempts: Int = 0, circuitBreakerTriggered: Bool = false, 
         finalFailureReasons: [String: Int] = [:]) {
        self.sessionId = sessionId
        self.totalBooks = totalBooks
        self.successfulImports = successfulImports
        self.failedImports = failedImports
        self.duplicatesSkipped = duplicatesSkipped
        self.duplicatesISBN = duplicatesISBN
        self.duplicatesGoogleID = duplicatesGoogleID
        self.duplicatesTitleAuthor = duplicatesTitleAuthor
        self.duration = duration
        self.errors = errors
        self.importedBookIds = importedBookIds
        self.retryAttempts = retryAttempts
        self.successfulRetries = successfulRetries
        self.failedRetries = failedRetries
        self.maxRetryAttempts = maxRetryAttempts
        self.circuitBreakerTriggered = circuitBreakerTriggered
        self.finalFailureReasons = finalFailureReasons
    }
    
    var successRate: Double {
        guard totalBooks > 0 else { return 0 }
        return Double(successfulImports) / Double(totalBooks)
    }
    
    var retrySuccessRate: Double {
        guard retryAttempts > 0 else { return 0 }
        return Double(successfulRetries) / Double(retryAttempts) * 100.0
    }
    
    var hasErrors: Bool {
        !errors.isEmpty
    }
    
    var summary: String {
        if totalBooks == 0 {
            return "No books to import"
        }
        
        var components: [String] = []
        
        if successfulImports > 0 {
            components.append("\(successfulImports) imported")
        }
        
        if duplicatesSkipped > 0 {
            components.append("\(duplicatesSkipped) duplicates skipped")
            
            // Add details about duplicate types if available
            var duplicateDetails: [String] = []
            if duplicatesISBN > 0 {
                duplicateDetails.append("\(duplicatesISBN) by ISBN")
            }
            if duplicatesGoogleID > 0 {
                duplicateDetails.append("\(duplicatesGoogleID) by Google ID")
            }
            if duplicatesTitleAuthor > 0 {
                duplicateDetails.append("\(duplicatesTitleAuthor) by title/author")
            }
            
            if !duplicateDetails.isEmpty {
                components[components.count - 1] = "\(duplicatesSkipped) duplicates skipped (\(duplicateDetails.joined(separator: ", ")))"
            }
        }
        
        // Phase 2: Add retry information to summary
        if retryAttempts > 0 {
            components.append("\(retryAttempts) retries (\(successfulRetries) successful)")
        }
        
        if failedImports > 0 {
            components.append("\(failedImports) failed")
        }
        
        return components.joined(separator: ", ")
    }
    
    var detailedSummary: String {
        var details: [String] = [summary]
        
        if retryAttempts > 0 {
            details.append("Retry success rate: \(Int(retrySuccessRate))%")
        }
        
        if circuitBreakerTriggered {
            details.append("Circuit breaker protected API health")
        }
        
        if !finalFailureReasons.isEmpty {
            let reasonSummary = finalFailureReasons.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
            details.append("Failure reasons: \(reasonSummary)")
        }
        
        return details.joined(separator: "\n")
    }
}

// MARK: - Test Compatibility Types

/// Result wrapper for book search operations (test compatibility)
struct BookSearchResult: Identifiable, Sendable {
    let id = UUID()
    let metadata: BookMetadata
    let relevanceScore: Double
    
    init(metadata: BookMetadata, relevanceScore: Double = 1.0) {
        self.metadata = metadata
        self.relevanceScore = relevanceScore
    }
}

/// Result for CSV preview operations (test compatibility)
struct CSVPreviewResult: Sendable {
    let books: [ParsedBook]
    let mappedColumns: [String: Int]
    let totalRows: Int
    let estimatedImportTime: TimeInterval
    
    var hasValidData: Bool {
        !books.isEmpty && books.allSatisfy { $0.isValid }
    }
}

/// Result for CSV import operations (test compatibility)
struct CSVImportResult: Sendable {
    let successCount: Int
    let skippedBooks: [ParsedBook]
    let errors: [ImportError]
    let importDuration: TimeInterval
    
    var totalProcessed: Int {
        successCount + skippedBooks.count
    }
    
    var hasErrors: Bool {
        !errors.isEmpty
    }
}

/// Additional result type for test compatibility
struct TestISBNLookupResult: Sendable {
    let isbn: String
    let metadata: BookMetadata?
    let success: Bool
    let error: Error?
    let responseTime: TimeInterval
    
    init(isbn: String, metadata: BookMetadata?, success: Bool, error: Error? = nil, responseTime: TimeInterval = 0) {
        self.isbn = isbn
        self.metadata = metadata
        self.success = success
        self.error = error
        self.responseTime = responseTime
    }
}

// MARK: - Goodreads-Specific Mappings

/// Common column mappings for Goodreads CSV exports
struct GoodreadsColumnMappings {
    static let commonMappings: [String: BookField] = [
        "title": .title,
        "author": .author,
        "additional authors": .author,
        "isbn": .isbn,
        "isbn13": .isbn,
        "publisher": .publisher,
        "year published": .publishedDate,
        "original publication year": .publishedDate,
        "date published": .publishedDate,
        "number of pages": .pageCount,
        "book description": .description,
        "my review": .personalNotes,
        "my rating": .rating,
        "average rating": .rating,
        "date read": .dateRead,
        "date added": .dateAdded,
        "exclusive shelf": .readingStatus,
        "my tags": .tags,
        "bookshelves": .tags,
        "genres": .genre,
        "language": .language,
        "original language": .originalLanguage
    ]
    
    /// Attempts to auto-map CSV columns to our book fields
    static func autoMap(columns: [String]) -> [String: BookField] {
        var mappings: [String: BookField] = [:]
        
        for column in columns {
            let normalizedColumn = column.lowercased()
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "_", with: "")
                .replacingOccurrences(of: "-", with: "")
            
            // Direct matches
            if let field = commonMappings[normalizedColumn] {
                mappings[column] = field
                continue
            }
            
            // Fuzzy matching for common variations
            for (pattern, field) in commonMappings {
                if normalizedColumn.contains(pattern.replacingOccurrences(of: " ", with: "")) {
                    mappings[column] = field
                    break
                }
            }
        }
        
        return mappings
    }
    
    /// Maps Goodreads reading status to our ReadingStatus enum
    static func mapReadingStatus(_ goodreadsStatus: String) -> ReadingStatus {
        let normalized = goodreadsStatus.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch normalized {
        case "read":
            return .read
        case "currently-reading", "currently reading":
            return .reading
        case "to-read", "to read", "want to read":
            return .toRead
        case "did not finish", "dnf":
            return .dnf
        default:
            return .toRead // Default fallback
        }
    }
}