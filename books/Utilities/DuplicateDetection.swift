import Foundation
import SwiftData

struct DuplicateDetectionService {
    
    /// Types of duplicate detection methods
    enum DuplicateDetectionMethod {
        case googleBooksID
        case isbn
        case titleAuthor
    }
    
    /// Result of duplicate detection
    struct DuplicateDetectionResult {
        let userBook: UserBook
        let method: DuplicateDetectionMethod
    }
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Performance-optimized duplicate detection with hash-based lookups
    /// Creates lookup dictionaries for O(1) access instead of O(n) iteration
    func findExistingBook(for metadata: BookMetadata) -> DuplicateDetectionResult? {
        // Fetch all user books once
        let descriptor = FetchDescriptor<UserBook>()
        guard let userBooks = try? modelContext.fetch(descriptor) else {
            return nil
        }
        
        // Build lookup dictionaries for O(1) access
        var googleBooksIDLookup: [String: UserBook] = [:]
        var isbnLookup: [String: UserBook] = [:]
        var titleAuthorLookup: [String: UserBook] = [:]
        
        for userBook in userBooks {
            guard let bookMetadata = userBook.metadata else { continue }
            
            // Index by provider ID (Google Books ID, ISBNDB ID, etc.)
            if !bookMetadata.googleBooksID.isEmpty {
                googleBooksIDLookup[bookMetadata.googleBooksID] = userBook
                
                // Also index by provider type for cross-provider duplicate detection
                if bookMetadata.googleBooksID.contains(":") {
                    let components = bookMetadata.googleBooksID.components(separatedBy: ":")
                    if components.count == 2 {
                        let _ = components[0] // provider type
                        let providerId = components[1]
                        googleBooksIDLookup[providerId] = userBook // Index base ID too
                    }
                }
            }
            
            // Index by clean ISBN
            if let isbn = bookMetadata.isbn, !isbn.isEmpty {
                let cleanISBN = Self.cleanISBN(isbn)
                isbnLookup[cleanISBN] = userBook
            }
            
            // Index by normalized title+author
            if !bookMetadata.title.isEmpty, let firstAuthor = bookMetadata.authors.first {
                let key = Self.normalizeTitle(bookMetadata.title) + "|" + Self.normalizeAuthor(firstAuthor)
                titleAuthorLookup[key] = userBook
            }
        }
        
        // PRIORITY 1: Check ISBN first (most reliable unique identifier)
        if let metadataISBN = metadata.isbn, !metadataISBN.isEmpty {
            let cleanISBN = Self.cleanISBN(metadataISBN)
            if let match = isbnLookup[cleanISBN] {
                return DuplicateDetectionResult(userBook: match, method: .isbn)
            }
        }
        
        // PRIORITY 2: Check Google Books ID (reliable but only when both have it)
        if !metadata.googleBooksID.isEmpty,
           let match = googleBooksIDLookup[metadata.googleBooksID] {
            return DuplicateDetectionResult(userBook: match, method: .googleBooksID)
        }
        
        // PRIORITY 3: Enhanced title+author matching with fuzzy logic
        if !metadata.title.isEmpty, let firstAuthor = metadata.authors.first {
            let key = Self.normalizeTitle(metadata.title) + "|" + Self.normalizeAuthor(firstAuthor)
            
            // Exact match first
            if let match = titleAuthorLookup[key] {
                return DuplicateDetectionResult(userBook: match, method: .titleAuthor)
            }
            
            // Fuzzy matching for title+author when exact fails
            let normalizedTitle = Self.normalizeTitle(metadata.title)
            let normalizedAuthor = Self.normalizeAuthor(firstAuthor)
            
            for userBook in userBooks {
                guard let existingMetadata = userBook.metadata else { continue }
                guard !existingMetadata.title.isEmpty, let existingFirstAuthor = existingMetadata.authors.first else { continue }
                
                let existingNormalizedTitle = Self.normalizeTitle(existingMetadata.title)
                let existingNormalizedAuthor = Self.normalizeAuthor(existingFirstAuthor)
                
                // Check if titles and authors are very close matches
                if Self.isVeryCloseMatch(normalizedTitle, existingNormalizedTitle) &&
                   Self.isVeryCloseMatch(normalizedAuthor, existingNormalizedAuthor) {
                    return DuplicateDetectionResult(userBook: userBook, method: .titleAuthor)
                }
            }
        }
        
        return nil
    }
    
    /// Legacy static method for backward compatibility
    static func findExistingBook(
        for metadata: BookMetadata, 
        in userBooks: [UserBook]
    ) -> UserBook? {
        if let result = findExistingBookWithMethod(for: metadata, in: userBooks) {
            return result.userBook
        }
        return nil
    }
    
