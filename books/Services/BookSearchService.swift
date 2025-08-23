// books/Services/BookSearchServiceProxy.swift
import Foundation
import SwiftData
import SwiftUI

// MARK: - Proxy-Based Book Search Service

@MainActor
class BookSearchService: ObservableObject {
    static let shared = BookSearchService()
    
    // MARK: - Configuration
    
    /// Your CloudFlare Worker endpoint - update this after deployment
    private let proxyBaseURL = "https://books-api-proxy.jukasdrj.workers.dev"
    
    private init() {
        #if DEBUG
        print("✅ BookSearchService: Using proxy-based API at \(proxyBaseURL)")
        #endif
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

    // MARK: - Search Methods
    
    func search(
        query: String, 
        sortBy: SortOption = .relevance,
        maxResults: Int = 40,
        includeTranslations: Bool = false
    ) async -> Result<[BookMetadata], BookError> {
        // Handle empty queries
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return .success([])
        }
        
        // Build proxy URL
        guard var components = URLComponents(string: "\(proxyBaseURL)/search") else {
            return .failure(.invalidURL)
        }
        
        // Build query parameters
        var queryItems = [
            URLQueryItem(name: "q", value: optimizeQuery(trimmedQuery)),
            URLQueryItem(name: "maxResults", value: String(maxResults)),
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
    func searchByISBN(_ isbn: String) async -> Result<BookMetadata?, BookError> {
        let cleanedISBN = isbn.replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: "-", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanedISBN.isEmpty else {
            return .success(nil)
        }
        
        // First try: Google Books via search endpoint (more reliable for ISBN)
        let searchResult = await search(
            query: "isbn:\(cleanedISBN)",
            sortBy: .relevance,
            maxResults: 1,
            includeTranslations: false
        )
        
        switch searchResult {
        case .success(let books):
            if let book = books.first {
                return .success(book)
            }
            // If Google Books fails, try ISBNDB fallback
            return await searchByISBNWithISBNDBFallback(cleanedISBN)
            
        case .failure:
            // If Google Books fails, try ISBNDB fallback
            return await searchByISBNWithISBNDBFallback(cleanedISBN)
        }
    }
    
    /// Enhanced search with automatic ISBNDB fallback for title/author queries
    func searchWithFallback(
        query: String,
        sortBy: SortOption = .relevance,
        maxResults: Int = 40,
        includeTranslations: Bool = false
    ) async -> Result<[BookMetadata], BookError> {
        // First try Google Books
        let primaryResult = await search(
            query: query,
            sortBy: sortBy,
            maxResults: maxResults,
            includeTranslations: includeTranslations
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
        guard var components = URLComponents(string: "\(proxyBaseURL)/search") else {
            return .failure(.invalidURL)
        }
        
        var queryItems = [
            URLQueryItem(name: "q", value: optimizeQuery(query)),
            URLQueryItem(name: "maxResults", value: String(maxResults)),
            URLQueryItem(name: "provider", value: "isbndb"), // Force ISBNDB
            URLQueryItem(name: "fallback", value: "true")    // Enable fallback mode
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
    private func searchByISBNWithISBNDBFallback(_ isbn: String) async -> Result<BookMetadata?, BookError> {
        guard var components = URLComponents(string: "\(proxyBaseURL)/isbn") else {
            return .failure(.invalidURL)
        }
        
        components.queryItems = [
            URLQueryItem(name: "isbn", value: isbn),
            URLQueryItem(name: "provider", value: "isbndb"), // Force ISBNDB
            URLQueryItem(name: "fallback", value: "true")    // Enable fallback mode
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
        decoder: @escaping (Data) throws -> T,
        retryCount: Int = 0
    ) async -> Result<T, BookError> {
        
        do {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 20.0  // Reduced timeout for better UX
            configuration.timeoutIntervalForResource = 40.0
            configuration.waitsForConnectivity = true
            let session = URLSession(configuration: configuration)
            
            var request = URLRequest(url: url)
            request.setValue("BooksTrack-iOS/1.0", forHTTPHeaderField: "User-Agent")
            request.cachePolicy = .reloadIgnoringLocalCacheData // Force fresh requests for search
            
            let (data, response) = try await session.data(for: request)
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                guard 200...299 ~= httpResponse.statusCode else {
                    // Handle specific error cases with retry logic
                    switch httpResponse.statusCode {
                    case 429:
                        let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After") ?? "60"
                        return .failure(.proxyError("Too many requests. Please wait \(retryAfter) seconds before trying again."))
                    case 500...599:
                        // Server error - retry if we haven't exceeded limit
                        if retryCount < 2 {
                            let delay = pow(2.0, Double(retryCount)) // Exponential backoff
                            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                            return await executeProxyRequest(url: url, decoder: decoder, retryCount: retryCount + 1)
                        }
                        return .failure(.networkError("Server temporarily unavailable. Please try again later."))
                    case 404:
                        return .failure(.noData)
                    default:
                        return .failure(.networkError("Unable to connect to book database (Error \(httpResponse.statusCode))"))
                    }
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
            // Handle network-specific errors with user-friendly messages
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .failure(.networkError("No internet connection. Please check your network and try again."))
            case .timedOut:
                if retryCount < 1 {
                    return await executeProxyRequest(url: url, decoder: decoder, retryCount: retryCount + 1)
                }
                return .failure(.networkError("Request timed out. Please try again."))
            case .cannotConnectToHost, .cannotFindHost:
                return .failure(.networkError("Unable to connect to book database. Please try again later."))
            case .secureConnectionFailed:
                return .failure(.networkError("Secure connection failed. Please check your internet connection."))
            default:
                return .failure(.networkError("Network error occurred. Please check your connection and try again."))
            }
        } catch let error as ProxyError {
            return .failure(.proxyError(error.localizedDescription))
        } catch {
            return .failure(.decodingError("Unable to process response from book database. Please try again."))
        }
    }
    
    private func optimizeQuery(_ query: String) -> String {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if it's already an ISBN query
        if trimmed.hasPrefix("isbn:") {
            return trimmed
        }
        
        // Handle ISBN searches
        if isISBN(trimmed) {
            return "isbn:\(trimmed.replacingOccurrences(of: "=", with: "").replacingOccurrences(of: "-", with: ""))"
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
            let isDuplicate = uniqueResults.contains { existing in
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
        return ProxyVolumeItem(kind: kind ?? "", id: id ?? "", volumeInfo: volumeInfo).toBookMetadata(provider: provider)
    }
}

private struct ProxyVolumeItem: Codable {
    let kind: String
    let id: String
    let volumeInfo: ProxyVolumeInfo
    
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

        let totalFields: Double = 10.0
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