import Foundation
import SwiftData

@Model
final class BookMetadata: Identifiable, @unchecked Sendable {
    @Attribute(.unique) var googleBooksID: String
    var title: String
    var authors: [String] = [] // Fixed: Non-optional with default
    var publishedDate: String?
    var pageCount: Int?
    var bookDescription: String?
    var imageURL: URL?
    var language: String?
    var previewLink: URL?
    var infoLink: URL?
    var publisher: String?
    var isbn: String?
    var genre: [String] = [] // Fixed: Non-optional with default
    var originalLanguage: String?
    var authorNationality: String?
    var translator: String?
    var format: BookFormat?

    // One-to-many relationship: BookMetadata can have multiple UserBooks
    @Relationship(inverse: \UserBook.metadata)
    var userBooks: [UserBook] = []
    
    @Transient
    var id: String { googleBooksID }

    init(googleBooksID: String, title: String, authors: [String] = [], publishedDate: String? = nil, pageCount: Int? = nil, bookDescription: String? = nil, imageURL: URL? = nil, language: String? = nil, previewLink: URL? = nil, infoLink: URL? = nil, publisher: String? = nil, isbn: String? = nil, genre: [String] = [], originalLanguage: String? = nil, authorNationality: String? = nil, translator: String? = nil, format: BookFormat? = nil) {
        self.googleBooksID = googleBooksID
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.authors = authors.isEmpty ? [] : authors
        self.publishedDate = publishedDate
        self.pageCount = pageCount
        self.bookDescription = bookDescription
        self.imageURL = imageURL
        self.language = language
        self.previewLink = previewLink
        self.infoLink = infoLink
        self.publisher = publisher
        self.isbn = isbn
        self.genre = genre.isEmpty ? [] : genre
        self.originalLanguage = originalLanguage
        self.authorNationality = authorNationality
        self.translator = translator
        self.format = format
    }
    
    // Validation methods (non-fatal for migration safety)
    func validateTitle() -> Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 512
    }
    
    func validateAuthors() -> Bool {
        return !authors.isEmpty && authors.allSatisfy({ 
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.count <= 100 
        })
    }
    
    func validateDescription() -> Bool {
        guard let description = bookDescription else { return true }
        return description.count <= 10000
    }
    
    func validatePageCount() -> Bool {
        guard let pages = pageCount else { return true }
        return pages > 0
    }
    
    func validateGenres() -> Bool {
        return genre.count <= 10 && genre.allSatisfy({ $0.count <= 50 })
    }
}

// Book format enum
enum BookFormat: String, Codable, CaseIterable, Identifiable, Sendable {
    case hardcover = "Hardcover"
    case paperback = "Paperback"
    case ebook = "E-book"
    case audiobook = "Audiobook"
    case magazine = "Magazine"
    case other = "Other"
    
    var id: Self { self }
    
    var icon: String {
        switch self {
        case .hardcover: return "book.closed"
        case .paperback: return "book"
        case .ebook: return "tablet"
        case .audiobook: return "headphones"
        case .magazine: return "magazine"
        case .other: return "questionmark.square"
        }
    }
}