    /// Legacy static method for backward compatibility
    static func findExistingBookWithMethod(
        for metadata: BookMetadata, 
        in userBooks: [UserBook]
    ) -> DuplicateDetectionResult? {
        
        // First, try to match by Google Books ID (most reliable)
        if !metadata.googleBooksID.isEmpty {
            for userBook in userBooks {
                if let bookMetadata = userBook.metadata,
                   bookMetadata.googleBooksID == metadata.googleBooksID {
                    return DuplicateDetectionResult(userBook: userBook, method: .googleBooksID)
                }
            }
        }
        
        // Then try to match by ISBN (also very reliable)
        if let metadataISBN = metadata.isbn, !metadataISBN.isEmpty {
            let cleanResultISBN = cleanISBN(metadataISBN)
            
            for userBook in userBooks {
                if let bookMetadata = userBook.metadata,
                   let bookISBN = bookMetadata.isbn {
                    let cleanBookISBN = cleanISBN(bookISBN)
                    if cleanResultISBN == cleanBookISBN {
                        return DuplicateDetectionResult(userBook: userBook, method: .isbn)
                    }
                }
            }
        }
        
        // If no ISBN match, try title and author matching with fuzzy logic
        let resultTitle = normalizeTitle(metadata.title)
        let resultAuthor = normalizeAuthor(metadata.authors.joined(separator: ", "))
        
        for userBook in userBooks {
            guard let bookMetadata = userBook.metadata else { continue }
            
            let bookTitle = normalizeTitle(bookMetadata.title)
            let bookAuthor = normalizeAuthor(bookMetadata.authors.joined(separator: ", "))
            
            // Check for exact matches
            if resultTitle == bookTitle && resultAuthor == bookAuthor {
                return DuplicateDetectionResult(userBook: userBook, method: .titleAuthor)
            }
            
            // Check for very close matches (accounting for subtitles, etc.)
            if isVeryCloseMatch(resultTitle, bookTitle) && 
               isVeryCloseMatch(resultAuthor, bookAuthor) {
                return DuplicateDetectionResult(userBook: userBook, method: .titleAuthor)
            }
        }
        
        return nil
    }
    
    /// Clean and normalize ISBN for comparison
    private static func cleanISBN(_ isbn: String) -> String {
        return isbn.replacingOccurrences(of: "=", with: "") // Remove leading = from Goodreads exports
                  .replacingOccurrences(of: "-", with: "")
                  .replacingOccurrences(of: " ", with: "")
                  .trimmingCharacters(in: .whitespacesAndNewlines)
                  .uppercased()
    }
    
    /// Normalize title for comparison
    private static func normalizeTitle(_ title: String) -> String {
        return title.lowercased()
                   .trimmingCharacters(in: .whitespacesAndNewlines)
                   .replacingOccurrences(of: ":", with: "")
                   .replacingOccurrences(of: ";", with: "")
                   .replacingOccurrences(of: "  ", with: " ")
    }
    
    /// Normalize author for comparison
    private static func normalizeAuthor(_ author: String) -> String {
        return author.lowercased()
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: ",", with: "")
                    .replacingOccurrences(of: "  ", with: " ")
    }
    
    /// Check if two strings are very close matches (accounting for minor differences)
    private static func isVeryCloseMatch(_ string1: String, _ string2: String) -> Bool {
        // If one string contains the other, consider it a close match
        if string1.contains(string2) || string2.contains(string1) {
            return true
        }
        
        // Calculate simple similarity (could be enhanced with Levenshtein distance)
        let similarity = calculateSimilarity(string1, string2)
        return similarity > 0.85 // 85% similarity threshold
    }
    
    /// Calculate basic similarity between two strings
    private static func calculateSimilarity(_ string1: String, _ string2: String) -> Double {
        let longer = string1.count > string2.count ? string1 : string2
        let shorter = string1.count > string2.count ? string2 : string1
        
        if longer.count == 0 {
            return 1.0
        }
        
        let editDistance = levenshteinDistance(shorter, longer)
        return (Double(longer.count) - Double(editDistance)) / Double(longer.count)
    }
    
    /// Calculate Levenshtein distance between two strings
    private static func levenshteinDistance(_ string1: String, _ string2: String) -> Int {
        let empty = Array<Int>(repeating: 0, count: string2.count + 1)
        var last = Array(0...string2.count)
        
        for (i, char1) in string1.enumerated() {
            var current = [i + 1] + empty
            
            for (j, char2) in string2.enumerated() {
                current[j + 1] = char1 == char2 ? last[j] : min(
                    last[j] + 1,     // substitution
                    last[j + 1] + 1, // deletion
                    current[j] + 1   // insertion
                )
            }
            
            last = current
        }
        
        return last[string2.count]
    }
}