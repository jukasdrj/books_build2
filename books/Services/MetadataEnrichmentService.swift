//
//  MetadataEnrichmentService.swift
//  books
//
//  Background metadata enrichment service for filling data gaps
//  Identifies and enriches books with incomplete metadata
//

import Foundation
import SwiftData
@preconcurrency import Combine

/// Service for background metadata enrichment
@MainActor
class MetadataEnrichmentService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isEnriching: Bool = false
    @Published var enrichmentProgress: EnrichmentProgress?
    @Published var lastEnrichmentDate: Date?
    
    // MARK: - Private Properties
    
    private let modelContext: ModelContext
    private let bookSearchService: BookSearchService
    private let simpleISBNService: SimpleISBNLookupService
    private var enrichmentTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    // Rate limiting
    private let maxConcurrentEnrichments = 3
    private let delayBetweenBatches: TimeInterval = 2.0
    private let batchSize = 10
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.bookSearchService = BookSearchService.shared
        self.simpleISBNService = SimpleISBNLookupService()
        
        // Load last enrichment date from UserDefaults
        self.lastEnrichmentDate = UserDefaults.standard.object(forKey: "lastEnrichmentDate") as? Date
        
        // Set up notification observers for background enrichment
        setupNotificationObservers()
    }
    
    deinit {
        // Clean up observers - access cancellables directly since it's already main-actor isolated
        cancellables.removeAll()
    }
    
    // MARK: - Public API
    
    /// Identify books that need metadata enrichment
    func identifyIncompleteBooks(completenessThreshold: Double = 0.7) -> [EnrichmentCandidate] {
        let descriptor = FetchDescriptor<UserBook>()
        
        guard let allBooks = try? modelContext.fetch(descriptor) else {
            print("⚠️ [MetadataEnrichmentService] Failed to fetch books")
            return []
        }
        
        var candidates: [EnrichmentCandidate] = []
        
        for book in allBooks {
            guard let metadata = book.metadata else { continue }
            
            let completeness = DataCompletenessService.calculateMetadataCompleteness(metadata)
            
            if completeness < completenessThreshold {
                let missingFields = identifyMissingFields(metadata)
                let priority = calculateEnrichmentPriority(completeness: completeness, missingFields: missingFields)
                
                candidates.append(EnrichmentCandidate(
                    book: book,
                    completeness: completeness,
                    missingFields: missingFields,
                    priority: priority,
                    enrichmentMethod: determineEnrichmentMethod(book)
                ))
            }
        }
        
        // Sort by priority (high to low) then by completeness (low to high)
        return candidates.sorted { first, second in
            if first.priority != second.priority {
                return first.priority.rawValue > second.priority.rawValue
            }
            return first.completeness < second.completeness
        }
    }
    
    /// Start background enrichment process
    func startEnrichment(candidates: [EnrichmentCandidate]? = nil) {
        guard !isEnriching else {
            print("⚠️ [MetadataEnrichmentService] Enrichment already in progress")
            return
        }
        
        let targetCandidates = candidates ?? identifyIncompleteBooks()
        
        guard !targetCandidates.isEmpty else {
            print("✅ [MetadataEnrichmentService] No books need enrichment")
            return
        }
        
        isEnriching = true
        enrichmentProgress = EnrichmentProgress(
            totalBooks: targetCandidates.count,
            processedBooks: 0,
            successfulEnrichments: 0,
            failedEnrichments: 0,
            currentBookTitle: "",
            estimatedTimeRemaining: 0
        )
        
        print("🚀 [MetadataEnrichmentService] Starting enrichment for \(targetCandidates.count) books")
        
        enrichmentTask = Task {
            await performEnrichment(candidates: targetCandidates)
        }
    }
    
    /// Stop enrichment process
    func stopEnrichment() {
        enrichmentTask?.cancel()
        enrichmentTask = nil
        isEnriching = false
        enrichmentProgress = nil
        print("⏹️ [MetadataEnrichmentService] Enrichment stopped")
    }
    
    /// Get enrichment statistics
    func getEnrichmentStats() -> EnrichmentStats {
        let incompleteBooks = identifyIncompleteBooks()
        let totalBooks = (try? modelContext.fetch(FetchDescriptor<UserBook>()))?.count ?? 0
        
        return EnrichmentStats(
            totalBooks: totalBooks,
            incompleteBooks: incompleteBooks.count,
            lastEnrichmentDate: lastEnrichmentDate,
            averageCompleteness: calculateAverageCompleteness()
        )
    }
    
    // MARK: - Private Implementation
    
    private func performEnrichment(candidates: [EnrichmentCandidate]) async {
        let startTime = Date()
        var successCount = 0
        var failCount = 0
        
        // Process in batches to avoid overwhelming the API
        for batch in candidates.chunked(into: batchSize) {
            if Task.isCancelled { break }
            
            await processBatch(batch, successCount: &successCount, failCount: &failCount)
            
            // Rate limiting delay between batches
            if batch != candidates.chunked(into: batchSize).last {
                try? await Task.sleep(nanoseconds: UInt64(delayBetweenBatches * 1_000_000_000))
            }
        }
        
        // Update completion state
        await MainActor.run {
            self.isEnriching = false
            self.enrichmentProgress = nil
            self.lastEnrichmentDate = Date()
            UserDefaults.standard.set(self.lastEnrichmentDate, forKey: "lastEnrichmentDate")
            
            let duration = Date().timeIntervalSince(startTime)
            print("✅ [MetadataEnrichmentService] Enrichment completed: \(successCount) succeeded, \(failCount) failed in \(Int(duration))s")
        }
    }
    
    private func processBatch(_ batch: [EnrichmentCandidate], successCount: inout Int, failCount: inout Int) async {
        await withTaskGroup(of: EnrichmentResult.self, body: { group in
            for candidate in batch {
                group.addTask { @Sendable in
                    await self.enrichBook(candidate)
                }
            }
            
            for await result in group {
                if Task.isCancelled { break }
                
                await MainActor.run {
                    if var progress = self.enrichmentProgress {
                        progress.processedBooks += 1
                        
                        switch result {
                        case .success(let bookTitle):
                            progress.successfulEnrichments += 1
                            successCount += 1
                            print("✅ [MetadataEnrichmentService] Enriched: \(bookTitle)")
                        case .failure(let bookTitle, let error):
                            progress.failedEnrichments += 1
                            failCount += 1
                            print("❌ [MetadataEnrichmentService] Failed to enrich \(bookTitle): \(error)")
                        case .noEnrichmentNeeded(let bookTitle):
                            print("ℹ️ [MetadataEnrichmentService] No enrichment needed: \(bookTitle)")
                        }
                        
                        // Update estimated time remaining
                        let remaining = progress.totalBooks - progress.processedBooks
                        let avgTimePerBook: TimeInterval = 3.0 // Estimated 3 seconds per book
                        progress.estimatedTimeRemaining = TimeInterval(remaining) * avgTimePerBook
                        
                        self.enrichmentProgress = progress
                    }
                }
            }
        })
    }
    
    private func enrichBook(_ candidate: EnrichmentCandidate) async -> EnrichmentResult {
        let bookTitle = candidate.book.metadata?.title ?? "Unknown"
        
        let enrichedMetadata: BookMetadata?
        
        switch candidate.enrichmentMethod {
            case .isbn:
                if let isbn = candidate.book.metadata?.isbn {
                    let result = await simpleISBNService.lookupISBN(isbn)
                    switch result {
                    case .success(let metadata):
                        enrichedMetadata = metadata
                    case .failure:
                        enrichedMetadata = nil
                    }
                } else {
                    enrichedMetadata = nil
                }
                
            case .titleAuthor:
                if let title = candidate.book.metadata?.title,
                   let authors = candidate.book.metadata?.authors,
                   !authors.isEmpty {
                    let searchQuery = "\(title) \(authors.joined(separator: " "))"
                    let result = await bookSearchService.search(query: searchQuery, maxResults: 1)
                    switch result {
                    case .success(let books):
                        enrichedMetadata = books.first
                    case .failure:
                        enrichedMetadata = nil
                    }
                } else {
                    enrichedMetadata = nil
                }
                
        case .none:
            return .noEnrichmentNeeded(bookTitle)
        }
        
        if let newMetadata = enrichedMetadata {
            await MainActor.run {
                updateBookMetadata(candidate.book, with: newMetadata, missingFields: candidate.missingFields)
            }
            return .success(bookTitle)
        } else {
            return .failure(bookTitle, "No enrichment data found")
        }
    }
    
    @MainActor
    private func updateBookMetadata(_ book: UserBook, with newMetadata: BookMetadata, missingFields: [MissingField]) {
        guard let existingMetadata = book.metadata else { return }
        
        // Selectively update only missing fields to preserve existing data
        for field in missingFields {
            switch field {
            case .coverImage:
                if existingMetadata.imageURL == nil && newMetadata.imageURL != nil {
                    existingMetadata.imageURL = newMetadata.imageURL
                }
            case .description:
                if existingMetadata.bookDescription?.isEmpty != false && newMetadata.bookDescription?.isEmpty == false {
                    existingMetadata.bookDescription = newMetadata.bookDescription
                }
            case .publishedDate:
                if existingMetadata.publishedDate?.isEmpty != false && newMetadata.publishedDate?.isEmpty == false {
                    existingMetadata.publishedDate = newMetadata.publishedDate
                }
            case .pageCount:
                if existingMetadata.pageCount == nil && newMetadata.pageCount != nil {
                    existingMetadata.pageCount = newMetadata.pageCount
                }
            case .publisher:
                if existingMetadata.publisher?.isEmpty != false && newMetadata.publisher?.isEmpty == false {
                    existingMetadata.publisher = newMetadata.publisher
                }
            case .genre:
                if existingMetadata.genre.isEmpty && !newMetadata.genre.isEmpty {
                    existingMetadata.genre = newMetadata.genre
                }
            case .language:
                if existingMetadata.language == nil && newMetadata.language != nil {
                    existingMetadata.language = newMetadata.language
                }
            case .isbn:
                if existingMetadata.isbn?.isEmpty != false && newMetadata.isbn?.isEmpty == false {
                    existingMetadata.isbn = newMetadata.isbn
                }
            }
        }
        
        // Save changes
        do {
            try modelContext.save()
        } catch {
            print("❌ [MetadataEnrichmentService] Failed to save enriched metadata: \(error)")
        }
    }
    
    private func identifyMissingFields(_ metadata: BookMetadata) -> [MissingField] {
        var missing: [MissingField] = []
        
        if metadata.imageURL == nil { missing.append(.coverImage) }
        if metadata.bookDescription?.isEmpty != false { missing.append(.description) }
        if metadata.publishedDate?.isEmpty != false { missing.append(.publishedDate) }
        if metadata.pageCount == nil { missing.append(.pageCount) }
        if metadata.publisher?.isEmpty != false { missing.append(.publisher) }
        if metadata.genre.isEmpty { missing.append(.genre) }
        if metadata.language == nil { missing.append(.language) }
        if metadata.isbn?.isEmpty != false { missing.append(.isbn) }
        
        return missing
    }
    
    private func calculateEnrichmentPriority(completeness: Double, missingFields: [MissingField]) -> EnrichmentPriority {
        // High priority: Missing critical visual/content fields
        if missingFields.contains(.coverImage) || missingFields.contains(.description) {
            return .high
        }
        
        // Medium priority: Missing important metadata
        if missingFields.contains(.pageCount) || missingFields.contains(.publishedDate) || missingFields.contains(.publisher) {
            return .medium
        }
        
        // Low priority: Missing nice-to-have fields
        return .low
    }
    
    private func determineEnrichmentMethod(_ book: UserBook) -> EnrichmentMethod {
        guard let metadata = book.metadata else { return .none }
        
        // Prefer ISBN lookup if available
        if let isbn = metadata.isbn, !isbn.isEmpty {
            return .isbn
        }
        
        // Fall back to title/author search
        if !metadata.title.isEmpty && !metadata.authors.isEmpty {
            return .titleAuthor
        }
        
        return .none
    }
    
    private func calculateAverageCompleteness() -> Double {
        let descriptor = FetchDescriptor<UserBook>()
        guard let allBooks = try? modelContext.fetch(descriptor), !allBooks.isEmpty else {
            return 0.0
        }
        
        let totalCompleteness = allBooks.compactMap { book in
            book.metadata != nil ? DataCompletenessService.calculateMetadataCompleteness(book.metadata!) : nil
        }.reduce(0.0, +)
        
        return totalCompleteness / Double(allBooks.count)
    }
    
    // MARK: - Notification Observers
    
    private func setupNotificationObservers() {
        // Listen for background enrichment requests
        NotificationCenter.default.publisher(for: .shouldStartBackgroundEnrichment)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.handleBackgroundEnrichmentRequest()
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleBackgroundEnrichmentRequest() async {
        print("📱 [MetadataEnrichmentService] Received background enrichment request")
        
        // Check if already enriching
        guard !isEnriching else {
            print("⚠️ [MetadataEnrichmentService] Already enriching, ignoring background request")
            return
        }
        
        // Find incomplete books with high priority
        let candidates = identifyIncompleteBooks().filter { $0.priority == .high }
        
        guard !candidates.isEmpty else {
            print("✅ [MetadataEnrichmentService] No high-priority books need enrichment")
            return
        }
        
        // Start enrichment with limited candidates for background processing
        let backgroundCandidates = Array(candidates.prefix(20)) // Limit for background processing
        startEnrichment(candidates: backgroundCandidates)
    }
}

