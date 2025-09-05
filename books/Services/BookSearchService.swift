// books/Services/BookSearchServiceProxy.swift
import Foundation
import SwiftData
import SwiftUI

// MARK: - Proxy-Based Book Search Service

@MainActor
class BookSearchService: ObservableObject {
    static let shared = BookSearchService()
    
    // MARK: - Configuration
    
    /// Primary CloudFlare Worker endpoint with custom domain
    private let primaryProxyURL = "https://books.ooheynerds.com"
    /// Fallback CloudFlare Worker endpoint 
    private let fallbackProxyURL = "https://books-api-proxy.jukasdrj.workers.dev"
    
    private init() {
        #if DEBUG
        print("✅ BookSearchService: Using proxy-based API")
        print("   Primary: \(primaryProxyURL)")
        print("   Fallback: \(fallbackProxyURL)")
        #endif
    }
    
    // MARK: - URL Management with Fallback
    
    /// Get the appropriate proxy URL with automatic fallback logic
    private func getProxyBaseURL() async -> String {
        // Try primary URL first
        if await isEndpointHealthy(primaryProxyURL) {
            #if DEBUG
            print("📡 Using primary endpoint: \(primaryProxyURL)")
            #endif
            return primaryProxyURL
        }
        
        // Fallback to secondary URL
        #if DEBUG
        print("⚠️ Primary endpoint unavailable, using fallback: \(fallbackProxyURL)")
        #endif
        return fallbackProxyURL
    }
    
