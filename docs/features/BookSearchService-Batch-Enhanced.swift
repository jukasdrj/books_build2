// Enhanced BookSearchService with Batch Support
// Supports both single lookups and efficient batch processing for CSV imports

import Foundation
import SwiftData
import SwiftUI

@MainActor
class BookSearchService: ObservableObject {
    static let shared = BookSearchService()
    
    // MARK: - Configuration
    private let proxyBaseURL = "https://books-api-proxy.jukasdrj.workers.dev"
    
    // MARK: - Batch Configuration
    struct BatchConfig {
        static let maxBatchSize = 100        // CloudFlare Worker limit
        static let optimalBatchSize = 50     // Sweet spot for performance
        static let csvImportBatchSize = 25   // Conservative for CSV imports
        static let maxConcurrentBatches = 3  // Parallel batch processing
    }
    
    // MARK: - Provider Selection
    enum APIProvider: String, CaseIterable {
        case auto = ""
        case google = "google"
        case isbndb = "isbndb" 
        case openLibrary = "openlibrary"
        
        var displayName: String {
            switch self {
            case .auto: return "Automatic"
            case .google: return "Google Books"
            case .isbndb: return "ISBNdb"
            case .openLibrary: return "Open Library"
            }
        }
        
        var supportsBatching: Bool {
            switch self {
            case .isbndb: return true  // ISBNdb has native batch support
            case .google: return false // Individual requests only
            case .openLibrary: return false // Individual requests only
            case .auto: return true    // Will use best available
            }
        }
    }
    
    // MARK: - Batch Result Types
    struct BatchLookupResult {
        let results: [ISBNLookupResult]
        let total: Int
        let found: Int
        let cached: Int
        let fresh: Int
        let provider: String
        let processingTime: TimeInterval
        let requestId: String
        
        var successRate: Double {
            return total > 0 ? Double(found) / Double(total) : 0.0
        }
    }
    
    struct ISBNLookupResult {
        let isbn: String
        let found: Bool
        let bookMetadata: BookMetadata?
        let error: String?
        let source: String? // "cache" or "api"
        
        init(isbn: String, bookMetadata: BookMetadata?, source: String? = nil) {
            self.isbn = isbn
            self.found = bookMetadata != nil
            self.bookMetadata = bookMetadata
            self.error = nil
            self.source = source
        }
        
        init(isbn: String, error: String) {
            self.isbn = isbn
            self.found = false
            self.bookMetadata = nil
            self.error = error
            self.source = nil
        }
    }
    
    private init() {
        #if DEBUG
        print("✅ BookSearchService: Batch-enabled proxy at \(proxyBaseURL)")
        #endif
    }
    
    // MARK: - Batch Lookup Methods
    
    /// High-performance batch ISBN lookup optimized for CSV imports
    func batchLookupISBNs(
        _ isbns: [String], 
        provider: APIProvider = .isbndb,  // Default to ISBNdb for CSV imports
        progressCallback: ((Double) -> Void)? = nil
    ) async -> Result<BatchLookupResult, BookError> {
        
        // Validate input
        guard !isbns.isEmpty else {
            return .success(BatchLookupResult(
                results: [], total: 0, found: 0, cached: 0, fresh: 0,
                provider: provider.rawValue, processingTime: 0, requestId: UUID().uuidString
            ))
        }
        
        guard isbns.count <= BatchConfig.maxBatchSize else {
            return .failure(.proxyError("Batch size exceeds maximum of \(BatchConfig.maxBatchSize)"))
        }
        
        let startTime = Date()
        
        // Clean and validate ISBNs
        let cleanedISBNs = isbns.compactMap { cleanISBN($0) }
        guard !cleanedISBNs.isEmpty else {
            return .failure(.proxyError("No valid ISBNs found in batch"))
        }
        
        // Choose optimal batch strategy
        if provider.supportsBatching && cleanedISBNs.count >= 10 {
            // Use native batch API for large batches
            return await performNativeBatchLookup(
                cleanedISBNs, 
                provider: provider, 
                progressCallback: progressCallback
            )
        } else {
            // Use concurrent individual lookups for small batches or non-batch providers
            return await performConcurrentBatchLookup(
                cleanedISBNs, 
                provider: provider, 
                progressCallback: progressCallback
            )
        }
    }
    
