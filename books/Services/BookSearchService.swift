// books-buildout-main/books/BookSearchService.swift
import Foundation

// MARK: - Cloudflare AI Gateway Integration

/// Configuration and management for Cloudflare AI Gateway integration
@MainActor
class CloudflareGatewayService: ObservableObject {
    static let shared = CloudflareGatewayService()
    
    // MARK: - Gateway Configuration
    
    /// Your Cloudflare Account ID (you'll need to get this from Cloudflare dashboard)
    /// This should be a 32-character alphanumeric string, not an email address
    private let accountId = "d03bed0be6d976acd8a1707b55052f79" // Your Cloudflare Account ID
    
    /// Your AI Gateway ID (set this to your gateway name)
    private let gatewayId = "books-api-gateway" // TODO: Replace with your Gateway ID
    
    /// Base URL for Google Books API through Cloudflare AI Gateway
    private var gatewayBaseURL: String {
        "https://gateway.ai.cloudflare.com/v1/\(accountId)/\(gatewayId)/google-books"
    }
    
    /// Fallback to direct Google Books API if gateway fails
    private let fallbackBaseURL = "https://www.googleapis.com/books/v1/volumes"
    
    private init() {}
    
    // MARK: - Gateway Integration
    
    /// Enhanced URL request with Cloudflare AI Gateway headers
    func createGatewayRequest(for components: URLComponents, cacheTTL: Int = 3600) -> URLRequest? {
        // First try to construct gateway URL
        guard let originalURL = components.url else { return nil }
        
        // Replace the base URL with gateway URL
        let urlString = originalURL.absoluteString.replacingOccurrences(
            of: "https://www.googleapis.com/books/v1/volumes",
            with: gatewayBaseURL + "/v1/volumes"
        )
        
        guard let gatewayURL = URL(string: urlString) else { return nil }
        
        var request = URLRequest(url: gatewayURL)
        
        // Add Cloudflare AI Gateway headers for caching and cost optimization
        addGatewayHeaders(to: &request, cacheTTL: cacheTTL)
        
        return request
    }
    
    /// Add Cloudflare AI Gateway optimization headers
    private func addGatewayHeaders(to request: inout URLRequest, cacheTTL: Int = 3600) {
        // Cache duration based on request type
        request.setValue(String(cacheTTL), forHTTPHeaderField: "cf-aig-cache-ttl")
        
        // Add custom cost tracking (estimate: $0.001 per request)
        request.setValue("{\"per_request\": 0.001}", forHTTPHeaderField: "cf-aig-custom-cost")
        
        // Add metadata for analytics
        let metadata = [
            "app": "books-tracker",
            "api": "google-books",
            "version": "1.0"
        ]
        
        if let metadataData = try? JSONSerialization.data(withJSONObject: metadata),
           let metadataString = String(data: metadataData, encoding: .utf8) {
            request.setValue(metadataString, forHTTPHeaderField: "cf-aig-metadata")
        }
        
        // Set reasonable timeout
        request.timeoutInterval = 30.0
    }
    
    /// Create fallback request for direct Google Books API
    func createFallbackRequest(for components: URLComponents) -> URLRequest? {
        guard let url = components.url else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 20.0
        return request
    }
    
    // MARK: - Configuration Validation
    
    /// Check if gateway is properly configured
    var isGatewayConfigured: Bool {
        return !accountId.contains("YOUR_ACCOUNT_ID_HERE") && 
               !gatewayId.isEmpty &&
               accountId.count > 10 // Basic validation
    }
    
    /// Get configuration status for debugging
    func getConfigurationStatus() -> String {
        var status = "Cloudflare AI Gateway Configuration:\n"
        status += "- Account ID: \(accountId.contains("YOUR_ACCOUNT_ID_HERE") ? "❌ Not configured" : "✅ Set")\n"
        status += "- Gateway ID: \(gatewayId.isEmpty ? "❌ Empty" : "✅ \(gatewayId)")\n"
        status += "- Gateway URL: \(gatewayBaseURL)\n"
        status += "- Status: \(isGatewayConfigured ? "✅ Ready" : "❌ Needs configuration")"
        return status
    }
    
