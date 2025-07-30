import Foundation
import SwiftData

@Model
final class BookMetadata: Identifiable {
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

    // Plain reference; `UserBook` owns the relationship via its `metadata` property
    var userBook: UserBook?
    
    @Transient
    var id: String { googleBooksID }

    init(googleBooksID: String, title: String, authors: [String], publishedDate: String? = nil, pageCount: Int? = nil, bookDescription: String? = nil, imageURL: URL? = nil, language: String? = nil, previewLink: URL? = nil, infoLink: URL? = nil, publisher: String? = nil, isbn: String? = nil, genre: [String]? = nil, originalLanguage: String? = nil, authorNationality: String? = nil, translator: String? = nil) {
        self.googleBooksID = googleBooksID
        self.title = title
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