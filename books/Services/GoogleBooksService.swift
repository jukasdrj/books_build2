import Foundation
import Combine

final class GoogleBooksService: @unchecked Sendable {
    static let shared = GoogleBooksService()
    private let diagnostics = GoogleBooksDiagnostics.shared

    private init() {}

    // Search Google Books and return BookMetadata models
    func searchBooks(query: String) -> AnyPublisher<[BookMetadata], GoogleBooksError> {
        // Empty queries -> empty results quickly
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return Just([])
                .setFailureType(to: GoogleBooksError.self)
                .eraseToAnyPublisher()
        }

        guard let apiKey = KeychainService.shared.loadAPIKey(), !apiKey.isEmpty else {
            diagnostics.logError(requestId: UUID(),
                                 error: GoogleBooksError.apiKeyMissing,
                                 context: "searchBooks")
            return Fail(error: GoogleBooksError.apiKeyMissing)
                .eraseToAnyPublisher()
        }

        guard let url = buildSearchURL(query: trimmed, apiKey: apiKey) else {
            return Fail(error: GoogleBooksError.invalidRequest("Invalid URL"))
                .eraseToAnyPublisher()
        }

        let requestId = diagnostics.logRequest(
            endpoint: url.absoluteString,
            parameters: ["query": trimmed, "maxResults": 40]
        )

        let startTime = Date()

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 20.0
        configuration.timeoutIntervalForResource = 40.0
        configuration.waitsForConnectivity = true
        let session = URLSession(configuration: configuration)

        return session.dataTaskPublisher(for: url)
            .handleEvents(
                receiveOutput: { output in
                    let responseTime = Date().timeIntervalSince(startTime)
                    self.diagnostics.logResponse(
                        requestId: requestId,
                        statusCode: (output.response as? HTTPURLResponse)?.statusCode ?? 0,
                        responseTime: responseTime,
                        dataSize: output.data.count
                    )
                },
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        self.diagnostics.logError(
                            requestId: requestId,
                            error: error,
                            context: "Network request failed"
                        )
                    }
                }
            )
            .tryMap { output -> Data in
                guard let httpResponse = output.response as? HTTPURLResponse else {
                    throw GoogleBooksError.unknownError
                }

                switch httpResponse.statusCode {
                case 200:
                    return output.data
                case 400:
                    throw GoogleBooksError.invalidRequest("Bad request")
                case 401:
                    throw GoogleBooksError.invalidAPIKey
                case 403:
                    throw GoogleBooksError.quotaExceeded
                case 429:
                    let retryAfter = httpResponse.value(forHTTPHeaderField: "Retry-After")
                        .flatMap { Double($0) }
                    throw GoogleBooksError.rateLimitExceeded(retryAfter: retryAfter)
                case 500...599:
                    throw GoogleBooksError.httpError(
                        statusCode: httpResponse.statusCode,
                        message: "Server error"
                    )
                default:
                    throw GoogleBooksError.httpError(
                        statusCode: httpResponse.statusCode,
                        message: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                    )
                }
            }
            .decode(type: GoogleBooksResponse.self, decoder: JSONDecoder())
            .map { response in
                (response.items ?? []).map { $0.toBookMetadata() }
            }
            .mapError { error in
                if let googleError = error as? GoogleBooksError {
                    return googleError
                } else if error is DecodingError {
                    return GoogleBooksError.decodingError(error)
                } else {
                    return GoogleBooksError.networkError(error)
                }
            }
            .eraseToAnyPublisher()
    }

    private func buildSearchURL(query: String, apiKey: String) -> URL? {
        var components = URLComponents(string: "https://www.googleapis.com/books/v1/volumes")
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "maxResults", value: "40"),
            URLQueryItem(name: "printType", value: "books"),
            URLQueryItem(name: "projection", value: "full")
        ]
        return components?.url
    }
}

// MARK: - Response Models for Decoding

private struct GoogleBooksResponse: Codable {
    let items: [VolumeItem]?
}

private struct VolumeItem: Codable {
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

private struct VolumeInfo: Codable {
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

private struct IndustryIdentifier: Codable {
    let type: String
    let identifier: String
}

private struct ImageLinks: Codable {
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