// MARK: - Data Models

struct EnrichmentCandidate: Equatable, @unchecked Sendable {
    let book: UserBook
    let completeness: Double
    let missingFields: [MissingField]
    let priority: EnrichmentPriority
    let enrichmentMethod: EnrichmentMethod
    
    static func == (lhs: EnrichmentCandidate, rhs: EnrichmentCandidate) -> Bool {
        return lhs.book.id == rhs.book.id
    }
}

struct EnrichmentProgress {
    var totalBooks: Int
    var processedBooks: Int
    var successfulEnrichments: Int
    var failedEnrichments: Int
    var currentBookTitle: String
    var estimatedTimeRemaining: TimeInterval
}

struct EnrichmentStats {
    let totalBooks: Int
    let incompleteBooks: Int
    let lastEnrichmentDate: Date?
    let averageCompleteness: Double
}

enum EnrichmentPriority: Int, CaseIterable {
    case high = 3
    case medium = 2
    case low = 1
    
    var description: String {
        switch self {
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }
}

enum EnrichmentMethod {
    case isbn
    case titleAuthor
    case none
}

enum MissingField: CaseIterable {
    case coverImage
    case description
    case publishedDate
    case pageCount
    case publisher
    case genre
    case language
    case isbn
    
    var displayName: String {
        switch self {
        case .coverImage: return "Cover Image"
        case .description: return "Description"
        case .publishedDate: return "Publication Date"
        case .pageCount: return "Page Count"
        case .publisher: return "Publisher"
        case .genre: return "Genre"
        case .language: return "Language"
        case .isbn: return "ISBN"
        }
    }
}

private enum EnrichmentResult {
    case success(String)
    case failure(String, String)
    case noEnrichmentNeeded(String)
}

// MARK: - Array Extension

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}