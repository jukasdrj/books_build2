import Foundation
import SwiftData
import SwiftUI

@Model
final class BookMetadata: Identifiable, Hashable {
    // FIXED: Removed .unique constraint for CloudKit compatibility
    // Note: You'll need to handle duplicates manually in your business logic
    var googleBooksID: String = ""
    var title: String = "" {
        didSet {
            // Prevent nil assignment - SwiftData sometimes passes nil during loading
            if title.isEmpty {
                title = "Unknown Title"
            }
        }
    }
    
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
    var format: BookFormat?

    // NEW: Enhanced cultural and diversity tracking
    var authorGender: AuthorGender?
    var authorEthnicity: String?
    var culturalRegion: CulturalRegion?
    var originalPublicationCountry: String?
    var translatorNationality: String?
    
    // Store cultural themes as a comma-separated string for SwiftData compatibility
    private var culturalThemesString: String = ""
    
    // NEW: Enhanced reading experience tracking
    var readingDifficulty: ReadingDifficulty?
    var timeToRead: Int? // estimated minutes
    
    // MARK: - Data Source Tracking (Phase 3)
    
    // Primary data source for the entire book record - handle existing nil values
    private var _dataSource: DataSource? = DataSource.manualEntry
    
    var dataSource: DataSource {
        get {
            return _dataSource ?? .manualEntry
        }
        set {
            _dataSource = newValue
        }
    }
    
    // Field-level tracking for mixed-source books (stored as JSON string for SwiftData compatibility)
    private var fieldDataSourcesString: String = "{}"
    
    // Overall data quality metrics
    var dataCompleteness: Double = 0.0 // 0.0-1.0
    var lastDataUpdate: Date = Date()
    var dataQualityScore: Double = 1.0 // Enhanced from existing field
    

    // MARK: - Relationships
    
    // One-to-many relationship: BookMetadata can have multiple UserBooks
    @Relationship(inverse: \UserBook.metadata)
    var userBooks: [UserBook] = []
    
    // Many-to-many relationship: BookMetadata can have multiple AuthorProfiles
    @Relationship()
    var authorProfiles: [AuthorProfile] = []
    
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
    
    // Use @Transient to exclude this computed property from SwiftData persistence
    @Transient
    var fieldDataSources: [String: DataSourceInfo] {
        get {
            guard !fieldDataSourcesString.isEmpty, fieldDataSourcesString != "{}" else { return [:] }
            guard let data = fieldDataSourcesString.data(using: .utf8) else { return [:] }
            do {
                return try JSONDecoder().decode([String: DataSourceInfo].self, from: data)
            } catch {
                return [:]
            }
        }
        set {
            do {
                let data = try JSONEncoder().encode(newValue)
                fieldDataSourcesString = String(data: data, encoding: .utf8) ?? "{}"
            } catch {
                fieldDataSourcesString = "{}"
            }
        }
    }
    