    // MARK: - Request Execution
    
    /// Execute request with gateway fallback
    func executeWithFallback<T>(
        components: URLComponents,
        cacheTTL: Int = 3600,
        decoder: @escaping (Data) throws -> T
    ) async -> Result<T, BookSearchService.BookError> {
        
        // First, try the gateway
        if isGatewayConfigured {
            let gatewayResult = await executeGatewayRequest(components: components, cacheTTL: cacheTTL, decoder: decoder)
            
            switch gatewayResult {
            case .success(let result):
                #if DEBUG
                print("✅ [Gateway] Request successful")
                #endif
                return .success(result)
            case .failure(let error):
                #if DEBUG
                print("⚠️ [Gateway] Failed, falling back to direct API: \(error.localizedDescription)")
                #endif
            }
        }
        
        // Fallback to direct API
        return await executeFallbackRequest(components: components, decoder: decoder)
    }
    
    private func executeGatewayRequest<T>(
        components: URLComponents,
        cacheTTL: Int = 3600,
        decoder: @escaping (Data) throws -> T
    ) async -> Result<T, BookSearchService.BookError> {
        
        guard let request = createGatewayRequest(for: components, cacheTTL: cacheTTL) else {
            return .failure(.invalidURL)
        }
        
        return await executeRequest(request, decoder: decoder)
    }
    
    private func executeFallbackRequest<T>(
        components: URLComponents,
        decoder: @escaping (Data) throws -> T
    ) async -> Result<T, BookSearchService.BookError> {
        
        guard let request = createFallbackRequest(for: components) else {
            return .failure(.invalidURL)
        }
        
        let result = await executeRequest(request, decoder: decoder)
        #if DEBUG
        print("📡 [Direct API] Request executed")
        #endif
        return result
    }
    
    private func executeRequest<T>(
        _ request: URLRequest,
        decoder: @escaping (Data) throws -> T
    ) async -> Result<T, BookSearchService.BookError> {
        
        do {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 30.0
            configuration.timeoutIntervalForResource = 60.0
            configuration.waitsForConnectivity = true
            let session = URLSession(configuration: configuration)
            
            let (data, response) = try await session.data(for: request)
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                guard 200...299 ~= httpResponse.statusCode else {
                    return .failure(.networkError("HTTP \(httpResponse.statusCode)"))
                }
                
                // Check for cache hit in Cloudflare headers
                let cacheStatus = httpResponse.value(forHTTPHeaderField: "cf-cache-status") ?? "MISS"
                let wasCacheHit = cacheStatus == "HIT"
                
                #if DEBUG
                if wasCacheHit {
                    print("🚀 [Cache HIT] Response served from Cloudflare cache")
                }
                #endif
            }
            
            let result = try decoder(data)
            return .success(result)
            
        } catch let error as URLError {
            return .failure(.networkError(error.localizedDescription))
        } catch {
            return .failure(.decodingError(error.localizedDescription))
        }
    }
}

// MARK: - Book Search Service

@MainActor
class BookSearchService: ObservableObject {
    static let shared = BookSearchService()
    private let keychainService = KeychainService.shared
    private let gatewayService = CloudflareGatewayService.shared
    
    private init() {
        // Ensure API keys are set up on initialization
        keychainService.setupInitialKeys()
        
        #if DEBUG
        keychainService.printKeyStatus()
        print(gatewayService.getConfigurationStatus())
        #endif
    }

    private let baseURL = "https://www.googleapis.com/books/v1/volumes"
    
