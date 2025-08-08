// books-buildout-main/books/BookSearchService.swift
import Foundation

@MainActor
class BookSearchService: ObservableObject {
    static let shared = BookSearchService()
    private init() {}

    private let baseURL = "https://www.googleapis.com/books/v1/volumes"
    
    enum SortOption: String, CaseIterable, Identifiable {
        case relevance = "relevance"
        case newest = "newest"
        case popularity = "popularity"
        case completeness = "completeness"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .relevance: return "Most Relevant"
            case .newest: return "Newest First"
            case .popularity: return "Most Popular"
            case .completeness: return "Complete Info"
            }
        }
        
        var systemImage: String {
            switch self {
            case .relevance: return "target"
            case .newest: return "calendar"
            case .popularity: return "star.fill"
            case .completeness: return "checkmark.seal.fill"
            }
        }
    }
    
    enum BookError: LocalizedError, Sendable {
        case invalidURL
        case networkError(String)
        case decodingError(String)
        case noData
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid search URL"
            case .networkError(let message):
                return "Network error: \(message)"
            case .decodingError(let message):
                return "Data parsing error: \(message)"
            case .noData:
                return "No data received"
            }
        }
    }

    func search(
        query: String, 
        sortBy: SortOption = .relevance,
        maxResults: Int = 40,
        includeTranslations: Bool = true
    ) async -> Result<[BookMetadata], BookError> {
        // Handle empty or whitespace-only queries
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return .success([]) // Return empty results for empty queries
        }
        
        print("🔍 BookSearchService: Starting search for query: '\(trimmedQuery)' with sort: \(sortBy.displayName)")
        
        guard var components = URLComponents(string: baseURL) else {
            print("❌ BookSearchService: Invalid base URL")
            return .failure(.invalidURL)
        }
        
        // Enhanced query construction
        let optimizedQuery = buildOptimizedQuery(trimmedQuery)
        
        // Build query parameters with Google Books API optimizations
        var queryItems = [
            URLQueryItem(name: "q", value: optimizedQuery),
            URLQueryItem(name: "maxResults", value: String(maxResults)),
            URLQueryItem(name: "printType", value: "books"),
            URLQueryItem(name: "projection", value: "full") // Get full volume info including ratings
        ]
        
        // Add sorting parameter for Google Books API
        if sortBy == .newest {
            queryItems.append(URLQueryItem(name: "orderBy", value: "newest"))
        } else {
            queryItems.append(URLQueryItem(name: "orderBy", value: "relevance"))
        }
        
        // Language settings
        if !includeTranslations {
            queryItems.append(URLQueryItem(name: "langRestrict", value: "en"))
        }
        
        components.queryItems = queryItems

        guard let url = components.url else {
            print("❌ BookSearchService: Failed to construct URL from components")
            return .failure(.invalidURL)
        }
        
        print("🌐 BookSearchService: Making request to: \(url.absoluteString)")

        do {
            // Create URL session with better configuration
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 20.0
            configuration.timeoutIntervalForResource = 40.0
            configuration.waitsForConnectivity = true
            let session = URLSession(configuration: configuration)
            
            let (data, response) = try await session.data(from: url)
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 BookSearchService: HTTP Status: \(httpResponse.statusCode)")
                guard 200...299 ~= httpResponse.statusCode else {
                    return .failure(.networkError("HTTP \(httpResponse.statusCode)"))
                }
            }
            
            print("📊 BookSearchService: Response data size: \(data.count) bytes")
            
            let searchResponse = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
            
            let metadataItems = searchResponse.items?.compactMap { $0.toBookMetadata() } ?? []
            
            // Apply post-processing sorting and filtering
            let processedResults = processSearchResults(
                metadataItems, 
                originalQuery: trimmedQuery,
                sortBy: sortBy
            )
            
            print("📚 BookSearchService: Returning \(processedResults.count) processed results")
            return .success(processedResults)
            
        } catch let error as URLError {
            return .failure(.networkError(error.localizedDescription))
        } catch {
            return .failure(.decodingError(error.localizedDescription))
        }
    }
    
    // MARK: - Query Optimization
    
    private func buildOptimizedQuery(_ query: String) -> String {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Handle ISBN searches
        if isISBN(trimmed) {
            return "isbn:\(trimmed.replacingOccurrences(of: "-", with: ""))"
        }
        
        // Handle author-specific searches (when coming from AuthorSearchResultsView)
        // Check if this looks like an author name (contains spaces but no special terms)
        let isLikelyAuthorName = trimmed.contains(" ") && 
                                !trimmed.lowercased().contains("by ") && 
                                !trimmed.contains("\"") &&
                                !trimmed.contains(":") &&
                                trimmed.split(separator: " ").count <= 4 // Reasonable author name length
        
        if isLikelyAuthorName {
            return "inauthor:\"\(trimmed)\""
        }
        
        // Handle author-specific searches with "by"
        if trimmed.lowercased().contains("by ") {
            let parts = trimmed.components(separatedBy: " by ")
            if parts.count == 2 {
                return "intitle:\"\(parts[0])\" inauthor:\"\(parts[1])\""
            }
        }
        
        // Handle title searches with quotes
        if trimmed.contains("\"") {
            return trimmed // Keep exact phrase searches as-is
        }
        
        // For general searches, boost title and author matches
        return "intitle:\(trimmed) OR inauthor:\(trimmed) OR \(trimmed)"
    }
    
    private func isISBN(_ string: String) -> Bool {
        let cleaned = string.replacingOccurrences(of: "-", with: "")
        return cleaned.count == 10 || cleaned.count == 13 && cleaned.allSatisfy { $0.isNumber }
    }
    
    // MARK: - Result Processing & Sorting
    
    private func processSearchResults(
        _ results: [BookMetadata], 
        originalQuery: String,
        sortBy: SortOption
    ) -> [BookMetadata] {
        
        // First, filter out low-quality results
        let filteredResults = results.filter { metadata in
            // Must have title and at least one author
            guard !metadata.title.isEmpty && !metadata.authors.isEmpty else { return false }
            
            // Filter out obvious non-books (magazines, etc.)
            let title = metadata.title.lowercased()
            let badKeywords = ["magazine", "journal", "newsletter", "catalog", "brochure"]
            return !badKeywords.contains { title.contains($0) }
        }
        
        // Remove duplicates based on title and author similarity
        let deduplicatedResults = removeDuplicates(filteredResults)
        
        // Apply sorting
        let sortedResults = sortResults(deduplicatedResults, by: sortBy, originalQuery: originalQuery)
        
        return sortedResults
    }
    
    private func removeDuplicates(_ results: [BookMetadata]) -> [BookMetadata] {
        var uniqueResults: [BookMetadata] = []
        
        for result in results {
            let isDuplicate = uniqueResults.contains { existing in
                // Check for similar titles and authors
                let titleSimilarity = stringSimilarity(result.title, existing.title)
                let authorSimilarity = authorsSimilarity(result.authors, existing.authors)
                
                return titleSimilarity > 0.85 && authorSimilarity > 0.8
            }
            
            if !isDuplicate {
                uniqueResults.append(result)
            }
        }
        
        return uniqueResults
    }
    
    private func sortResults(_ results: [BookMetadata], by sortOption: SortOption, originalQuery: String) -> [BookMetadata] {
        switch sortOption {
        case .relevance:
            return results.sorted { first, second in
                let firstRelevance = calculateRelevanceScore(first, query: originalQuery)
                let secondRelevance = calculateRelevanceScore(second, query: originalQuery)
                return firstRelevance > secondRelevance
            }
            
        case .newest:
            return results.sorted { first, second in
                let firstYear = extractYear(from: first.publishedDate) ?? 0
                let secondYear = extractYear(from: second.publishedDate) ?? 0
                return firstYear > secondYear
            }
            
        case .popularity:
            return results.sorted { first, second in
                let firstPopularity = calculatePopularityScore(first)
                let secondPopularity = calculatePopularityScore(second)
                return firstPopularity > secondPopularity
            }
            
        case .completeness:
            return results.sorted { first, second in
                let firstCompleteness = calculateCompletenessScore(first)
                let secondCompleteness = calculateCompletenessScore(second)
                return firstCompleteness > secondCompleteness
            }
        }
    }
    
    // MARK: - Scoring Algorithms
    
    private func calculateRelevanceScore(_ metadata: BookMetadata, query: String) -> Double {
        let queryWords = query.lowercased().components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        var score: Double = 0
        
        // Title matching (highest weight)
        let titleWords = metadata.title.lowercased().components(separatedBy: .whitespacesAndNewlines)
        for queryWord in queryWords {
            for titleWord in titleWords {
                if titleWord.contains(queryWord) {
                    score += titleWord == queryWord ? 10 : 5 // Exact match vs partial
                }
            }
        }
        
        // Author matching (medium weight)
        let authorText = metadata.authors.joined(separator: " ").lowercased()
        for queryWord in queryWords {
            if authorText.contains(queryWord) {
                score += 7
            }
        }
        
        // Completeness bonus
        if metadata.imageURL != nil { score += 1 }
        if metadata.bookDescription != nil && !metadata.bookDescription!.isEmpty { score += 1 }
        if metadata.pageCount != nil && metadata.pageCount! > 0 { score += 1 }
        
        return score
    }
    
    private func calculatePopularityScore(_ metadata: BookMetadata) -> Double {
        var score: Double = 0
        
        // Boost books with covers and descriptions (usually more popular)
        if metadata.imageURL != nil { score += 3 }
        if metadata.bookDescription != nil && !metadata.bookDescription!.isEmpty { score += 2 }
        
        // Boost books from major publishers
        if let publisher = metadata.publisher?.lowercased() {
            let majorPublishers = ["penguin", "random house", "harpercollins", "simon", "macmillan", "scholastic"]
            if majorPublishers.contains(where: publisher.contains) {
                score += 5
            }
        }
        
        // Prefer books with reasonable page counts (not too short/long)
        if let pageCount = metadata.pageCount {
            if pageCount >= 100 && pageCount <= 800 {
                score += 2
            }
        }
        
        // Boost recent but not too recent books (proven popular)
        if let year = extractYear(from: metadata.publishedDate) {
            let currentYear = Calendar.current.component(.year, from: Date())
            let age = currentYear - year
            if age >= 1 && age <= 10 {
                score += 3
            } else if age <= 20 {
                score += 1
            }
        }
        
        return score
    }
    
    private func calculateCompletenessScore(_ metadata: BookMetadata) -> Double {
        var score: Double = 0
        
        // Required fields
        if !metadata.title.isEmpty { score += 2 }
        if !metadata.authors.isEmpty { score += 2 }
        
        // Nice-to-have fields
        if metadata.imageURL != nil { score += 2 }
        if metadata.bookDescription != nil && !metadata.bookDescription!.isEmpty { score += 2 }
        if metadata.pageCount != nil && metadata.pageCount! > 0 { score += 2 }
        if metadata.publisher != nil && !metadata.publisher!.isEmpty { score += 1 }
        if metadata.publishedDate != nil && !metadata.publishedDate!.isEmpty { score += 1 }
        if metadata.isbn != nil && !metadata.isbn!.isEmpty { score += 1 }
        if !metadata.genre.isEmpty { score += 1 }
        
        return score
    }
    
    // MARK: - Helper Functions
    
    private func stringSimilarity(_ s1: String, _ s2: String) -> Double {
        let longer = s1.count > s2.count ? s1.lowercased() : s2.lowercased()
        let shorter = s1.count > s2.count ? s2.lowercased() : s1.lowercased()
        
        let longerLength = longer.count
        if longerLength == 0 { return 1.0 }
        
        let editDistance = levenshteinDistance(shorter, longer)
        return Double(longerLength - editDistance) / Double(longerLength)
    }
    
    private func authorsSimilarity(_ authors1: [String], _ authors2: [String]) -> Double {
        guard !authors1.isEmpty && !authors2.isEmpty else { return 0 }
        
        let maxSimilarity = authors1.flatMap { author1 in
            authors2.map { author2 in
                stringSimilarity(author1, author2)
            }
        }.max() ?? 0
        
        return maxSimilarity
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
    
    private func extractYear(from dateString: String?) -> Int? {
        guard let dateString = dateString, dateString.count >= 4 else { return nil }
        let yearString = String(dateString.prefix(4))
        return Int(yearString)
    }
}