    init(googleBooksID: String, title: String, authors: [String] = [], publishedDate: String? = nil, pageCount: Int? = nil, bookDescription: String? = nil, imageURL: URL? = nil, language: String? = nil, previewLink: URL? = nil, infoLink: URL? = nil, publisher: String? = nil, isbn: String? = nil, genre: [String] = [], originalLanguage: String? = nil, authorNationality: String? = nil, format: BookFormat? = nil, authorGender: AuthorGender? = nil, authorEthnicity: String? = nil, culturalRegion: CulturalRegion? = nil, originalPublicationCountry: String? = nil, translatorNationality: String? = nil, culturalThemes: [String] = [], readingDifficulty: ReadingDifficulty? = nil, timeToRead: Int? = nil, dataSource: DataSource = DataSource.manualEntry, fieldDataSources: [String: DataSourceInfo] = [:], dataCompleteness: Double = 0.0, dataQualityScore: Double = 1.0) {
        // Ensure non-nil values for required properties
        self.googleBooksID = googleBooksID.isEmpty ? "unknown_\(UUID().uuidString)" : googleBooksID
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Unknown Title" : title.trimmingCharacters(in: .whitespacesAndNewlines)
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
        self.format = format
        self.authorGender = authorGender
        self.authorEthnicity = authorEthnicity
        self.culturalRegion = culturalRegion
        self.originalPublicationCountry = originalPublicationCountry
        self.translatorNationality = translatorNationality
        self.readingDifficulty = readingDifficulty
        self.timeToRead = timeToRead
        self._dataSource = dataSource
        self.dataCompleteness = dataCompleteness
        self.dataQualityScore = dataQualityScore
        self.lastDataUpdate = Date()
        
        // Set the computed properties which will update the private strings
        self.authors = authors
        self.genre = genre
        self.culturalThemes = culturalThemes
        self.fieldDataSources = fieldDataSources
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
    
    // MARK: - Replacement Methods for Deprecated Fields
    
    /// Returns true if this work represents an indigenous voice
    /// Uses enhanced cultural tracking instead of deprecated indigenousAuthor field
    func hasIndigenousVoice() -> Bool {
        // Check if the cultural region indicates indigenous authorship
        if culturalRegion == .indigenous {
            return true
        }
        
        // Check author ethnicity for indigenous indicators
        if let ethnicity = authorEthnicity?.lowercased() {
            let indigenousKeywords = ["indigenous", "native", "aboriginal", "first nations", "inuit", "maori", "aboriginal"]
            return indigenousKeywords.contains { ethnicity.contains($0) }
        }
        
        return false
    }
    
    /// Returns true if this work represents a marginalized voice
    /// Uses enhanced cultural tracking instead of deprecated marginalizedVoice field
    func hasMarginalizedVoice() -> Bool {
        // Check various indicators of marginalized voices
        if hasIndigenousVoice() {
            return true
        }
        
        // Check for underrepresented cultural regions
        let marginalizedRegions: [CulturalRegion] = [.africa, .indigenous, .middleEast]
        if let region = culturalRegion, marginalizedRegions.contains(region) {
            return true
        }
        
        // Check author gender diversity
        if let gender = authorGender, gender != .male && gender != .unknown {
            return true
        }
        
        // Check if work is translated (often underrepresented)
        if originalLanguage != nil && originalLanguage?.lowercased() != "english" {
            return true
        }
        
        return false
    }
    
    /// Returns true if this book has notable achievements
    /// Provides functionality previously handled by awards field
    func hasNotableRecognition() -> Bool {
        // Check for recognition indicators in title or description
        let title = self.title.lowercased()
        let description = self.bookDescription?.lowercased() ?? ""
        
        let recognitionKeywords = ["winner", "award", "prize", "bestseller", "nominated", "finalist", "pulitzer", "nobel", "hugo", "nebula", "booker"]
        
        return recognitionKeywords.contains { keyword in
            title.contains(keyword) || description.contains(keyword)
        }
    }
    
    /// Returns series information as a formatted string
    /// Provides functionality previously handled by separate series fields
    func getSeriesInfo() -> String? {
        // Try to extract series information from title
        let title = self.title
        
        // Look for patterns like "Book Name (Series #3)" or "Book Name: Series Book 3"
        let seriesPatterns = [
            #"\(([^)]+)\s*#?(\d+)\)"#,  // (Series Name #3)
            #":\s*([^:]+)\s+Book\s+(\d+)"#,  // : Series Book 3
            #":\s*([^:]+)\s+(\d+)"#,  // : Series 3
            #"-\s*([^-]+)\s+(\d+)$"#   // - Series 3
        ]
        
        for pattern in seriesPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
               let match = regex.firstMatch(in: title, range: NSRange(title.startIndex..., in: title)),
               let seriesRange = Range(match.range(at: 1), in: title),
               let numberRange = Range(match.range(at: 2), in: title) {
                let seriesName = String(title[seriesRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                let number = String(title[numberRange])
                return "\(seriesName) #\(number)"
            }
        }
        
        return nil
    }
    
    // MARK: - AuthorProfile Integration Methods
    
    /// Get all author names from both legacy authors string and AuthorProfile relationships
    func getAllAuthorNames() -> [String] {
        var allNames = authors // Legacy string-based authors
        
        // Add names from AuthorProfile relationships
        let profileNames = authorProfiles.map { $0.name }
        allNames.append(contentsOf: profileNames)
        
        // Remove duplicates and empty names
        return Array(Set(allNames.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }))
    }
    
    /// Get primary cultural metadata from AuthorProfiles
    func getPrimaryCulturalData() -> (regions: [CulturalRegion], genders: [AuthorGender], themes: [String]) {
        let regions = Set(authorProfiles.compactMap { $0.culturalRegion })
        let genders = Set(authorProfiles.map { $0.gender }).filter { $0 != .unknown }
        let themes = Set(authorProfiles.flatMap { $0.culturalThemes })
        
        return (
            regions: Array(regions),
            genders: Array(genders),
            themes: Array(themes)
        )
    }
    
    /// Check if any author represents indigenous voices
    func hasIndigenousAuthorVoices() -> Bool {
        return authorProfiles.contains { $0.representsIndigenousVoices() }
    }
    
    /// Check if any author represents marginalized voices
    func hasMarginalizedAuthorVoices() -> Bool {
        return authorProfiles.contains { $0.representsMarginalizedVoices() }
    }
    
    /// Get the highest cultural data confidence from all authors
    func getHighestCulturalConfidence() -> Double {
        return authorProfiles.map { $0.culturalDataConfidence }.max() ?? 0.0
    }
    
    /// Associate an AuthorProfile with this book
    func addAuthorProfile(_ profile: AuthorProfile) {
        if !authorProfiles.contains(profile) {
            authorProfiles.append(profile)
            
            // Update author profile's book count and statistics
            profile.bookCount += 1
            profile.dateLastModified = Date()
        }
    }
    
    /// Remove an AuthorProfile association from this book
    func removeAuthorProfile(_ profile: AuthorProfile) {
        if let index = authorProfiles.firstIndex(of: profile) {
            authorProfiles.remove(at: index)
            
            // Update author profile's book count
            profile.bookCount = max(0, profile.bookCount - 1)
            profile.dateLastModified = Date()
        }
    }
    
    /// Migration helper: Create AuthorProfile entities from legacy string-based authors
    func migrateToAuthorProfiles() -> [AuthorProfile] {
        var createdProfiles: [AuthorProfile] = []
        
        for authorName in authors {
            // Check if we already have a profile for this author
            let existingProfile = authorProfiles.first { $0.matches(authorName) }
            
            if existingProfile == nil {
                // Create new AuthorProfile
                let profile = AuthorProfile(
                    name: authorName,
                    culturalDataConfidence: 0.3, // Low confidence for migrated data
                    culturalDataSources: [
                        "migration": DataSourceInfo(source: .mixedSources, confidence: 0.3, fieldPath: "migration")
                    ]
                )
                
                // Try to infer cultural data from existing BookMetadata fields
                if let gender = authorGender {
                    profile.gender = gender
                }
                
                if let nationality = authorNationality {
                    profile.nationality = nationality
                }
                
                if let region = culturalRegion {
                    profile.culturalRegion = region
                }
                
                // Add cultural themes from book
                profile.culturalThemes = culturalThemes
                
                createdProfiles.append(profile)
                addAuthorProfile(profile)
            }
        }
        
        return createdProfiles
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
    case antarctica = "Antarctica"
    case international = "International"
    
    var id: Self { self }
    
    func color(theme: AppColorTheme) -> Color {
        switch self {
        case .africa: return theme.cultureAfrica
        case .asia: return theme.cultureAsia
        case .europe: return theme.cultureEurope
        case .northAmerica, .southAmerica: return theme.cultureAmericas
        case .oceania: return theme.cultureOceania
        case .middleEast, .centralAsia: return theme.cultureMiddleEast
        case .caribbean: return theme.cultureAmericas
        case .indigenous: return theme.cultureIndigenous
        case .antarctica: return theme.primary.opacity(0.7)
        case .international: return theme.secondary.opacity(0.8)
        }
    }
    
    // MARK: - Additional Properties for LiquidGlass Compatibility
    
    var emoji: String {
        switch self {
        case .africa: return "🌍"
        case .asia: return "🌏"
        case .europe: return "🌍"
        case .northAmerica: return "🌎"
        case .southAmerica: return "🌎"
        case .oceania: return "🏝️"
        case .middleEast: return "🕌"
        case .caribbean: return "🏖️"
        case .centralAsia: return "🏔️"
        case .indigenous: return "🪶"
        case .antarctica: return "🧊"
        case .international: return "🌐"
        }
    }
    
    
    var shortName: String {
        switch self {
        case .africa: return "Africa"
        case .asia: return "Asia"
        case .europe: return "Europe"
        case .northAmerica: return "N. America"
        case .southAmerica: return "S. America"
        case .oceania: return "Oceania"
        case .middleEast: return "Middle East"
        case .caribbean: return "Caribbean"
        case .centralAsia: return "C. Asia"
        case .indigenous: return "Indigenous"
        case .antarctica: return "Antarctica"
        case .international: return "Global"
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
        case .antarctica: return "snow"
        case .international: return "globe"
        }
    }
}

enum ReadingDifficulty: String, Codable, CaseIterable, Identifiable, Sendable {
    case easy = "Easy"
    case moderate = "Moderate"
    case challenging = "Challenging"
    case advanced = "Advanced"
    
    var id: Self { self }
    
    func color(theme: AppColorTheme) -> Color {
        switch self {
        case .easy: return theme.success
        case .moderate: return theme.warning
        case .challenging: return theme.error
        case .advanced: return theme.primary
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

// MARK: - Data Source Tracking Types

enum DataSource: String, Codable, CaseIterable, Sendable {
    case googleBooksAPI = "google_books_api"
    case csvImport = "csv_import"
    case manualEntry = "manual_entry"
    case mixedSources = "mixed_sources"
    case userInput = "user_input"
}

struct DataSourceInfo: Codable, Sendable {
    let source: DataSource
    let timestamp: Date
    let confidence: Double // 0.0-1.0 (API=1.0, CSV=0.7, manual=0.9)
    let fieldPath: String? // e.g., "title", "authors[0]", "userRating"
    
    init(source: DataSource, timestamp: Date = Date(), confidence: Double, fieldPath: String? = nil) {
        self.source = source
        self.timestamp = timestamp
        self.confidence = confidence
        self.fieldPath = fieldPath
    }
}

// MARK: - Sendable Conformance
extension BookMetadata: @unchecked Sendable {}