    /// Secure API key retrieved from Keychain
    private var apiKey: String? {
        return keychainService.googleBooksAPIKey
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
        
        // Check for API key availability
        guard let secureApiKey = self.apiKey else {
            #if DEBUG
            print("❌ BookSearchService: Google Books API key not found in Keychain")
            #endif
            return .failure(.networkError("API key not configured. Please restart the app to initialize secure storage."))
        }
        
        // Starting search with optimized query
        
        guard var components = URLComponents(string: baseURL) else {
            // Invalid base URL
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
        
        // Add secure API key
        queryItems.append(URLQueryItem(name: "key", value: secureApiKey))
        
        components.queryItems = queryItems

        guard components.url != nil else {
            // Failed to construct URL from components
            return .failure(.invalidURL)
        }
        
        // Making network request through Cloudflare AI Gateway with fallback

        let result = await gatewayService.executeWithFallback(
            components: components
        ) { [self] data in
            let searchResponse = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
            let metadataItems = searchResponse.items?.compactMap { $0.toBookMetadata() } ?? []
            
            // Apply post-processing sorting and filtering
            return self.processSearchResults(
                metadataItems, 
                originalQuery: trimmedQuery,
                sortBy: sortBy
            )
        }
        
        return result
    }
    
    /// Specialized search for ISBN lookups with aggressive caching (used by CSVImportService)
    func searchByISBN(_ isbn: String) async -> Result<BookMetadata?, BookError> {
        let cleanedISBN = isbn.replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: "-", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanedISBN.isEmpty else {
            return .success(nil)
        }
        
        // Check for API key availability
        guard let secureApiKey = self.apiKey else {
            return .failure(.networkError("API key not configured"))
        }
        
        guard var components = URLComponents(string: baseURL) else {
            return .failure(.invalidURL)
        }
        
        // Build ISBN query with more aggressive caching (24 hours)
        let queryItems = [
            URLQueryItem(name: "q", value: "isbn:\(cleanedISBN)"),
            URLQueryItem(name: "maxResults", value: "1"),
            URLQueryItem(name: "printType", value: "books"),
            URLQueryItem(name: "projection", value: "full"),
            URLQueryItem(name: "key", value: secureApiKey)
        ]
        
        components.queryItems = queryItems
        
        let result = await gatewayService.executeWithFallback(
            components: components,
            cacheTTL: 86400 // 24 hours - ISBN data never changes
        ) { data in
            let searchResponse = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
            return searchResponse.items?.first?.toBookMetadata()
        }
        
        return result
    }
    
    // MARK: - Query Optimization
    
    private func buildOptimizedQuery(_ query: String) -> String {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if it's already an ISBN query (handle CSVImportService calls)
        if trimmed.hasPrefix("isbn:") {
            // Already formatted, ensure clean ISBN after prefix
            let isbnPart = String(trimmed.dropFirst(5))
                .replacingOccurrences(of: "=", with: "")
                .replacingOccurrences(of: "-", with: "")
                .replacingOccurrences(of: " ", with: "")
            return "isbn:\(isbnPart)"
        }
        
        // Handle ISBN searches
        if isISBN(trimmed) {
            return "isbn:\(trimmed.replacingOccurrences(of: "=", with: "").replacingOccurrences(of: "-", with: ""))"
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
        let cleaned = string.replacingOccurrences(of: "=", with: "").replacingOccurrences(of: "-", with: "")
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

        // Create field-level data sources for API data
        var fieldSources: [String: DataSourceInfo] = [:]
        let apiSourceInfo = DataSourceInfo(source: .googleBooksAPI, confidence: 1.0)
        
        // Track all fields from Google Books API
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

        // Calculate completeness based on available fields
        let totalFields: Double = 10.0 // Core fields we expect from API
        let presentFields = Double(fieldSources.count)
        let completeness = presentFields / totalFields

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
            genre: volumeInfo.categories ?? [],
            dataSource: .googleBooksAPI,
            fieldDataSources: fieldSources,
            dataCompleteness: completeness,
            dataQualityScore: 1.0
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
