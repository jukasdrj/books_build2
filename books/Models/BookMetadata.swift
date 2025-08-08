import Foundation
import SwiftData
import SwiftUI

@Model
final class BookMetadata: Identifiable, Hashable {
    @Attribute(.unique) var googleBooksID: String
    var title: String
    
    // Store authors as a comma-separated string for SwiftData compatibility
    private var authorsString: String = ""
    
    var publishedDate: String?
    var pageCount: Int?
    var bookDescription: String?
    var imageURL: URL?
    var language: String?
    var previewLink: URL?
    var infoLink: URL?
    var publisher: String?
    var isbn: String?
    
    // Store genres as a comma-separated string for SwiftData compatibility  
    private var genreString: String = ""
    
    var originalLanguage: String?
    var authorNationality: String?
    var translator: String?
    var format: BookFormat?

    // NEW: Enhanced cultural and diversity tracking
    var authorGender: AuthorGender?
    var authorEthnicity: String?
    var culturalRegion: CulturalRegion?
    var originalPublicationCountry: String?
    var translatorNationality: String?
    
    // Store cultural themes as a comma-separated string for SwiftData compatibility
    private var culturalThemesString: String = ""
    
    var indigenousAuthor: Bool = false
    var marginalizedVoice: Bool = false
    
    // NEW: Enhanced reading experience tracking
    var readingDifficulty: ReadingDifficulty?
    var timeToRead: Int? // estimated minutes
    
    // Store content warnings as a comma-separated string for SwiftData compatibility
    private var contentWarningsString: String = ""
    
    // Store awards as a comma-separated string for SwiftData compatibility
    private var awardsString: String = ""
    
    var series: String?
    var seriesNumber: Int?

    // One-to-many relationship: BookMetadata can have multiple UserBooks
    @Relationship(inverse: \UserBook.metadata)
    var userBooks: [UserBook] = []
    
    @Transient
    var id: String { googleBooksID }
    
