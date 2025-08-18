// books/Services/BookSearchServiceProxy.swift
import Foundation

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
        includeTranslations: Bool = true
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
            return .failure(.invalidURL)
        }
        
        // Execute request through proxy
        return await executeProxyRequest(url: url) { data in
            let searchResponse = try JSONDecoder().decode(ProxySearchResponse.self, from: data)
            
            // Handle proxy errors
            if let error = searchResponse.error {
                throw ProxyError.serverError(error)
            }
            
            let metadataItems = searchResponse.items?.compactMap { $0.toBookMetadata() } ?? []
            
            // Apply post-processing sorting and filtering
            return self.processSearchResults(
                metadataItems, 
                originalQuery: trimmedQuery,
                sortBy: sortBy
            )
        }
    }
    
    /// Specialized search for ISBN lookups
    func searchByISBN(_ isbn: String) async -> Result<BookMetadata?, BookError> {
        let cleanedISBN = isbn.replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: "-", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanedISBN.isEmpty else {
            return .success(nil)
        }
        
        guard var components = URLComponents(string: "\(proxyBaseURL)/isbn") else {
            return .failure(.invalidURL)
        }
        
        components.queryItems = [
            URLQueryItem(name: "isbn", value: cleanedISBN)
        ]
        
        guard let url = components.url else {
            return .failure(.invalidURL)
        }
        
        return await executeProxyRequest(url: url) { data in
            let response = try JSONDecoder().decode(ProxyISBNResponse.self, from: data)
            
            // Handle proxy errors
            if let error = response.error {
                if error.contains("not found") {
                    return nil // ISBN not found
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
            return .failure(.networkError(error.localizedDescription))
        } catch let error as ProxyError {
            return .failure(.proxyError(error.localizedDescription))
        } catch {
            return .failure(.decodingError(error.localizedDescription))
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
        return ProxyVolumeItem(kind: kind ?? "", id: id ?? "", volumeInfo: volumeInfo).toBookMetadata()
    }
}

private struct ProxyVolumeItem: Codable {
    let kind: String
    let id: String
    let volumeInfo: ProxyVolumeInfo
    
    func toBookMetadata() -> BookMetadata {
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

        return BookMetadata(
            googleBooksID: self.id,
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