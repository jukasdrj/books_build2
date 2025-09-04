import Foundation
import SwiftData
import SwiftUI

@Model
final class AuthorProfile: Identifiable, Hashable {
    /// Unique identifier for the author - combines normalized name with additional identifiers
    var id: String = ""
    
    /// Primary display name for the author
    var name: String = "" {
        didSet {
            // Ensure non-empty name
            if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                name = "Unknown Author"
            }
            // Update normalized name when name changes
            normalizedName = normalizeAuthorName(name)
        }
    }
    
    /// Normalized name for matching and deduplication
    var normalizedName: String = ""
    
    /// Store aliases as a string for SwiftData compatibility
    private var aliasesString: String = ""
    
    // MARK: - API Identifiers from Multiple Sources
    
    /// ISBNdb author ID (if available)
    var isbndbID: String?
    
    /// Open Library author key (if available)
    var openLibraryKey: String?
    
    /// Store Google Books name variations as a string for SwiftData compatibility
    private var googleBooksNamesString: String = ""
    
    /// Standard identifiers when available
    var orcidID: String? // Open Researcher and Contributor ID
    var isniID: String? // International Standard Name Identifier
    var viafID: String? // Virtual International Authority File
    
    // MARK: - Cultural Diversity Data (Centralized)
    
    var gender: AuthorGender = AuthorGender.unknown
    var nationality: String?
    var ethnicity: String?
    var culturalRegion: CulturalRegion?
    var birthYear: Int?
    var deathYear: Int?
    
    /// Store cultural regions as a string for SwiftData compatibility (author may represent multiple regions)
    private var culturalRegionsString: String = ""
    
    /// Store languages the author writes in as a string for SwiftData compatibility
    private var languagesString: String = ""
    
    /// Store cultural themes associated with this author's works as a string for SwiftData compatibility
    private var culturalThemesString: String = ""
    
    // MARK: - Data Quality Tracking
    
    /// Overall confidence in the cultural data (0.0-1.0)
    var culturalDataConfidence: Double = 0.0
    
    /// Verification status of cultural information
    var culturalDataVerified: Bool = false
    
    /// Date when cultural data was last updated
    var culturalDataLastUpdate: Date = Date()
    
    /// Source of cultural data (stored as JSON string for SwiftData compatibility)
    private var culturalDataSourcesString: String = "{}"
    
    // MARK: - Author Statistics and Metadata
    
    /// Total number of books by this author in the user's library
    var bookCount: Int = 0
    
    /// Average rating across all user's books by this author
    var averageRating: Double = 0.0
    
    /// User's engagement level with this author (0.0-1.0)
    var userEngagementScore: Double = 0.0
    
    /// Popularity weight for search optimization (higher = more popular)
    var searchWeight: Double = 1.0
    
    /// Whether this is a frequent author in user's reading
    var isFrequentlyRead: Bool = false
    
    // MARK: - Timestamps
    
    var dateCreated: Date = Date()
    var dateLastModified: Date = Date()
    
    // MARK: - Relationships
    
    /// Many-to-many relationship with BookMetadata
    @Relationship(inverse: \BookMetadata.authorProfiles)
    var books: [BookMetadata] = []
    
    // MARK: - Computed Properties
    
    @Transient
    var hashID: String {
        // Create a stable ID for the author based on normalized name and identifiers
        return id.isEmpty ? generateAuthorID() : id
    }
    
    /// Aliases and name variations
    var aliases: [String] {
        get {
            guard !aliasesString.isEmpty else { return [] }
            return aliasesString.components(separatedBy: "|||")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        set {
            aliasesString = newValue
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: "|||")
        }
    }
    
    /// Google Books name variations
    var googleBooksNames: [String] {
        get {
            guard !googleBooksNamesString.isEmpty else { return [] }
            return googleBooksNamesString.components(separatedBy: "|||")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        set {
            googleBooksNamesString = newValue
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: "|||")
        }
    }
    
    /// Cultural regions (author may represent multiple)
    var culturalRegions: [CulturalRegion] {
        get {
            guard !culturalRegionsString.isEmpty else { return [] }
            return culturalRegionsString.components(separatedBy: "|||")
                .compactMap { CulturalRegion(rawValue: $0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        }
        set {
            culturalRegionsString = newValue.map { $0.rawValue }.joined(separator: "|||")
        }
    }
    
    /// Languages the author writes in
    var languages: [String] {
        get {
            guard !languagesString.isEmpty else { return [] }
            return languagesString.components(separatedBy: "|||")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        set {
            languagesString = newValue
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: "|||")
        }
    }
    
    /// Cultural themes associated with author's works
    var culturalThemes: [String] {
        get {
            guard !culturalThemesString.isEmpty else { return [] }
            return culturalThemesString.components(separatedBy: "|||")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
        set {
            culturalThemesString = newValue
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: "|||")
        }
    }
    
    /// Cultural data sources tracking
    @Transient
    var culturalDataSources: [String: DataSourceInfo] {
        get {
            guard !culturalDataSourcesString.isEmpty, culturalDataSourcesString != "{}" else { return [:] }
            guard let data = culturalDataSourcesString.data(using: .utf8) else { return [:] }
            do {
                return try JSONDecoder().decode([String: DataSourceInfo].self, from: data)
            } catch {
                return [:]
            }
        }
        set {
            do {
                let data = try JSONEncoder().encode(newValue)
                culturalDataSourcesString = String(data: data, encoding: .utf8) ?? "{}"
            } catch {
                culturalDataSourcesString = "{}"
            }
            dateLastModified = Date()
        }
    }
    
    // MARK: - Initialization
    
    init(
        name: String,
        aliases: [String] = [],
        isbndbID: String? = nil,
        openLibraryKey: String? = nil,
        googleBooksNames: [String] = [],
        orcidID: String? = nil,
        isniID: String? = nil,
        viafID: String? = nil,
        gender: AuthorGender = AuthorGender.unknown,
        nationality: String? = nil,
        ethnicity: String? = nil,
        culturalRegion: CulturalRegion? = nil,
        culturalRegions: [CulturalRegion] = [],
        birthYear: Int? = nil,
        deathYear: Int? = nil,
        languages: [String] = [],
        culturalThemes: [String] = [],
        culturalDataConfidence: Double = 0.0,
        culturalDataSources: [String: DataSourceInfo] = [:]
    ) {
        // Ensure non-empty name
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Unknown Author" : name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.normalizedName = normalizeAuthorName(self.name)
        self.id = generateAuthorID()
        
        self.isbndbID = isbndbID
        self.openLibraryKey = openLibraryKey
        self.orcidID = orcidID
        self.isniID = isniID
        self.viafID = viafID
        self.gender = gender
        self.nationality = nationality
        self.ethnicity = ethnicity
        self.culturalRegion = culturalRegion
        self.birthYear = birthYear
        self.deathYear = deathYear
        self.culturalDataConfidence = culturalDataConfidence
        
        self.dateCreated = Date()
        self.dateLastModified = Date()
        
        // Set computed properties
        self.aliases = aliases
        self.googleBooksNames = googleBooksNames
        self.culturalRegions = culturalRegions.isEmpty && culturalRegion != nil ? [culturalRegion!] : culturalRegions
        self.languages = languages
        self.culturalThemes = culturalThemes
        self.culturalDataSources = culturalDataSources
    }
    
    // MARK: - Author Name Normalization
    
    /// Normalize author name for matching and deduplication
    private func normalizeAuthorName(_ name: String) -> String {
        let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Handle common name formats: "Last, First" -> "First Last"
        if cleaned.contains(",") {
            let parts = cleaned.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count >= 2 && !parts[0].isEmpty && !parts[1].isEmpty {
                return "\(parts[1]) \(parts[0])"
            }
        }
        
        return cleaned
    }
    
    /// Generate a stable author ID based on normalized name and identifiers
    private func generateAuthorID() -> String {
        var components: [String] = []
        
        // Use external IDs if available for maximum stability
        if let isbndbID = isbndbID, !isbndbID.isEmpty {
            components.append("isbndb:\(isbndbID)")
        }
        if let openLibraryKey = openLibraryKey, !openLibraryKey.isEmpty {
            components.append("ol:\(openLibraryKey)")
        }
        if let orcidID = orcidID, !orcidID.isEmpty {
            components.append("orcid:\(orcidID)")
        }
        
        // Fall back to normalized name
        if components.isEmpty {
            components.append("name:\(normalizedName)")
        }
        
        // Create hash for consistent length
        let combinedString = components.joined(separator: "|")
        let hash = abs(combinedString.hashValue)
        return "author_\(hash)"
    }
    
    // MARK: - Author Matching Methods
    
    /// Check if this author matches another name or alias
    func matches(_ otherName: String) -> Bool {
        let otherNormalized = normalizeAuthorName(otherName)
        
        // Direct normalized name match
        if normalizedName == otherNormalized {
            return true
        }
        
        // Check aliases
        let normalizedAliases = aliases.map { normalizeAuthorName($0) }
        if normalizedAliases.contains(otherNormalized) {
            return true
        }
        
        // Check Google Books name variations
        let normalizedGoogleNames = googleBooksNames.map { normalizeAuthorName($0) }
        if normalizedGoogleNames.contains(otherNormalized) {
            return true
        }
        
        // Fuzzy matching for similar names (basic version)
        return similarityScore(to: otherNormalized) > 0.85
    }
    
    /// Calculate similarity score between normalized names (0.0-1.0)
    private func similarityScore(to otherName: String) -> Double {
        let thisName = normalizedName
        let maxLength = max(thisName.count, otherName.count)
        guard maxLength > 0 else { return 0.0 }
        
        let distance = levenshteinDistance(thisName, otherName)
        return 1.0 - (Double(distance) / Double(maxLength))
    }
    
    /// Calculate Levenshtein distance between two strings
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)
        var distances = Array(repeating: Array(repeating: 0, count: s2Array.count + 1), count: s1Array.count + 1)
        
        for i in 0...s1Array.count {
            distances[i][0] = i
        }
        for j in 0...s2Array.count {
            distances[0][j] = j
        }
        
        for i in 1...s1Array.count {
            for j in 1...s2Array.count {
                let cost = s1Array[i - 1] == s2Array[j - 1] ? 0 : 1
                distances[i][j] = min(
                    distances[i - 1][j] + 1,      // deletion
                    distances[i][j - 1] + 1,      // insertion
                    distances[i - 1][j - 1] + cost // substitution
                )
            }
        }
        
        return distances[s1Array.count][s2Array.count]
    }
    
    // MARK: - Cultural Data Management
    
    /// Update cultural data with new information and track data source
    func updateCulturalData(
        gender: AuthorGender? = nil,
        nationality: String? = nil,
        ethnicity: String? = nil,
        culturalRegion: CulturalRegion? = nil,
        birthYear: Int? = nil,
        deathYear: Int? = nil,
        confidence: Double? = nil,
        source: DataSource,
        fieldPath: String? = nil
    ) {
        var sources = culturalDataSources
        let timestamp = Date()
        
        if let gender = gender {
            self.gender = gender
            sources["gender"] = DataSourceInfo(source: source, timestamp: timestamp, confidence: confidence ?? 0.7, fieldPath: fieldPath)
        }
        
        if let nationality = nationality {
            self.nationality = nationality
            sources["nationality"] = DataSourceInfo(source: source, timestamp: timestamp, confidence: confidence ?? 0.7, fieldPath: fieldPath)
        }
        
        if let ethnicity = ethnicity {
            self.ethnicity = ethnicity
            sources["ethnicity"] = DataSourceInfo(source: source, timestamp: timestamp, confidence: confidence ?? 0.7, fieldPath: fieldPath)
        }
        
        if let culturalRegion = culturalRegion {
            self.culturalRegion = culturalRegion
            sources["culturalRegion"] = DataSourceInfo(source: source, timestamp: timestamp, confidence: confidence ?? 0.7, fieldPath: fieldPath)
        }
        
        if let birthYear = birthYear {
            self.birthYear = birthYear
            sources["birthYear"] = DataSourceInfo(source: source, timestamp: timestamp, confidence: confidence ?? 0.8, fieldPath: fieldPath)
        }
        
        if let deathYear = deathYear {
            self.deathYear = deathYear
            sources["deathYear"] = DataSourceInfo(source: source, timestamp: timestamp, confidence: confidence ?? 0.8, fieldPath: fieldPath)
        }
        
        culturalDataSources = sources
        culturalDataLastUpdate = timestamp
        
        // Recalculate overall confidence
        recalculateCulturalDataConfidence()
    }
    
    /// Recalculate overall cultural data confidence based on individual field confidences
    private func recalculateCulturalDataConfidence() {
        let sources = culturalDataSources.values
        guard !sources.isEmpty else {
            culturalDataConfidence = 0.0
            return
        }
        
        let totalConfidence = sources.reduce(0.0) { $0 + $1.confidence }
        culturalDataConfidence = totalConfidence / Double(sources.count)
    }
    
    /// Check if author represents indigenous voices
    func representsIndigenousVoices() -> Bool {
        return culturalRegions.contains(.indigenous) || culturalRegion == .indigenous
    }
    
    /// Check if author represents marginalized voices
    func representsMarginalizedVoices() -> Bool {
        // Indigenous authors
        if representsIndigenousVoices() {
            return true
        }
        
        // Underrepresented regions
        let marginalizedRegions: [CulturalRegion] = [.africa, .indigenous, .middleEast, .centralAsia]
        if let region = culturalRegion, marginalizedRegions.contains(region) {
            return true
        }
        if culturalRegions.contains(where: { marginalizedRegions.contains($0) }) {
            return true
        }
        
        // Gender diversity
        if gender == .female || gender == .nonBinary || gender == .other {
            return true
        }
        
        return false
    }
    
    // MARK: - Statistics and Analytics
    
    /// Update author statistics based on user's library
    func updateStatistics(from userBooks: [UserBook]) {
        let authorBooks = userBooks.filter { userBook in
            userBook.metadata?.authors.contains { matches($0) } ?? false
        }
        
        bookCount = authorBooks.count
        
        // Calculate average rating
        let ratingsSum = authorBooks.compactMap { $0.rating }.reduce(0, +)
        let ratingsCount = authorBooks.filter { $0.rating != nil }.count
        averageRating = ratingsCount > 0 ? Double(ratingsSum) / Double(ratingsCount) : 0.0
        
        // Calculate engagement score based on user interactions
        let engagementFactors: [Double] = [
            authorBooks.filter { $0.notes?.isEmpty == false }.count > 0 ? 0.3 : 0.0,  // Has notes
            authorBooks.filter { !$0.tags.isEmpty }.count > 0 ? 0.2 : 0.0,   // Has tags
            authorBooks.filter { $0.rating != nil }.count > 0 ? 0.25 : 0.0,  // Has ratings
            authorBooks.filter { $0.readingStatus == .read }.count > 0 ? 0.25 : 0.0  // Has finished books
        ]
        
        userEngagementScore = engagementFactors.reduce(0, +)
        isFrequentlyRead = bookCount >= 3
        
        // Search weight based on book count and engagement
        searchWeight = max(1.0, Double(bookCount) * 0.5 + userEngagementScore * 2.0)
        
        dateLastModified = Date()
    }
    
    // MARK: - Validation Methods
    
    func validateName() -> Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && name.count <= 200
    }
    
    func validateBirthYear() -> Bool {
        guard let year = birthYear else { return true }
        return year >= 1000 && year <= Calendar.current.component(.year, from: Date())
    }
    
    func validateDeathYear() -> Bool {
        guard let year = deathYear else { return true }
        let currentYear = Calendar.current.component(.year, from: Date())
        return year >= 1000 && year <= currentYear && (birthYear == nil || year >= birthYear!)
    }
    
    // MARK: - Hashable Conformance
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: AuthorProfile, rhs: AuthorProfile) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Sendable Conformance
extension AuthorProfile: @unchecked Sendable {}