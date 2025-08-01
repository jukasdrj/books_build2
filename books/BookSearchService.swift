// books-buildout-main/books/BookSearchService.swift
import Foundation

@MainActor
class BookSearchService: ObservableObject {
    static let shared = BookSearchService()
    private init() {}

    private let baseURL = "https://www.googleapis.com/books/v1/volumes"
    
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

    func search(query: String) async -> Result<[BookMetadata], BookError> {
        // Handle empty or whitespace-only queries
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return .success([]) // Return empty results for empty queries
        }
        
        guard var components = URLComponents(string: baseURL) else {
            return .failure(.invalidURL)
        }
        // Increase max results to get a better selection
        components.queryItems = [
            URLQueryItem(name: "q", value: trimmedQuery),
            URLQueryItem(name: "maxResults", value: "20")
        ]

        guard let url = components.url else {
            return .failure(.invalidURL)
        }

        do {
            // Create URL session with better configuration
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 10.0
            configuration.timeoutIntervalForResource = 30.0
            let session = URLSession(configuration: configuration)
            
            let (data, _) = try await session.data(from: url)
            let searchResponse = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
            
            let metadataItems = searchResponse.items?.compactMap { $0.toBookMetadata() } ?? []
            return .success(metadataItems)
        } catch let error as URLError {
            return .failure(.networkError(error.localizedDescription))
        } catch {
            return .failure(.decodingError(error.localizedDescription))
        }
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
            authors: volumeInfo.authors ?? [], // Fixed: Empty array instead of ["Unknown Author"]
            publishedDate: volumeInfo.publishedDate,
            pageCount: volumeInfo.pageCount,
            bookDescription: volumeInfo.description,
            imageURL: volumeInfo.imageLinks?.thumbnail?.replacingHTTPWithHTTPS(),
            language: volumeInfo.language,
            previewLink: URL(string: volumeInfo.previewLink ?? ""),
            infoLink: URL(string: volumeInfo.infoLink ?? ""),
            publisher: volumeInfo.publisher,
            isbn: isbn13 ?? isbn10,
            genre: volumeInfo.categories ?? [] // Fixed: Empty array instead of nil
            // Note: originalLanguage, authorNationality, and translator are left nil
            // as they are not provided by this API and require manual entry.
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