    /// Quick health check for endpoint availability
    private func isEndpointHealthy(_ baseURL: String) async -> Bool {
        guard let url = URL(string: "\(baseURL)/health") else { return false }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
            return false
        } catch {
            #if DEBUG
            print("🚨 Health check failed for \(baseURL): \(error.localizedDescription)")
            #endif
            return false
        }
    }
    
    // MARK: - API Provider Selection
    enum APIProvider: String, CaseIterable, Identifiable {
        case auto = "auto"           // Smart fallback with query translation (Google → ISBNdb → Open Library)
        case isbndb = "isbndb"       // Force ISBNdb only
        case google = "google"       // Force Google Books only
        case openlibrary = "openlibrary" // Force Open Library only
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .auto: return "Smart Fallback (Enhanced)"
            case .isbndb: return "ISBNdb (Premium)"
            case .google: return "Google Books (Fast)"
            case .openlibrary: return "Open Library (Free)"
            }
        }
        
        var systemImage: String {
            switch self {
            case .auto: return "wand.and.stars"
            case .isbndb: return "crown.fill"
            case .google: return "globe"
            case .openlibrary: return "books.vertical"
            }
        }
        
        var description: String {
            switch self {
            case .auto: return "Uses intelligent query translation and provider fallback for best results"
            case .isbndb: return "Premium database with comprehensive metadata, best for author/title searches"
            case .google: return "Fast and comprehensive, supports advanced search operators"
            case .openlibrary: return "Free and open source, good fallback option"
            }
        }
    }
    
    enum SortOption: String, CaseIterable, Identifiable {
        case relevance = "relevance"
        case newest = "newest"
        case popularity = "popularity"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .relevance: return "Most Relevant"
            case .newest: return "Newest First"
            case .popularity: return "Most Popular"
            }
        }
        
        var systemImage: String {
            switch self {
            case .relevance: return "target"
            case .newest: return "calendar"
            case .popularity: return "star.fill"
            }
        }
    }
    
    enum BookError: LocalizedError, Sendable {
        case invalidURL
        case networkError(String)
        case decodingError(String)
        case noData
        case proxyError(String)
        
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
            case .proxyError(let message):
                return "Service error: \(message)"
            }
        }
    }

    // MARK: - Search Tips and Help
    
    static let searchTips: [String] = [
        "📖 Try author names like \"Stephen King\" or \"J.K. Rowling\"",
        "🔍 Use quotes for exact titles like \"Harry Potter\"",
        "👤 Search \"books by [author name]\" for author-specific results",
        "🔢 Enter ISBN numbers (with or without hyphens) for precise lookups",
        "🎯 Use \"inauthor:\" or \"intitle:\" for advanced searches",
        "🌐 The Enhanced provider uses smart query translation for better results"
    ]
    
    // MARK: - Search Methods
    
    func search(
        query: String, 
        sortBy: SortOption = .relevance,
        maxResults: Int = 40,
        includeTranslations: Bool = false,
        provider: APIProvider = .auto
    ) async -> Result<[BookMetadata], BookError> {
        // Handle empty queries
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return .success([])
        }
        
        // Get proxy URL with fallback logic
        let baseURL = await getProxyBaseURL()
        guard var components = URLComponents(string: "\(baseURL)/search") else {
            return .failure(.invalidURL)
        }
        
        // Build query parameters
        var queryItems = [
            URLQueryItem(name: "q", value: optimizeQuery(trimmedQuery)),
            URLQueryItem(name: "maxResults", value: String(maxResults)),
            URLQueryItem(name: "provider", value: provider.rawValue)
        ]
        
        // Add sorting parameter
        switch sortBy {
        case .newest:
            queryItems.append(URLQueryItem(name: "orderBy", value: "newest"))
        case .popularity:
            // Google Books API doesn't have popularity sort, so we'll use a different strategy
            // Send special parameter to proxy to handle popularity sorting
            queryItems.append(URLQueryItem(name: "sortType", value: "popularity"))
        case .relevance:
            queryItems.append(URLQueryItem(name: "orderBy", value: "relevance"))
        }
        
        // Language settings
        if !includeTranslations {
            queryItems.append(URLQueryItem(name: "langRestrict", value: "en"))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            return .failure(.invalidURL)
        }
        
        // Execute request through proxy
        return await executeProxyRequest(url: url) { data in
            let searchResponse = try JSONDecoder().decode(ProxySearchResponse.self, from: data)
            
            // Handle proxy errors
            if let error = searchResponse.error {
                throw ProxyError.serverError(error)
            }
            
            let metadataItems = searchResponse.items?.compactMap { $0.toBookMetadata(provider: searchResponse.provider) } ?? []
            
            // Apply post-processing sorting and filtering
            return self.processSearchResults(
                metadataItems, 
                originalQuery: trimmedQuery,
                sortBy: sortBy
            )
        }
    }
    
    /// Specialized search for author-specific queries
    func searchByAuthor(
        _ author: String,
        sortBy: SortOption = .popularity,
        maxResults: Int = 40,
        includeTranslations: Bool = false
    ) async -> Result<[BookMetadata], BookError> {
        let trimmedAuthor = author.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAuthor.isEmpty else {
            return .success([])
        }
        
        // Format as author-specific query
        let authorQuery = "inauthor:\"\(trimmedAuthor)\""
        
        return await search(
            query: authorQuery,
            sortBy: sortBy,
            maxResults: maxResults,
            includeTranslations: includeTranslations
        )
    }
    
    /// Specialized search for title-specific queries
    func searchByTitle(
        _ title: String,
        sortBy: SortOption = .relevance,
        maxResults: Int = 40,
        includeTranslations: Bool = false
    ) async -> Result<[BookMetadata], BookError> {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            return .success([])
        }
        
        // Format as title-specific query
        let titleQuery = "intitle:\"\(trimmedTitle)\""
        
        return await search(
            query: titleQuery,
            sortBy: sortBy,
            maxResults: maxResults,
            includeTranslations: includeTranslations
        )
    }
    
    /// Specialized search for ISBN lookups with automatic ISBNDB fallback
    func searchByISBN(_ isbn: String, provider: APIProvider = .auto) async -> Result<BookMetadata?, BookError> {
        let cleanedISBN = isbn.replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: "-", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanedISBN.isEmpty else {
            return .success(nil)
        }
        
        // First try: Search by ISBN with specified provider
        let searchResult = await search(
            query: "isbn:\(cleanedISBN)",
            sortBy: .relevance,
            maxResults: 1,
            includeTranslations: false,
            provider: provider
        )
        
        switch searchResult {
        case .success(let books):
            if let book = books.first {
                return .success(book)
            }
            // If primary provider fails, try direct ISBN lookup with same provider
            return await searchByISBNWithISBNDBFallback(cleanedISBN, provider: provider)
            
        case .failure:
            // If primary provider fails, try direct ISBN lookup with same provider
            return await searchByISBNWithISBNDBFallback(cleanedISBN, provider: provider)
        }
    }
    
    /// Enhanced search with automatic ISBNDB fallback for title/author queries
    func searchWithFallback(
        query: String,
        sortBy: SortOption = .relevance,
        maxResults: Int = 40,
        includeTranslations: Bool = false,
        provider: APIProvider = .auto
    ) async -> Result<[BookMetadata], BookError> {
        // First try with specified provider
        let primaryResult = await search(
            query: query,
            sortBy: sortBy,
            maxResults: maxResults,
            includeTranslations: includeTranslations,
            provider: provider
        )
        
        switch primaryResult {
        case .success(let books):
            if !books.isEmpty {
                return .success(books)
            }
            // If Google Books returns no results, try ISBNDB fallback
            return await searchWithISBNDBFallback(
                query: query,
                sortBy: sortBy,
                maxResults: maxResults
            )
            
        case .failure:
            // If Google Books fails completely, try ISBNDB fallback
            return await searchWithISBNDBFallback(
                query: query,
                sortBy: sortBy,
                maxResults: maxResults
            )
        }
    }
    
    /// ISBNDB fallback search for title/author queries
    private func searchWithISBNDBFallback(
        query: String,
        sortBy: SortOption,
        maxResults: Int
    ) async -> Result<[BookMetadata], BookError> {
        let baseURL = await getProxyBaseURL()
        guard var components = URLComponents(string: "\(baseURL)/search") else {
            return .failure(.invalidURL)
        }
        
        var queryItems = [
            URLQueryItem(name: "q", value: optimizeQuery(query)),
            URLQueryItem(name: "maxResults", value: String(maxResults)),
            URLQueryItem(name: "provider", value: "auto") // Use ISBNdb → Google Books → Open Library fallback chain
        ]
        
        // Add sorting parameter
        switch sortBy {
        case .newest:
            queryItems.append(URLQueryItem(name: "orderBy", value: "newest"))
        case .popularity:
            // Google Books API doesn't have popularity sort, so we'll use a different strategy
            // Send special parameter to proxy to handle popularity sorting
            queryItems.append(URLQueryItem(name: "sortType", value: "popularity"))
        case .relevance:
            break // Default relevance sorting
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            return .failure(.invalidURL)
        }
        
        return await executeProxyRequest(url: url) { data in
            let response = try JSONDecoder().decode(ProxySearchResponse.self, from: data)
            
            // Handle proxy errors
            if let error = response.error {
                throw ProxyError.serverError(error)
            }
            
            // Parse results
            let metadataItems = response.items?.map { $0.toBookMetadata(provider: response.provider) } ?? []
            
            // Apply post-processing sorting and filtering
            return self.processSearchResults(
                metadataItems, 
                originalQuery: query,
                sortBy: sortBy
            )
        }
    }
    
    /// Direct ISBNDB fallback for ISBN lookups when Google Books fails
    private func searchByISBNWithISBNDBFallback(_ isbn: String, provider: APIProvider = .auto) async -> Result<BookMetadata?, BookError> {
        let baseURL = await getProxyBaseURL()
        guard var components = URLComponents(string: "\(baseURL)/isbn") else {
            return .failure(.invalidURL)
        }
        
        components.queryItems = [
            URLQueryItem(name: "isbn", value: isbn),
            URLQueryItem(name: "provider", value: provider.rawValue)
        ]
        
        guard let url = components.url else {
            return .failure(.invalidURL)
        }
        
        return await executeProxyRequest(url: url) { data in
            let response = try JSONDecoder().decode(ProxyISBNResponse.self, from: data)
            
            // Handle proxy errors
            if let error = response.error {
                if error.contains("not found") {
                    return nil // ISBN not found in ISBNDB either
                }
                throw ProxyError.serverError(error)
            }
            
            return response.toBookMetadata()
        }
    }
    
    // MARK: - Private Methods
    
    private func executeProxyRequest<T>(
        url: URL,
        decoder: @escaping (Data) throws -> T
    ) async -> Result<T, BookError> {
        
        do {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 30.0
            configuration.timeoutIntervalForResource = 60.0
            configuration.waitsForConnectivity = true
            let session = URLSession(configuration: configuration)
            
            var request = URLRequest(url: url)
            request.setValue("BooksTrack-iOS/1.0", forHTTPHeaderField: "User-Agent")
            
            let (data, response) = try await session.data(for: request)
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                guard 200...299 ~= httpResponse.statusCode else {
                    // Handle specific error cases
                    if httpResponse.statusCode == 429 {
                        let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After") ?? "60"
                        return .failure(.proxyError("Rate limit exceeded. Please try again in \(retryAfter) seconds."))
                    }
                    return .failure(.networkError("HTTP \(httpResponse.statusCode)"))
                }
                
                // Log cache status for debugging
                let cacheStatus = httpResponse.value(forHTTPHeaderField: "X-Cache") ?? "UNKNOWN"
                let provider = httpResponse.value(forHTTPHeaderField: "X-Provider") ?? "unknown"
                
                #if DEBUG
                print("📊 [BookSearch] Provider: \(provider), Cache: \(cacheStatus)")
                #endif
            }
            
            let result = try decoder(data)
            return .success(result)
            
        } catch let error as URLError {
            ErrorHandler.shared.handle(
                error,
                context: "BookSearchService HTTP Request",
                userInfo: ["url": url.absoluteString, "method": "GET"]
            )
            return .failure(.networkError(error.localizedDescription))
        } catch let error as ProxyError {
            ErrorHandler.shared.handle(
                error,
                context: "BookSearchService Proxy Error",
                userInfo: ["url": url.absoluteString, "proxy": "dynamic-fallback"]
            )
            return .failure(.proxyError(error.localizedDescription))
        } catch {
            ErrorHandler.shared.handle(
                error,
                context: "BookSearchService JSON Decoding",
                userInfo: ["url": url.absoluteString, "expected_type": String(describing: T.self)]
            )
            return .failure(.decodingError(error.localizedDescription))
        }
    }
    
    private func optimizeQuery(_ query: String) -> String {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if it's already an operator query
        if trimmed.hasPrefix("isbn:") || trimmed.hasPrefix("inauthor:") || trimmed.hasPrefix("intitle:") {
            return trimmed
        }
        
        // Handle ISBN searches (both direct and with isbn: prefix)
        if isISBN(trimmed) {
            return "isbn:\(trimmed.replacingOccurrences(of: "=", with: "").replacingOccurrences(of: "-", with: ""))"
        }
        
        // Handle author-specific searches with "by"
        if trimmed.lowercased().contains("by ") {
            let parts = trimmed.components(separatedBy: " by ")
            if parts.count == 2 {
                return "intitle:\"\(parts[0].trimmingCharacters(in: .whitespacesAndNewlines))\" inauthor:\"\(parts[1].trimmingCharacters(in: .whitespacesAndNewlines))\""
            }
        }
        
        // Handle title searches with quotes - but be more conservative
        if trimmed.contains("\"") && trimmed.count > 3 {
            return "intitle:\(trimmed)" // Treat quoted searches as title searches
        }
        
        // NEW: Enhanced query optimization for the improved proxy
        // The proxy now has query translation, so we can be more intelligent
        
        // Check if it looks like an author name (2-4 words, no numbers, proper case)
        let words = trimmed.components(separatedBy: " ").filter { !$0.isEmpty }
        let looksLikeAuthor = words.count >= 2 && 
                             words.count <= 4 && 
                             words.allSatisfy { word in
                                 word.first?.isUppercase == true && 
                                 !word.contains(where: { $0.isNumber }) &&
                                 word.count > 1
                             } &&
                             !trimmed.lowercased().contains("the ")
        
        if looksLikeAuthor {
            return "inauthor:\"\(trimmed)\""
        }
        
        // Check if it looks like a book title (longer phrases, contains common title words)
        let titleIndicators = ["a ", "an ", "the ", "of ", "in ", "on ", "for ", "with ", "and ", "or "]
        let containsTitleWords = titleIndicators.contains { trimmed.lowercased().contains($0) }
        
        if containsTitleWords || words.count > 4 {
            return "intitle:\"\(trimmed)\""
        }
        
        // For short general searches, let the proxy decide the best strategy
        // Don't use complex OR queries - the proxy's translation layer handles this better
        return trimmed
    }
    
    private func isISBN(_ string: String) -> Bool {
        let cleaned = string.replacingOccurrences(of: "=", with: "").replacingOccurrences(of: "-", with: "")
        return cleaned.count == 10 || cleaned.count == 13 && cleaned.allSatisfy { $0.isNumber }
    }
    
    private func processSearchResults(
        _ results: [BookMetadata], 
        originalQuery: String,
        sortBy: SortOption
    ) -> [BookMetadata] {
        
        // Filter out low-quality results
        let filteredResults = results.filter { metadata in
            guard !metadata.title.isEmpty && !metadata.authors.isEmpty else { return false }
            
            let title = metadata.title.lowercased()
            let badKeywords = ["magazine", "journal", "newsletter", "catalog", "brochure"]
            return !badKeywords.contains { title.contains($0) }
        }
        
        // Remove duplicates based on title and author similarity
        let deduplicatedResults = removeDuplicates(filteredResults)
        
        // Apply sorting (proxy handles basic sorting, but we can fine-tune)
        let sortedResults = sortResults(deduplicatedResults, by: sortBy, originalQuery: originalQuery)
        
        return sortedResults
    }
    
    private func removeDuplicates(_ results: [BookMetadata]) -> [BookMetadata] {
        var uniqueResults: [BookMetadata] = []
        
        for result in results {
            // Check if this is a duplicate (ISBN match takes priority)
            if let existingIndex = uniqueResults.firstIndex(where: { existing in
                // First check ISBN match (most reliable)
                if let resultISBN = result.isbn,
                   let existingISBN = existing.isbn,
                   !resultISBN.isEmpty && !existingISBN.isEmpty {
                    return cleanISBN(resultISBN) == cleanISBN(existingISBN)
                }
                
                // Fall back to title/author similarity
                let titleSimilarity = stringSimilarity(result.title, existing.title)
                let authorSimilarity = authorsSimilarity(result.authors, existing.authors)
                return titleSimilarity > 0.85 && authorSimilarity > 0.8
            }) {
                // Merge data from both results, keeping the most complete information
                uniqueResults[existingIndex] = mergeBookMetadata(primary: uniqueResults[existingIndex], secondary: result)
            } else {
                uniqueResults.append(result)
            }
        }
        
        return uniqueResults
    }
    
    /// Clean ISBN for comparison (remove hyphens, spaces, etc.)
    private func cleanISBN(_ isbn: String) -> String {
        return isbn.replacingOccurrences(of: "-", with: "")
                  .replacingOccurrences(of: " ", with: "")
                  .replacingOccurrences(of: "=", with: "")
                  .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Merge two BookMetadata objects, keeping the most complete information
    private func mergeBookMetadata(primary: BookMetadata, secondary: BookMetadata) -> BookMetadata {
        // Update primary with missing data from secondary
        if primary.title.isEmpty && !secondary.title.isEmpty {
            primary.title = secondary.title
        }
        
        if primary.authors.isEmpty && !secondary.authors.isEmpty {
            primary.authors = secondary.authors
        }
        
        if primary.pageCount == nil && secondary.pageCount != nil {
            primary.pageCount = secondary.pageCount
        }
        
        if primary.publishedDate == nil && secondary.publishedDate != nil {
            primary.publishedDate = secondary.publishedDate
        }
        
        if primary.imageURL == nil && secondary.imageURL != nil {
            primary.imageURL = secondary.imageURL
        }
        
        if primary.bookDescription == nil && secondary.bookDescription != nil {
            primary.bookDescription = secondary.bookDescription
        }
        
        if primary.publisher == nil && secondary.publisher != nil {
            primary.publisher = secondary.publisher
        }
        
        if primary.language == nil && secondary.language != nil {
            primary.language = secondary.language
        }
        
        if primary.isbn == nil && secondary.isbn != nil {
            primary.isbn = secondary.isbn
        }
        
        if primary.genre.isEmpty && !secondary.genre.isEmpty {
            primary.genre = secondary.genre
        }
        
        return primary
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
                    score += titleWord == queryWord ? 10 : 5
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
        
        if metadata.imageURL != nil { score += 3 }
        if metadata.bookDescription != nil && !metadata.bookDescription!.isEmpty { score += 2 }
        
        if let publisher = metadata.publisher?.lowercased() {
            let majorPublishers = ["penguin", "random house", "harpercollins", "simon", "macmillan", "scholastic"]
            if majorPublishers.contains(where: publisher.contains) {
                score += 5
            }
        }
        
        if let pageCount = metadata.pageCount {
            if pageCount >= 100 && pageCount <= 800 {
                score += 2
            }
        }
        
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

// MARK: - Proxy Response Models

private struct ProxySearchResponse: Codable {
    let kind: String?
    let totalItems: Int?
    let provider: String?
    let cached: Bool?
    let items: [ProxyVolumeItem]?
    let error: String?
}

private struct ProxyISBNResponse: Codable {
    let kind: String?
    let id: String?
    let volumeInfo: ProxyVolumeInfo?
    let provider: String?
    let error: String?
    let isbn: String?
    
    func toBookMetadata() -> BookMetadata? {
        guard let volumeInfo = volumeInfo else { return nil }
        return ProxyVolumeItem(kind: kind ?? "", id: id ?? "", volumeInfo: volumeInfo, culturalMetadata: nil).toBookMetadata(provider: provider)
    }
}

private struct ProxyVolumeItem: Codable {
    let kind: String
    let id: String
    let volumeInfo: ProxyVolumeInfo
    let culturalMetadata: ProxyCulturalMetadata?
    
    func toBookMetadata(provider: String? = nil) -> BookMetadata {
        let isbn13 = volumeInfo.industryIdentifiers?.first(where: { $0.type == "ISBN_13" })?.identifier
        let isbn10 = volumeInfo.industryIdentifiers?.first(where: { $0.type == "ISBN_10" })?.identifier

        var fieldSources: [String: DataSourceInfo] = [:]
        let apiSourceInfo = DataSourceInfo(source: .proxyAPI, confidence: 1.0)
        
        // Track all fields from proxy API
        fieldSources["title"] = apiSourceInfo
        if let authors = volumeInfo.authors, !authors.isEmpty {
            fieldSources["authors"] = apiSourceInfo
        }
        if volumeInfo.publishedDate != nil {
            fieldSources["publishedDate"] = apiSourceInfo
        }
        if volumeInfo.pageCount != nil {
            fieldSources["pageCount"] = apiSourceInfo
        }
        if volumeInfo.description != nil {
            fieldSources["bookDescription"] = apiSourceInfo
        }
        if volumeInfo.imageLinks?.thumbnail != nil {
            fieldSources["imageURL"] = apiSourceInfo
        }
        if volumeInfo.language != nil {
            fieldSources["language"] = apiSourceInfo
        }
        if volumeInfo.publisher != nil {
            fieldSources["publisher"] = apiSourceInfo
        }
        if isbn13 != nil || isbn10 != nil {
            fieldSources["isbn"] = apiSourceInfo
        }
        if let categories = volumeInfo.categories, !categories.isEmpty {
            fieldSources["genre"] = apiSourceInfo
        }

        // Extract enhanced cultural metadata from the API response
        var extractedNationality: String? = nil
        var extractedGender: AuthorGender? = nil
        var extractedRegion: CulturalRegion? = nil
        var extractedThemes: [String] = []
        
        if let culturalMeta = culturalMetadata, let authors = culturalMeta.authors, !authors.isEmpty {
            // Use the first author's cultural data as primary
            if let firstAuthor = authors.first, let profile = firstAuthor.culturalProfile {
                
                // Map nationality from API (handle adjective forms)
                if let nationalityString = profile.nationality?.lowercased() {
                    switch nationalityString {
                    case "american": 
                        extractedNationality = "United States"
                        extractedRegion = .northAmerica
                    case "british", "english": 
                        extractedNationality = "United Kingdom"
                        extractedRegion = .europe
                    case "canadian": 
                        extractedNationality = "Canada"
                        extractedRegion = .northAmerica
                    case "japanese": 
                        extractedNationality = "Japan"
                        extractedRegion = .asia
                    case "chinese": 
                        extractedNationality = "China"
                        extractedRegion = .asia
                    case "indian": 
                        extractedNationality = "India"
                        extractedRegion = .asia
                    case "french": 
                        extractedNationality = "France"
                        extractedRegion = .europe
                    case "german": 
                        extractedNationality = "Germany"
                        extractedRegion = .europe
                    case "african":
                        // Generic "African" - don't set specific country, but set region
                        extractedNationality = nil
                        extractedRegion = .africa
                    case "european":
                        extractedNationality = nil
                        extractedRegion = .europe
                    case "asian":
                        extractedNationality = nil
                        extractedRegion = .asia
                    default:
                        // If it's already a country name, use as-is
                        extractedNationality = profile.nationality
                    }
                }
                
                // Map gender from API to enum
                if let genderString = profile.gender {
                    switch genderString.lowercased() {
                    case "female": extractedGender = .female
                    case "male": extractedGender = .male
                    case "non-binary", "nonbinary": extractedGender = .nonBinary
                    case "other": extractedGender = .other
                    default: extractedGender = .unknown
                    }
                }
                
                // If region not set by nationality, try explicit regions from API
                if extractedRegion == nil, let regions = profile.regions, !regions.isEmpty {
                    let regionString = regions.first?.lowercased() ?? ""
                    switch regionString {
                    case "africa": extractedRegion = .africa
                    case "asia": extractedRegion = .asia
                    case "europe": extractedRegion = .europe
                    case "north america", "northamerica": extractedRegion = .northAmerica
                    case "south america", "southamerica": extractedRegion = .southAmerica
                    case "oceania": extractedRegion = .oceania
                    case "middle east", "middleeast": extractedRegion = .middleEast
                    case "caribbean": extractedRegion = .caribbean
                    case "central asia", "centralasia": extractedRegion = .centralAsia
                    case "indigenous": extractedRegion = .indigenous
                    default: break
                    }
                }
                
                // Extract cultural themes
                if let themes = profile.themes {
                    extractedThemes = themes
                }
            }
            
            // Add cultural data to field sources if available
            if extractedNationality != nil {
                fieldSources["authorNationality"] = apiSourceInfo
            }
            if extractedGender != nil {
                fieldSources["authorGender"] = apiSourceInfo
            }
            if extractedRegion != nil {
                fieldSources["culturalRegion"] = apiSourceInfo
            }
            if !extractedThemes.isEmpty {
                fieldSources["culturalThemes"] = apiSourceInfo
            }
        }

        let totalFields: Double = 14.0  // Updated count including cultural fields
        let presentFields = Double(fieldSources.count)
        let completeness = presentFields / totalFields

        // Handle different provider IDs appropriately with proper prefixing
        let providerID: String
        if let provider = provider?.lowercased() {
            switch provider {
            case "isbndb":
                // Prefix ISBNDB book_id to distinguish from Google Books IDs
                providerID = "isbndb:\(self.id)"
            case "google-books":
                // Use Google Books ID as-is
                providerID = self.id
            default:
                // Unknown provider - use prefixed ID
                providerID = "\(provider):\(self.id)"
            }
        } else {
            // No provider specified - assume Google Books
            providerID = self.id
        }
        
        return BookMetadata(
            googleBooksID: providerID,
            title: volumeInfo.title ?? "",
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
            genre: volumeInfo.categories ?? [],
            authorNationality: extractedNationality,
            authorGender: extractedGender,
            culturalRegion: extractedRegion,
            culturalThemes: extractedThemes,
            dataSource: .proxyAPI,
            fieldDataSources: fieldSources,
            dataCompleteness: completeness,
            dataQualityScore: 1.0
        )
    }
}

private struct ProxyVolumeInfo: Codable {
    let title: String?
    let authors: [String]?
    let publisher: String?
    let publishedDate: String?
    let description: String?
    let industryIdentifiers: [ProxyIndustryIdentifier]?
    let pageCount: Int?
    let categories: [String]?
    let imageLinks: ProxyImageLinks?
    let language: String?
    let previewLink: String?
    let infoLink: String?
}

private struct ProxyIndustryIdentifier: Codable {
    let type: String
    let identifier: String
}

private struct ProxyImageLinks: Codable {
    let smallThumbnail: String?
    let thumbnail: String?
}

// MARK: - Enhanced Cultural Metadata Structures

private struct ProxyCulturalMetadata: Codable {
    let authors: [ProxyAuthorCultural]?
    let diversityScore: ProxyDiversityScore?
    let lastUpdated: Double?
    let version: String?
}

private struct ProxyAuthorCultural: Codable {
    let name: String?
    let culturalProfile: ProxyAuthorCulturalProfile?
    let confidence: Double?
}

private struct ProxyAuthorCulturalProfile: Codable {
    let nationality: String?
    let gender: String?
    let languages: [String]?
    let regions: [String]?
    let themes: [String]?
    let timeSpan: ProxyTimeSpan?
    let lastUpdated: Double?
    let confidence: Double?
}

private struct ProxyTimeSpan: Codable {
    let earliest: Int?
    let latest: Int?
}

private struct ProxyDiversityScore: Codable {
    let regions: [String: Double]?
    let languages: [String: Double]?
    let genders: [String: Double]?
    let score: Double?
}

private enum ProxyError: LocalizedError {
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .serverError(let message):
            return message
        }
    }
}

private extension String {
    func replacingHTTPWithHTTPS() -> URL? {
        if self.starts(with: "http://") {
            return URL(string: self.replacingOccurrences(of: "http://", with: "https://"))
        }
        return URL(string: self)
    }
}

// MARK: - Data Source Extension

extension DataSource {
    static let proxyAPI = DataSource(rawValue: "proxyAPI") ?? .googleBooksAPI
}