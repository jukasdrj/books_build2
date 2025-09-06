import Foundation
import SwiftData

/// Service for managing AuthorProfile entities and author-related operations
/// Handles author normalization, matching, deduplication, and cultural data management
@MainActor
final class AuthorService: ObservableObject {
    
    private let modelContext: ModelContext
    
    // MARK: - Performance Optimization
    
    /// Cache of recently accessed author profiles for performance
    private var authorCache: [String: AuthorProfile] = [:]
    private let cacheLimit = 100
    
    /// Background queue for expensive operations
    private let backgroundQueue = DispatchQueue(label: "authorservice.background", qos: .userInitiated)
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Author Finding and Creation
    
    /// Find or create an AuthorProfile for a given author name
    /// Returns existing profile if found, creates new one if not
    func findOrCreateAuthor(name: String, from source: DataSource = .manualEntry) async -> AuthorProfile {
        let normalizedName = normalizeAuthorName(name)
        
        // Check cache first
        if let cached = authorCache[normalizedName] {
            return cached
        }
        
        // Try to find existing author
        if let existingAuthor = await findExistingAuthor(name: name) {
            authorCache[normalizedName] = existingAuthor
            return existingAuthor
        }
        
        // Create new author profile
        let newAuthor = AuthorProfile(
            name: name,
            culturalDataSources: [
                "initial": DataSourceInfo(source: source, confidence: 0.5)
            ]
        )
        
        modelContext.insert(newAuthor)
        
        do {
            try modelContext.save()
            authorCache[normalizedName] = newAuthor
            
            // Background enrichment
            Task {
                await enrichAuthorProfile(newAuthor)
            }
            
            return newAuthor
        } catch {
            print("Error saving new author: \(error)")
            return newAuthor
        }
    }
    
    /// Find existing author by name, checking various matching strategies
    private func findExistingAuthor(name: String) async -> AuthorProfile? {
        let normalizedName = normalizeAuthorName(name)
        
        // Create fetch descriptor for authors
        let descriptor = FetchDescriptor<AuthorProfile>()
        
        do {
            let allAuthors = try modelContext.fetch(descriptor)
            
            // Try exact normalized name match first (fastest)
            if let exactMatch = allAuthors.first(where: { $0.normalizedName == normalizedName }) {
                return exactMatch
            }
            
            // Try alias matching
            for author in allAuthors {
                if author.matches(name) {
                    return author
                }
            }
            
            return nil
        } catch {
            print("Error fetching authors: \(error)")
            return nil
        }
    }
    
