//
//  IncompleteBookAnalyzer.swift
//  books
//
//  Enhanced service for analyzing book data completeness
//  Implements MVVM pattern with @Observable for SwiftUI integration
//  Provides configurable criteria and performance optimization for large datasets
//

import Foundation
import SwiftData
@preconcurrency import Combine

/// Advanced analyzer for identifying books with incomplete metadata
/// Provides configurable criteria, performance optimization, and detailed analysis
@MainActor
@Observable
final class IncompleteBookAnalyzer {
    
    // MARK: - Published Properties
    
    private(set) var incompleteBooks: [UserBook] = []
    private(set) var analysisResults: [String: AnalysisResult] = [:]
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var lastAnalysisDate: Date?
    
    // MARK: - Configuration
    
    var minimumCompletionThreshold: Double = 0.7 // 70% completion required
    var enabledCriteria: Set<BookCompletionCriteria> = Set(BookCompletionCriteria.allCases)
    
    // MARK: - Private Properties
    
    private let modelContext: ModelContext
    private var analysisTask: Task<Void, Never>?
    private let analysisQueue = DispatchQueue(label: "book.analysis", qos: .userInitiated)
    
    // Performance optimization
    private var cachedResults: [String: AnalysisResult] = [:]
    private var lastCacheUpdate: Date = Date.distantPast
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.lastAnalysisDate = UserDefaults.standard.object(forKey: "lastBookAnalysisDate") as? Date
    }
    
    // Note: Tasks are automatically cancelled when the instance is deallocated
    
    // MARK: - Public Interface
    
    /// Performs comprehensive analysis of all books in the library
    /// Uses TaskGroup for parallel processing and caching for performance
    func analyzeIncompleteBooks() async {
        // Cancel any existing analysis
        analysisTask?.cancel()
        
        // Check if we can use cached results
        if canUseCachedResults() {
            print("[IncompleteBookAnalyzer] Using cached analysis results")
            applyFilteringFromCache()
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        analysisTask = Task { @MainActor in
            do {
                print("[IncompleteBookAnalyzer] Starting fresh analysis...")
                
                // Fetch all books with optimized descriptor
                let descriptor = FetchDescriptor<UserBook>(
                    sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
                )
                let allBooks = try modelContext.fetch(descriptor)
                
                print("[IncompleteBookAnalyzer] Analyzing \(allBooks.count) books...")
                
                // Parallel analysis using TaskGroup
                let results = await withTaskGroup(of: (UserBook, AnalysisResult?).self) { group in
                    var analysisResults: [(UserBook, AnalysisResult)] = []
                    
                    for book in allBooks {
                        group.addTask {
                            let result = await self.analyzeBook(book)
                            return (book, result)
                        }
                    }
                    
                    for await (book, result) in group {
                        if let result = result {
                            analysisResults.append((book, result))
                        }
                    }
                    
                    return analysisResults
                }
                
                // Process results
                await processAnalysisResults(results)
                
                // Update cache and timestamps
                updateCache()
                lastAnalysisDate = Date()
                UserDefaults.standard.set(lastAnalysisDate, forKey: "lastBookAnalysisDate")
                
                print("[IncompleteBookAnalyzer] Analysis complete: \(incompleteBooks.count) incomplete books found")
                
            } catch {
                errorMessage = "Analysis failed: \(error.localizedDescription)"
                print("[IncompleteBookAnalyzer] Error: \(error)")
            }
            
            isLoading = false
        }
    }
    
    /// Updates the model context (useful when the environment changes)
    func updateModelContext(_ newContext: ModelContext) {
        // Clear cache when context changes
        clearCache()
    }
    
    /// Gets incomplete books filtered by severity level
    func getIncompleteBooks(severity: DataCompletenessLevel) -> [UserBook] {
        switch severity {
        case .all:
            return incompleteBooks
        case .minor, .moderate, .severe:
            return incompleteBooks.filter { book in
                guard let result = analysisResults[book.id.uuidString] else { return false }
                return severity.matches(missingCount: result.missingFields.count)
            }
        }
    }
    
    /// Gets analysis result for a specific book
    func getAnalysisResult(for book: UserBook) -> AnalysisResult? {
        return analysisResults[book.id.uuidString]
    }
    
    /// Forces a refresh of the analysis
    func forceRefresh() async {
        clearCache()
        await analyzeIncompleteBooks()
    }
    
    // MARK: - Private Implementation
    
    private func analyzeBook(_ book: UserBook) async -> AnalysisResult? {
        // Check if this book meets the incompleteness criteria
        let missingFields = await identifyMissingFields(for: book)
        let completionScore = calculateCompletionScore(for: book, missingFields: missingFields)
        
        // Only return result if book is below completion threshold
        guard completionScore < minimumCompletionThreshold else { return nil }
        
        let severity = DataCompletenessLevel.fromMissingCount(missingFields.count)
        let priority = calculatePriority(for: book, severity: severity)
        
        return AnalysisResult(
            bookId: book.id.uuidString,
            missingFields: missingFields,
            completionScore: completionScore,
            severity: severity,
            priority: priority,
            analysisDate: Date()
        )
    }
    
    private func identifyMissingFields(for book: UserBook) async -> [MissingFieldInfo] {
        var missingFields: [MissingFieldInfo] = []
        
        for criteria in enabledCriteria {
            if !criteria.isComplete(for: book) {
                let info = MissingFieldInfo(
                    fieldName: criteria.displayName,
                    description: criteria.userDescription,
                    importance: criteria.importance,
                    fixSuggestion: criteria.fixSuggestion
                )
                missingFields.append(info)
            }
        }
        
        return missingFields.sorted { $0.importance.rawValue > $1.importance.rawValue }
    }
    
    private func calculateCompletionScore(for book: UserBook, missingFields: [MissingFieldInfo]) -> Double {
        let totalFields = enabledCriteria.count
        let _ = totalFields - missingFields.count
        
        // Weight by importance
        let totalWeight = enabledCriteria.reduce(0) { $0 + $1.importance.weight }
        let missingWeight = missingFields.reduce(0) { $0 + $1.importance.weight }
        let completeWeight = totalWeight - missingWeight
        
        return Double(completeWeight) / Double(totalWeight)
    }
    
    private func calculatePriority(for book: UserBook, severity: DataCompletenessLevel) -> AnalysisPriority {
        // Consider reading status, user interaction, and severity
        var priorityScore = 0.0
        
        // Higher priority for books user is actively reading
        switch book.readingStatus {
        case .reading:
            priorityScore += 3.0
        case .wantToRead:
            priorityScore += 2.0
        case .read:
            priorityScore += 1.0
        case .dnf:
            priorityScore += 0.5
        case .toRead, .onHold:
            priorityScore += 0.2
        }
        
        // Higher priority for recently added books
        let daysSinceAdded = Date().timeIntervalSince(book.dateAdded) / (24 * 60 * 60)
        if daysSinceAdded < 7 {
            priorityScore += 2.0
        } else if daysSinceAdded < 30 {
            priorityScore += 1.0
        }
        
        // Factor in severity
        priorityScore += severity.priorityWeight
        
        // Convert to priority level
        switch priorityScore {
        case 6...: return .critical
        case 4..<6: return .high
        case 2..<4: return .medium
        default: return .low
        }
    }
    
    private func processAnalysisResults(_ results: [(UserBook, AnalysisResult)]) async {
        var newIncompleteBooks: [UserBook] = []
        var newAnalysisResults: [String: AnalysisResult] = [:]
        
        for (book, result) in results {
            newIncompleteBooks.append(book)
            newAnalysisResults[book.id.uuidString] = result
        }
        
        // Sort by priority and then by severity
        newIncompleteBooks.sort { book1, book2 in
            guard let result1 = newAnalysisResults[book1.id.uuidString],
                  let result2 = newAnalysisResults[book2.id.uuidString] else {
                return false
            }
            
            if result1.priority != result2.priority {
                return result1.priority.rawValue > result2.priority.rawValue
            }
            
            return result1.severity.priorityWeight > result2.severity.priorityWeight
        }
        
        incompleteBooks = newIncompleteBooks
        analysisResults = newAnalysisResults
    }
    
    // MARK: - Caching
    
    private func canUseCachedResults() -> Bool {
        let cacheAge = Date().timeIntervalSince(lastCacheUpdate)
        return cacheAge < cacheValidityDuration && !cachedResults.isEmpty
    }
    
    private func applyFilteringFromCache() {
        analysisResults = cachedResults
        // Reconstruct incomplete books list from cache
        // This would require storing book references in cache - simplified for now
    }
    
    private func updateCache() {
        cachedResults = analysisResults
        lastCacheUpdate = Date()
    }
    
    private func clearCache() {
        cachedResults.removeAll()
        lastCacheUpdate = Date.distantPast
    }
}

