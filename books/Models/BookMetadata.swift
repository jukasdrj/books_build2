import Foundation
import SwiftData

@Model
final class BookMetadata: Identifiable, @unchecked Sendable {
    @Attribute(.unique) var googleBooksID: String
    var title: String
    var authors: [String]
    var publishedDate: String?
    var pageCount: Int?
    var bookDescription: String?
    var imageURL: URL?
    var language: String?
    var previewLink: URL?
    var infoLink: URL?
    var publisher: String?
    var isbn: String?
    var genre: [String]?
    var originalLanguage: String?
    var authorNationality: String?
    var translator: String?

    // One-to-many relationship: BookMetadata can have multiple UserBooks
    @Relationship(inverse: \UserBook.metadata)
    var userBooks: [UserBook] = []
    
    @Transient
    var id: String { googleBooksID }

    init(googleBooksID: String, title: String, authors: [String], publishedDate: String? = nil, pageCount: Int? = nil, bookDescription: String? = nil, imageURL: URL? = nil, language: String? = nil, previewLink: URL? = nil, infoLink: URL? = nil, publisher: String? = nil, isbn: String? = nil, genre: [String]? = nil, originalLanguage: String? = nil, authorNationality: String? = nil, translator: String? = nil) {
        // Validate title
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty && trimmedTitle.count <= 512 else {
            fatalError("Title must be 1-512 characters")
        }
        
        // Validate authors
        guard !authors.isEmpty && authors.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && $0.count <= 100 }) else {
            fatalError("Must have at least 1 author, each max 100 characters")
        }
        
        // Validate optional fields
        if let description = bookDescription, description.count > 10000 {
            fatalError("Book description must be max 10,000 characters")
        }
        
        if let pages = pageCount, pages <= 0 {
            fatalError("Page count must be positive")
        }
        
        if let genres = genre, genres.count > 10 || genres.contains(where: { $0.count > 50 }) {
            fatalError("Max 10 genres, each max 50 characters")
        }
        
        self.googleBooksID = googleBooksID
        self.title = trimmedTitle
        self.authors = authors
        self.publishedDate = publishedDate
        self.pageCount = pageCount
        self.bookDescription = bookDescription
        self.imageURL = imageURL
        self.language = language
        self.previewLink = previewLink
        self.infoLink = infoLink
        self.publisher = publisher
        self.isbn = isbn
        self.genre = genre
        self.originalLanguage = originalLanguage
        self.authorNationality = authorNationality
        self.translator = translator
    }
}