// MARK: - Google Books API Response Structures

private struct GoogleBooksResponse: Codable, Sendable {
    let items: [VolumeItem]?
}

private struct VolumeItem: Codable, Sendable {
    let id: String
    let volumeInfo: VolumeInfo
    
    func toBookMetadata() -> BookMetadata {
        let isbn13 = volumeInfo.industryIdentifiers?.first(where: { $0.type == "ISBN_13" })?.identifier
        let isbn10 = volumeInfo.industryIdentifiers?.first(where: { $0.type == "ISBN_10" })?.identifier

        return BookMetadata(
            googleBooksID: self.id,
            title: volumeInfo.title,
            authors: volumeInfo.authors ?? [],
            publishedDate: volumeInfo.publishedDate,
            pageCount: volumeInfo.pageCount,
            bookDescription: volumeInfo.description,
            imageURL: volumeInfo.imageLinks?.thumbnail?.replacingHTTPWithHTTPS(),
            language: volumeInfo.language,
            previewLink: URL(string: volumeInfo.previewLink ?? ""),
            infoLink: URL(string: volumeInfo.infoLink ?? ""),
            publisher: volumeInfo.publisher,
            isbn: isbn13 ?? isbn10,
            genre: volumeInfo.categories ?? []
        )
    }
}

private struct VolumeInfo: Codable, Sendable {
    let title: String
    let authors: [String]?
    let publisher: String?
    let publishedDate: String?
    let description: String?
    let industryIdentifiers: [IndustryIdentifier]?
    let pageCount: Int?
    let categories: [String]?
    let imageLinks: ImageLinks?
    let language: String?
    let previewLink: String?
    let infoLink: String?
    let averageRating: Double?
    let ratingsCount: Int?
}

private struct IndustryIdentifier: Codable, Sendable {
    let type: String
    let identifier: String
}

private struct ImageLinks: Codable, Sendable {
    let smallThumbnail: String?
    let thumbnail: String?
}

private extension String {
    func replacingHTTPWithHTTPS() -> URL? {
        if self.starts(with: "http://") {
            return URL(string: self.replacingOccurrences(of: "http://", with: "https://"))
        }
        return URL(string: self)
    }
}