    /// Get all authors from the database
    func getAllAuthors() async -> [AuthorProfile] {
        let descriptor = FetchDescriptor<AuthorProfile>(sortBy: [SortDescriptor(\.searchWeight, order: .reverse)])
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error fetching all authors: \(error)")
            return []
        }
    }
    
    /// Search authors by various criteria
    func searchAuthors(
        query: String? = nil,
        culturalRegion: CulturalRegion? = nil,
        gender: AuthorGender? = nil,
        language: String? = nil,
        minConfidence: Double = 0.0
    ) async -> [AuthorProfile] {
        var predicate: Predicate<AuthorProfile>?
        
        // Build predicate based on search criteria
        if let query = query, !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let normalizedQuery = normalizeAuthorName(query)
            predicate = #Predicate<AuthorProfile> { author in
                author.normalizedName.contains(normalizedQuery) ||
                author.name.contains(query)
            }
        }
        
        if let region = culturalRegion {
            let regionPredicate = #Predicate<AuthorProfile> { author in
                author.culturalRegion == region
            }
            predicate = predicate == nil ? regionPredicate : #Predicate { _ in true } // Simplified for complex combinations
        }
        
        if let targetGender = gender {
            let genderPredicate = #Predicate<AuthorProfile> { author in
                author.gender == targetGender
            }
            predicate = predicate == nil ? genderPredicate : #Predicate { _ in true } // Simplified for complex combinations
        }
        
        let descriptor = FetchDescriptor<AuthorProfile>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.searchWeight, order: .reverse)]
        )
        
        do {
            let results = try modelContext.fetch(descriptor)
            
            // Apply additional filtering that can't be done in predicate
            return results.filter { author in
                // Confidence filter
                if author.culturalDataConfidence < minConfidence {
                    return false
                }
                
                // Language filter
                if let language = language {
                    return author.languages.contains { $0.lowercased().contains(language.lowercased()) }
                }
                
                return true
            }
        } catch {
            print("Error searching authors: \(error)")
            return []
        }
    }
    
    // MARK: - Author Profile Enhancement
    
    /// Enrich an author profile with additional data from various sources
    func enrichAuthorProfile(_ author: AuthorProfile) async {
        // Update from CloudFlare author indexing service
        await updateFromCloudFlareIndex(author)
        
        // Update statistics from user's library
        await updateAuthorStatistics(author)
        
        // Save changes
        do {
            try modelContext.save()
        } catch {
            print("Error saving enriched author profile: \(error)")
        }
    }
    
    /// Update author profile from CloudFlare author indexing service
    private func updateFromCloudFlareIndex(_ author: AuthorProfile) async {
        guard let url = URL(string: "https://books-api-proxy-optimized-staging.jukasdrj.workers.dev/authors/search?name=\(author.name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else {
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if let response = try? JSONDecoder().decode(CloudFlareAuthorResponse.self, from: data),
               !response.authors.isEmpty {
                let cloudFlareAuthor = response.authors[0]
                
                // Update cultural data with high confidence from CloudFlare
                author.updateCulturalData(
                    nationality: cloudFlareAuthor.nationality,
                    ethnicity: cloudFlareAuthor.ethnicity,
                    confidence: 0.8,
                    source: .googleBooksAPI,
                    fieldPath: "cloudflare_index"
                )
                
                if let genderString = cloudFlareAuthor.gender,
                   let gender = AuthorGender(rawValue: genderString) {
                    author.gender = gender
                }
                
                if let regionString = cloudFlareAuthor.culturalRegion,
                   let region = CulturalRegion(rawValue: regionString) {
                    author.culturalRegion = region
                }
                
                // Add themes and languages
                if !cloudFlareAuthor.themes.isEmpty {
                    let currentThemes = Set(author.culturalThemes)
                    let newThemes = Set(cloudFlareAuthor.themes)
                    author.culturalThemes = Array(currentThemes.union(newThemes))
                }
                
                if !cloudFlareAuthor.languages.isEmpty {
                    let currentLanguages = Set(author.languages)
                    let newLanguages = Set(cloudFlareAuthor.languages)
                    author.languages = Array(currentLanguages.union(newLanguages))
                }
                
                // Update search weight based on CloudFlare popularity
                if cloudFlareAuthor.popularityScore > 0 {
                    author.searchWeight = max(author.searchWeight, Double(cloudFlareAuthor.popularityScore))
                }
            }
        } catch {
            print("Error fetching author data from CloudFlare: \(error)")
        }
    }
    
    /// Update author statistics based on user's library
    private func updateAuthorStatistics(_ author: AuthorProfile) async {
        do {
            let userBookDescriptor = FetchDescriptor<UserBook>()
            let allUserBooks = try modelContext.fetch(userBookDescriptor)
            
            // Find books by this author
            let authorBooks = allUserBooks.filter { userBook in
                userBook.metadata?.authorProfiles.contains(author) == true ||
                userBook.metadata?.authors.contains { authorName in
                    author.matches(authorName)
                } == true
            }
            
            author.updateStatistics(from: authorBooks)
            
        } catch {
            print("Error updating author statistics: \(error)")
        }
    }
    
    // MARK: - Author Migration and Maintenance
    
    /// Migrate all BookMetadata entries to use AuthorProfile relationships
    func migrateAllBooksToAuthorProfiles() async -> MigrationResult {
        let bookDescriptor = FetchDescriptor<BookMetadata>()
        var migrationResult = MigrationResult()
        
        do {
            let allBooks = try modelContext.fetch(bookDescriptor)
            
            for book in allBooks {
                if book.authorProfiles.isEmpty && !book.authors.isEmpty {
                    // Migrate this book's authors
                    let createdProfiles = await migrateBookAuthors(book)
                    migrationResult.booksProcessed += 1
                    migrationResult.authorsCreated += createdProfiles.count
                }
            }
            
            try modelContext.save()
            migrationResult.success = true
            
        } catch {
            print("Error during migration: \(error)")
            migrationResult.error = error
        }
        
        return migrationResult
    }
    
    /// Migrate a single book's authors to AuthorProfile relationships
    private func migrateBookAuthors(_ book: BookMetadata) async -> [AuthorProfile] {
        var createdProfiles: [AuthorProfile] = []
        
        for authorName in book.authors {
            let profile = await findOrCreateAuthor(name: authorName, from: .mixedSources)
            
            // Associate with book if not already associated
            if !book.authorProfiles.contains(profile) {
                book.addAuthorProfile(profile)
            }
            
            // Transfer cultural data from book to author if author has low confidence
            if profile.culturalDataConfidence < 0.5 {
                profile.updateCulturalData(
                    gender: book.authorGender,
                    nationality: book.authorNationality,
                    ethnicity: book.authorEthnicity,
                    culturalRegion: book.culturalRegion,
                    confidence: 0.4, // Medium confidence from book metadata
                    source: .mixedSources,
                    fieldPath: "book_migration"
                )
                
                if !book.culturalThemes.isEmpty {
                    let currentThemes = Set(profile.culturalThemes)
                    let bookThemes = Set(book.culturalThemes)
                    profile.culturalThemes = Array(currentThemes.union(bookThemes))
                }
            }
            
            createdProfiles.append(profile)
        }
        
        return createdProfiles
    }
    
    /// Find and merge duplicate author profiles
    func deduplicateAuthors() async -> DeduplicationResult {
        let allAuthors = await getAllAuthors()
        var result = DeduplicationResult()
        
        // Group authors by normalized name for initial duplicate detection
        let authorGroups = Dictionary(grouping: allAuthors) { $0.normalizedName }
        
        for (_, authors) in authorGroups where authors.count > 1 {
            // Multiple authors with same normalized name - potential duplicates
            let primaryAuthor = authors.max { $0.culturalDataConfidence < $1.culturalDataConfidence } ?? authors[0]
            let duplicates = authors.filter { $0.id != primaryAuthor.id }
            
            for duplicate in duplicates {
                await mergeDuplicateAuthors(primary: primaryAuthor, duplicate: duplicate)
                modelContext.delete(duplicate)
                result.mergedCount += 1
            }
        }
        
        // Look for similar authors across different normalized names
        await findAndMergeSimilarAuthors(result: &result)
        
        do {
            try modelContext.save()
            result.success = true
        } catch {
            print("Error during deduplication: \(error)")
            result.error = error
        }
        
        return result
    }
    
    /// Find authors with similar names and merge if they're the same person
    private func findAndMergeSimilarAuthors(result: inout DeduplicationResult) async {
        let allAuthors = await getAllAuthors()
        
        // Compare each author with every other author for similarity
        for i in 0..<allAuthors.count {
            for j in (i+1)..<allAuthors.count {
                let author1 = allAuthors[i]
                let author2 = allAuthors[j]
                
                // Check if they might be the same person
                if await areAuthorsSamePerson(author1, author2) {
                    let primary = author1.culturalDataConfidence >= author2.culturalDataConfidence ? author1 : author2
                    let duplicate = author1.culturalDataConfidence >= author2.culturalDataConfidence ? author2 : author1
                    
                    await mergeDuplicateAuthors(primary: primary, duplicate: duplicate)
                    modelContext.delete(duplicate)
                    result.mergedCount += 1
                    break // Avoid double-processing
                }
            }
        }
    }
    
    /// Check if two authors are likely the same person
    private func areAuthorsSamePerson(_ author1: AuthorProfile, _ author2: AuthorProfile) async -> Bool {
        // Name similarity
        let nameSimilarity = calculateNameSimilarity(author1.normalizedName, author2.normalizedName)
        if nameSimilarity < 0.7 {
            return false
        }
        
        // Check aliases
        let allNames1 = Set([author1.name, author1.normalizedName] + author1.aliases + author1.googleBooksNames)
        let allNames2 = Set([author2.name, author2.normalizedName] + author2.aliases + author2.googleBooksNames)
        
        if !allNames1.intersection(allNames2).isEmpty {
            return true
        }
        
        // External ID matches
        if let id1 = author1.isbndbID, let id2 = author2.isbndbID, id1 == id2 {
            return true
        }
        
        if let key1 = author1.openLibraryKey, let key2 = author2.openLibraryKey, key1 == key2 {
            return true
        }
        
        // Birth/death year consistency (if available)
        if let birth1 = author1.birthYear, let birth2 = author2.birthYear {
            return abs(birth1 - birth2) <= 1 // Allow 1 year difference for data inconsistencies
        }
        
        return nameSimilarity > 0.9 // High name similarity threshold
    }
    
    /// Merge duplicate author profiles
    private func mergeDuplicateAuthors(primary: AuthorProfile, duplicate: AuthorProfile) async {
        // Merge aliases and name variations
        let allAliases = Set(primary.aliases + duplicate.aliases + [duplicate.name])
        primary.aliases = Array(allAliases)
        
        let allGoogleNames = Set(primary.googleBooksNames + duplicate.googleBooksNames)
        primary.googleBooksNames = Array(allGoogleNames)
        
        // Merge external IDs (prefer non-nil values)
        if primary.isbndbID == nil && duplicate.isbndbID != nil {
            primary.isbndbID = duplicate.isbndbID
        }
        
        if primary.openLibraryKey == nil && duplicate.openLibraryKey != nil {
            primary.openLibraryKey = duplicate.openLibraryKey
        }
        
        if primary.orcidID == nil && duplicate.orcidID != nil {
            primary.orcidID = duplicate.orcidID
        }
        
        // Merge cultural data (prefer higher confidence values)
        if duplicate.culturalDataConfidence > primary.culturalDataConfidence {
            primary.gender = duplicate.gender
            primary.nationality = duplicate.nationality
            primary.ethnicity = duplicate.ethnicity
            primary.culturalRegion = duplicate.culturalRegion
            primary.birthYear = duplicate.birthYear
            primary.deathYear = duplicate.deathYear
        }
        
        // Merge languages and themes
        let allLanguages = Set(primary.languages + duplicate.languages)
        primary.languages = Array(allLanguages)
        
        let allThemes = Set(primary.culturalThemes + duplicate.culturalThemes)
        primary.culturalThemes = Array(allThemes)
        
        // Update statistics
        primary.bookCount += duplicate.bookCount
        primary.searchWeight = max(primary.searchWeight, duplicate.searchWeight)
        
        // Transfer book relationships
        for book in duplicate.books {
            book.removeAuthorProfile(duplicate)
            book.addAuthorProfile(primary)
        }
        
        // Merge cultural data sources
        let mergedSources = primary.culturalDataSources.merging(duplicate.culturalDataSources) { current, new in
            return current.confidence >= new.confidence ? current : new
        }
        primary.culturalDataSources = mergedSources
        
        primary.dateLastModified = Date()
    }
    
    // MARK: - Utility Methods
    
    /// Normalize author name for matching
    private func normalizeAuthorName(_ name: String) -> String {
        let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        // Handle "Last, First" format
        if cleaned.contains(",") {
            let parts = cleaned.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count >= 2 && !parts[0].isEmpty && !parts[1].isEmpty {
                return "\(parts[1]) \(parts[0])"
            }
        }
        
        return cleaned
    }
    
    /// Calculate name similarity (0.0-1.0)
    private func calculateNameSimilarity(_ name1: String, _ name2: String) -> Double {
        let maxLength = max(name1.count, name2.count)
        guard maxLength > 0 else { return 0.0 }
        
        let distance = levenshteinDistance(name1, name2)
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
    
    /// Clear author cache to free memory
    func clearCache() {
        authorCache.removeAll()
    }
    
    /// Get cache statistics
    func getCacheStats() -> (count: Int, limit: Int) {
        return (authorCache.count, cacheLimit)
    }
}

// MARK: - Supporting Types

/// Result of migration operation
struct MigrationResult {
    var success: Bool = false
    var booksProcessed: Int = 0
    var authorsCreated: Int = 0
    var error: Error?
}

/// Result of deduplication operation
struct DeduplicationResult {
    var success: Bool = false
    var mergedCount: Int = 0
    var error: Error?
}

/// Response from CloudFlare author search
struct CloudFlareAuthorResponse: Codable {
    let authors: [CloudFlareAuthor]
    let total: Int
}

/// Author data from CloudFlare indexing service
struct CloudFlareAuthor: Codable {
    let name: String
    let nationality: String?
    let gender: String?
    let ethnicity: String?
    let culturalRegion: String?
    let themes: [String]
    let languages: [String]
    let popularityScore: Int
    let confidence: Double
}