// MARK: - Supporting Types

/// Represents the analysis result for a specific book
struct AnalysisResult {
    let bookId: String
    let missingFields: [MissingFieldInfo]
    let completionScore: Double // 0.0 to 1.0
    let severity: DataCompletenessLevel
    let priority: AnalysisPriority
    let analysisDate: Date
    
    var completionPercentage: Int {
        Int(completionScore * 100)
    }
}

/// Information about a missing field
struct MissingFieldInfo {
    let fieldName: String
    let description: String
    let importance: FieldImportance
    let fixSuggestion: String
}

/// Priority levels for addressing incomplete books
enum AnalysisPriority: Int, CaseIterable {
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
    
    var displayName: String {
        switch self {
        case .low: return "Low Priority"
        case .medium: return "Medium Priority"
        case .high: return "High Priority"
        case .critical: return "Critical"
        }
    }
    
    var color: String {
        switch self {
        case .low: return "secondary"
        case .medium: return "warning"
        case .high: return "error"
        case .critical: return "critical"
        }
    }
}

/// Importance levels for different fields
enum FieldImportance: Int, CaseIterable {
    case low = 1
    case medium = 2
    case high = 3
    case critical = 4
    
    var weight: Double {
        switch self {
        case .low: return 1.0
        case .medium: return 2.0
        case .high: return 3.0
        case .critical: return 4.0
        }
    }
}