    // Computed property for authors array
    var authors: [String] {
        get {
            guard !authorsString.isEmpty else { return [] }
            return authorsString.components(separatedBy: "|||").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        }
        set {
            authorsString = newValue.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }.joined(separator: "|||")
        }
    }
    
    // Computed property for genre array
    var genre: [String] {
        get {
            guard !genreString.isEmpty else { return [] }
            return genreString.components(separatedBy: "|||").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        }
        set {
            genreString = newValue.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }.joined(separator: "|||")
        }
    }
    
    // Computed property for cultural themes array
    var culturalThemes: [String] {
        get {
            guard !culturalThemesString.isEmpty else { return [] }
            return culturalThemesString.components(separatedBy: "|||").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        }
        set {
            culturalThemesString = newValue.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }.joined(separator: "|||")
        }
    }
    
    // Computed property for content warnings array
    var contentWarnings: [String] {
        get {
            guard !contentWarningsString.isEmpty else { return [] }
            return contentWarningsString.components(separatedBy: "|||").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        }
        set {
            contentWarningsString = newValue.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }.joined(separator: "|||")
        }
    }
    
    // Computed property for awards array
    var awards: [String] {
        get {
            guard !awardsString.isEmpty else { return [] }
            return awardsString.components(separatedBy: "|||").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        }
        set {
            awardsString = newValue.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }.joined(separator: "|||")
        }
    }

    init(googleBooksID: String, title: String, authors: [String] = [], publishedDate: String? = nil, pageCount: Int? = nil, bookDescription: String? = nil, imageURL: URL? = nil, language: String? = nil, previewLink: URL? = nil, infoLink: URL? = nil, publisher: String? = nil, isbn: String? = nil, genre: [String] = [], originalLanguage: String? = nil, authorNationality: String? = nil, translator: String? = nil, format: BookFormat? = nil, authorGender: AuthorGender? = nil, authorEthnicity: String? = nil, culturalRegion: CulturalRegion? = nil, originalPublicationCountry: String? = nil, translatorNationality: String? = nil, culturalThemes: [String] = [], indigenousAuthor: Bool = false, marginalizedVoice: Bool = false, readingDifficulty: ReadingDifficulty? = nil, timeToRead: Int? = nil, contentWarnings: [String] = [], awards: [String] = [], series: String? = nil, seriesNumber: Int? = nil) {
        self.googleBooksID = googleBooksID
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.publishedDate = publishedDate
        self.pageCount = pageCount
        self.bookDescription = bookDescription
        self.imageURL = imageURL
        self.language = language
        self.previewLink = previewLink
        self.infoLink = infoLink
        self.publisher = publisher
        self.isbn = isbn
        self.originalLanguage = originalLanguage
        self.authorNationality = authorNationality
        self.translator = translator
        self.format = format
        self.authorGender = authorGender
        self.authorEthnicity = authorEthnicity
        self.culturalRegion = culturalRegion
        self.originalPublicationCountry = originalPublicationCountry
        self.translatorNationality = translatorNationality
        self.indigenousAuthor = indigenousAuthor
        self.marginalizedVoice = marginalizedVoice
        self.readingDifficulty = readingDifficulty
        self.timeToRead = timeToRead
        self.series = series
        self.seriesNumber = seriesNumber
        
        // Set the computed properties which will update the private strings
        self.authors = authors
        self.genre = genre
        self.culturalThemes = culturalThemes
        self.contentWarnings = contentWarnings
        self.awards = awards
    }
    
    // MARK: - Hashable Conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(googleBooksID)
    }
    
    static func == (lhs: BookMetadata, rhs: BookMetadata) -> Bool {
        return lhs.googleBooksID == rhs.googleBooksID
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

// Book format enum - Simplified to 3 essential formats
enum BookFormat: String, Codable, CaseIterable, Identifiable, Sendable {
    case physical = "Physical"
    case ebook = "E-book"
    case audiobook = "Audiobook"
    
    var id: Self { self }
    
    var icon: String {
        switch self {
        case .physical: return "book.closed"
        case .ebook: return "ipad"
        case .audiobook: return "headphones"
        }
    }
}

// NEW: Enhanced enums for cultural diversity tracking

enum AuthorGender: String, Codable, CaseIterable, Identifiable, Sendable {
    case female = "Female"
    case male = "Male"
    case nonBinary = "Non-binary"
    case other = "Other"
    case unknown = "Unknown"
    
    var id: Self { self }
    
    var icon: String {
        switch self {
        case .female: return "person.crop.circle.fill"
        case .male: return "person.crop.circle"
        case .nonBinary: return "person.crop.circle.badge.questionmark"
        case .other: return "person.crop.circle.badge.plus"
        case .unknown: return "questionmark.circle"
        }
    }
}

enum CulturalRegion: String, Codable, CaseIterable, Identifiable, Sendable {
    case africa = "Africa"
    case asia = "Asia"
    case europe = "Europe"
    case northAmerica = "North America"
    case southAmerica = "South America"
    case oceania = "Oceania"
    case middleEast = "Middle East"
    case caribbean = "Caribbean"
    case centralAsia = "Central Asia"
    case indigenous = "Indigenous"
    
    var id: Self { self }
    
    var color: Color {
        switch self {
        case .africa: return Color.theme.cultureAfrica
        case .asia: return Color.theme.cultureAsia
        case .europe: return Color.theme.cultureEurope
        case .northAmerica, .southAmerica: return Color.theme.cultureAmericas
        case .oceania: return Color.theme.cultureOceania
        case .middleEast, .centralAsia: return Color.theme.cultureMiddleEast
        case .caribbean: return Color.theme.cultureAmericas
        case .indigenous: return Color.theme.cultureIndigenous
        }
    }
    
    var icon: String {
        switch self {
        case .africa: return "globe.africa.fill"
        case .asia: return "globe.asia.australia.fill"
        case .europe: return "globe.europe.africa.fill"
        case .northAmerica, .southAmerica: return "globe.americas.fill"
        case .oceania: return "globe.asia.australia.fill"
        case .middleEast, .centralAsia: return "globe.europe.africa.fill"
        case .caribbean: return "globe.americas.fill"
        case .indigenous: return "leaf.fill"
        }
    }
}

enum ReadingDifficulty: String, Codable, CaseIterable, Identifiable, Sendable {
    case easy = "Easy"
    case moderate = "Moderate"
    case challenging = "Challenging"
    case advanced = "Advanced"
    
    var id: Self { self }
    
    var color: Color {
        switch self {
        case .easy: return Color.theme.success
        case .moderate: return Color.theme.warning
        case .challenging: return Color.theme.error
        case .advanced: return Color.theme.primary
        }
    }
    
    var icon: String {
        switch self {
        case .easy: return "1.circle.fill"
        case .moderate: return "2.circle.fill"
        case .challenging: return "3.circle.fill"
        case .advanced: return "4.circle.fill"
        }
    }
}