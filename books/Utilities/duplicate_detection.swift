import Foundation
import SwiftData

struct DuplicateDetectionService {
    
    /// Check if a book already exists in the library
    static func findExistingBook(
        for metadata: BookMetadata, 
        in userBooks: [UserBook]
    ) -> UserBook? {
        
        // First, try to match by Google Books ID (most reliable)
        if !metadata.googleBooksID.isEmpty {
            for userBook in userBooks {
                if let bookMetadata = userBook.metadata,
                   bookMetadata.googleBooksID == metadata.googleBooksID {
                    return userBook
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
                        return userBook
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
                return userBook
            }
            
            // Check for very close matches (accounting for subtitles, etc.)
            if isVeryCloseMatch(resultTitle, bookTitle) && 
               isVeryCloseMatch(resultAuthor, bookAuthor) {
                return userBook
            }
        }
        
        return nil
    }
    
    /// Clean and normalize ISBN for comparison
    private static func cleanISBN(_ isbn: String) -> String {
        return isbn.replacingOccurrences(of: "-", with: "")
                  .replacingOccurrences(of: " ", with: "")
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