    /// Native batch lookup using CloudFlare Worker batch endpoint
    private func performNativeBatchLookup(
        _ isbns: [String],
        provider: APIProvider,
        progressCallback: ((Double) -> Void)? = nil
    ) async -> Result<BatchLookupResult, BookError> {
        
        guard var components = URLComponents(string: "\(proxyBaseURL)/batch") else {
            return .failure(.invalidURL)
        }
        
        guard let url = components.url else {
            return .failure(.invalidURL)
        }
        
        // Prepare batch request payload
        let batchRequest = BatchRequest(
            isbns: isbns,
            provider: provider == .auto ? nil : provider.rawValue,
            options: BatchRequest.Options(
                includeMetadata: true,
                includePrices: false,
                timeout: 45
            )
        )
        
        do {
            let jsonData = try JSONEncoder().encode(batchRequest)
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("BooksTrack-iOS/1.0", forHTTPHeaderField: "User-Agent")
            request.httpBody = jsonData
            request.timeoutInterval = 60.0
            
            progressCallback?(0.1) // Starting request
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            progressCallback?(0.5) // Request completed
            
            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                guard 200...299 ~= httpResponse.statusCode else {
                    if httpResponse.statusCode == 429 {
                        let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After") ?? "60"
                        return .failure(.proxyError("Batch rate limit exceeded. Retry in \(retryAfter)s"))
                    }
                    return .failure(.networkError("HTTP \(httpResponse.statusCode)"))
                }
            }
            
            let batchResponse = try JSONDecoder().decode(BatchResponse.self, from: data)
            
            progressCallback?(0.9) // Parsing completed
            
            // Handle batch errors
            if let error = batchResponse.error {
                return .failure(.proxyError("Batch lookup failed: \(error)"))
            }
            
            // Transform results
            let lookupResults = batchResponse.results?.map { result in
                if result.found, let data = result.data {
                    let metadata = transformBatchItemToBookMetadata(data, provider: batchResponse.provider)
                    return ISBNLookupResult(isbn: result.isbn, bookMetadata: metadata, source: "api")
                } else {
                    let error = result.error ?? "Not found"
                    return ISBNLookupResult(isbn: result.isbn, error: error)
                }
            } ?? []
            
            progressCallback?(1.0) // Complete
            
            let processingTime = Date().timeIntervalSince(Date(timeIntervalSince1970: startTime.timeIntervalSince1970))
            
            let batchResult = BatchLookupResult(
                results: lookupResults,
                total: batchResponse.total ?? isbns.count,
                found: batchResponse.found ?? lookupResults.filter { $0.found }.count,
                cached: batchResponse.cached ?? 0,
                fresh: batchResponse.fresh ?? lookupResults.filter { $0.found }.count,
                provider: batchResponse.provider ?? provider.rawValue,
                processingTime: processingTime,
                requestId: batchResponse.requestId ?? UUID().uuidString
            )
            
            return .success(batchResult)
            
        } catch {
            return .failure(.decodingError("Batch request failed: \(error.localizedDescription)"))
        }
    }
    
    /// Concurrent individual lookups for smaller batches or non-batch providers
    private func performConcurrentBatchLookup(
        _ isbns: [String],
        provider: APIProvider,
        progressCallback: ((Double) -> Void)? = nil
    ) async -> Result<BatchLookupResult, BookError> {
        
        let startTime = Date()
        var completed = 0
        let total = isbns.count
        
        // Process in chunks to control concurrency
        let chunkSize = min(BatchConfig.maxConcurrentBatches, 10)
        var allResults: [ISBNLookupResult] = []
        
        for chunk in isbns.chunked(into: chunkSize) {
            let chunkResults = await withTaskGroup(of: ISBNLookupResult.self) { group in
                for isbn in chunk {
                    group.addTask {
                        let result = await self.searchByISBN(isbn, provider: provider)
                        
                        switch result {
                        case .success(let metadata):
                            return ISBNLookupResult(isbn: isbn, bookMetadata: metadata, source: "api")
                        case .failure(let error):
                            return ISBNLookupResult(isbn: isbn, error: error.localizedDescription)
                        }
                    }
                }
                
                var results: [ISBNLookupResult] = []
                for await result in group {
                    results.append(result)
                    completed += 1
                    progressCallback?(Double(completed) / Double(total))
                }
                return results
            }
            
            allResults.append(contentsOf: chunkResults)
        }
        
        let processingTime = Date().timeIntervalSince1970 - startTime.timeIntervalSince1970
        let foundCount = allResults.filter { $0.found }.count
        
        let batchResult = BatchLookupResult(
            results: allResults,
            total: total,
            found: foundCount,
            cached: 0, // Individual lookups don't track cache separately
            fresh: foundCount,
            provider: provider.rawValue,
            processingTime: processingTime,
            requestId: UUID().uuidString
        )
        
        return .success(batchResult)
    }
    
    // MARK: - Enhanced Single Lookup with Provider Selection
    
    func searchByISBN(_ isbn: String, provider: APIProvider = .auto) async -> Result<BookMetadata?, BookError> {
        let cleanedISBN = cleanISBN(isbn)
        guard let cleanedISBN = cleanedISBN else {
            return .success(nil)
        }
        
        // Build URL with provider parameter
        guard var components = URLComponents(string: "\(proxyBaseURL)/isbn") else {
            return .failure(.invalidURL)
        }
        
        var queryItems = [URLQueryItem(name: "isbn", value: cleanedISBN)]
        
        if provider != .auto {
            queryItems.append(URLQueryItem(name: "provider", value: provider.rawValue))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            return .failure(.invalidURL)
        }
        
        return await executeProxyRequest(url: url) { data in
            let response = try JSONDecoder().decode(ProxyISBNResponse.self, from: data)
            
            if let error = response.error {
                if error.contains("not found") {
                    return nil
                }
                throw ProxyError.serverError(error)
            }
            
            return response.toBookMetadata()
        }
    }
    
    // MARK: - CSV Import Optimization
    
    /// Optimized batch lookup specifically for CSV imports
    func batchLookupForCSVImport(
        _ csvBooks: [CSVBookData],
        progressCallback: @escaping (ImportBatchProgress) -> Void
    ) async -> [ISBNLookupResult] {
        
        // Extract valid ISBNs from CSV data
        let isbnPairs = csvBooks.compactMap { csvBook -> (String, UUID)? in
            guard let isbn = csvBook.isbn, !isbn.isEmpty else { return nil }
            return (isbn, csvBook.id)
        }
        
        let isbns = isbnPairs.map { $0.0 }
        
        guard !isbns.isEmpty else {
            progressCallback(ImportBatchProgress(current: 0, total: 0, found: 0, errors: 0))
            return []
        }
        
        // Use ISBNdb for CSV imports (best metadata quality)
        let result = await batchLookupISBNs(isbns, provider: .isbndb) { progress in
            let batchProgress = ImportBatchProgress(
                current: Int(progress * Double(isbns.count)),
                total: isbns.count,
                found: 0, // Will be updated after completion
                errors: 0
            )
            progressCallback(batchProgress)
        }
        
        switch result {
        case .success(let batchResult):
            let finalProgress = ImportBatchProgress(
                current: batchResult.total,
                total: batchResult.total,
                found: batchResult.found,
                errors: batchResult.total - batchResult.found
            )
            progressCallback(finalProgress)
            return batchResult.results
            
        case .failure(let error):
            print("❌ CSV batch lookup failed: \(error.localizedDescription)")
            // Fallback to individual lookups
            return await performFallbackCSVLookup(isbns, progressCallback: progressCallback)
        }
    }
    
    /// Fallback for CSV import when batch fails
    private func performFallbackCSVLookup(
        _ isbns: [String],
        progressCallback: @escaping (ImportBatchProgress) -> Void
    ) async -> [ISBNLookupResult] {
        
        var results: [ISBNLookupResult] = []
        var completed = 0
        var found = 0
        
        for isbn in isbns {
            let result = await searchByISBN(isbn, provider: .isbndb)
            
            switch result {
            case .success(let metadata):
                results.append(ISBNLookupResult(isbn: isbn, bookMetadata: metadata, source: "fallback"))
                if metadata != nil { found += 1 }
            case .failure(let error):
                results.append(ISBNLookupResult(isbn: isbn, error: error.localizedDescription))
            }
            
            completed += 1
            let progress = ImportBatchProgress(
                current: completed,
                total: isbns.count,
                found: found,
                errors: completed - found
            )
            progressCallback(progress)
        }
        
        return results
    }
    
    // MARK: - Helper Types
    
    struct ImportBatchProgress {
        let current: Int
        let total: Int
        let found: Int
        let errors: Int
        
        var percentage: Double {
            return total > 0 ? Double(current) / Double(total) : 0.0
        }
        
        var successRate: Double {
            return current > 0 ? Double(found) / Double(current) : 0.0
        }
    }
    
    // MARK: - Private Helpers
    
    private func cleanISBN(_ isbn: String) -> String? {
        let cleaned = isbn
            .replacingOccurrences(of: "=", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleaned.isEmpty else { return nil }
        guard cleaned.count == 10 || cleaned.count == 13 else { return nil }
        guard cleaned.allSatisfy({ $0.isNumber || $0.uppercased() == "X" }) else { return nil }
        
        return cleaned
    }
    
    private func transformBatchItemToBookMetadata(_ data: BatchItemData, provider: String?) -> BookMetadata {
        // Transform the batch item data to BookMetadata
        // This would use the same logic as the existing proxy response transformation
        let isbn13 = data.volumeInfo?.industryIdentifiers?.first(where: { $0.type == "ISBN_13" })?.identifier
        let isbn10 = data.volumeInfo?.industryIdentifiers?.first(where: { $0.type == "ISBN_10" })?.identifier
        
        return BookMetadata(
            googleBooksID: "\(provider ?? "batch"):\(data.id ?? UUID().uuidString)",
            title: data.volumeInfo?.title ?? "",
            authors: data.volumeInfo?.authors ?? [],
            publishedDate: data.volumeInfo?.publishedDate,
            pageCount: data.volumeInfo?.pageCount,
            bookDescription: data.volumeInfo?.description,
            imageURL: data.volumeInfo?.imageLinks?.thumbnail?.replacingHTTPWithHTTPS(),
            language: data.volumeInfo?.language,
            previewLink: URL(string: data.volumeInfo?.previewLink ?? ""),
            infoLink: URL(string: data.volumeInfo?.infoLink ?? ""),
            publisher: data.volumeInfo?.publisher,
            isbn: isbn13 ?? isbn10,
            genre: data.volumeInfo?.categories ?? [],
            dataSource: .proxyAPI,
            fieldDataSources: [:], // Would be populated properly
            dataCompleteness: 0.8,
            dataQualityScore: 1.0
        )
    }
    
    // Keep all existing methods from the original BookSearchService...
    // [Include all the existing search, executeProxyRequest, etc. methods]
}

// MARK: - Batch Request/Response Models

private struct BatchRequest: Codable {
    let isbns: [String]
    let provider: String?
    let options: Options
    
    struct Options: Codable {
        let includeMetadata: Bool
        let includePrices: Bool
        let timeout: Int
    }
}

private struct BatchResponse: Codable {
    let results: [BatchResultItem]?
    let total: Int?
    let found: Int?
    let cached: Int?
    let fresh: Int?
    let provider: String?
    let requestId: String?
    let error: String?
    let partial: Bool?
}

private struct BatchResultItem: Codable {
    let isbn: String
    let found: Bool
    let data: BatchItemData?
    let error: String?
    let source: String?
}

private struct BatchItemData: Codable {
    let kind: String?
    let id: String?
    let volumeInfo: ProxyVolumeInfo?
}

// MARK: - Array Extension for Chunking

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

// Keep all existing ProxyVolumeInfo, ProxyISBNResponse, etc. from the original file...
// [Include all existing response models and helper types]