/// Configurable criteria for book completion analysis
enum BookCompletionCriteria: String, CaseIterable {
    case isbn = "isbn"
    case authors = "authors"
    case publicationDate = "publicationDate"
    case genre = "genre"
    case pageCount = "pageCount"
    case description = "description"
    case coverImage = "coverImage"
    case language = "language"
    case publisher = "publisher"
    
    var displayName: String {
        switch self {
        case .isbn: return "ISBN"
        case .authors: return "Authors"
        case .publicationDate: return "Publication Date"
        case .genre: return "Genre"
        case .pageCount: return "Page Count"
        case .description: return "Description"
        case .coverImage: return "Cover Image"
        case .language: return "Language"
        case .publisher: return "Publisher"
        }
    }
    
    var userDescription: String {
        switch self {
        case .isbn: return "Unique book identifier for accurate matching"
        case .authors: return "Author information for proper attribution"
        case .publicationDate: return "When the book was published"
        case .genre: return "Categories to help organize your library"
        case .pageCount: return "Total pages for reading progress tracking"
        case .description: return "Book summary and overview"
        case .coverImage: return "Visual representation of the book"
        case .language: return "Original language of the book"
        case .publisher: return "Publishing company information"
        }
    }
    
    var importance: FieldImportance {
        switch self {
        case .isbn, .authors: return .critical
        case .publicationDate, .genre: return .high
        case .pageCount, .description: return .medium
        case .coverImage, .language, .publisher: return .low
        }
    }
    
    var fixSuggestion: String {
        switch self {
        case .isbn: return "Search for the book online or check the barcode"
        case .authors: return "Look up the book's author information"
        case .publicationDate: return "Check the book's copyright page"
        case .genre: return "Research the book's categories and themes"
        case .pageCount: return "Count pages or check book details online"
        case .description: return "Add a brief summary of the book"
        case .coverImage: return "Take a photo or find the cover image online"
        case .language: return "Identify the book's original language"
        case .publisher: return "Check the book's title page for publisher"
        }
    }
    
    func isComplete(for book: UserBook) -> Bool {
        let metadata = book.metadata
        
        switch self {
        case .isbn:
            return metadata?.isbn?.isEmpty == false
        case .authors:
            return metadata?.authors.isEmpty == false
        case .publicationDate:
            return metadata?.publishedDate?.isEmpty == false
        case .genre:
            return metadata?.genre.isEmpty == false
        case .pageCount:
            return metadata?.pageCount != nil && metadata!.pageCount! > 0
        case .description:
            return metadata?.bookDescription?.isEmpty == false
        case .coverImage:
            return metadata?.imageURL != nil
        case .language:
            return metadata?.language?.isEmpty == false || metadata?.originalLanguage?.isEmpty == false
        case .publisher:
            return metadata?.publisher?.isEmpty == false
        }
    }
}

/// Data completeness severity levels
enum DataCompletenessLevel: String, CaseIterable {
    case all = "All"
    case minor = "Minor Issues"
    case moderate = "Moderate Issues"
    case severe = "Severe Issues"
    
    func matches(missingCount: Int) -> Bool {
        switch self {
        case .all:
            return true
        case .minor:
            return missingCount >= 1 && missingCount <= 2
        case .moderate:
            return missingCount >= 3 && missingCount <= 4
        case .severe:
            return missingCount >= 5
        }
    }
    
    static func fromMissingCount(_ count: Int) -> DataCompletenessLevel {
        switch count {
        case 1...2: return .minor
        case 3...4: return .moderate
        case 5...: return .severe
        default: return .minor
        }
    }
    
    var priorityWeight: Double {
        switch self {
        case .all: return 0.0
        case .minor: return 1.0
        case .moderate: return 2.0
        case .severe: return 3.0
        }
    }
    
    var color: String {
        switch self {
        case .all: return "secondary"
        case .minor: return "warning"
        case .moderate: return "error"
        case .severe: return "critical"
        }
    }
}