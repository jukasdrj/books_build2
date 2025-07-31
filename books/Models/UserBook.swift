import Foundation
import SwiftData

@Model
final class UserBook: Identifiable, @unchecked Sendable {
    var id: UUID
    var dateAdded: Date
    var dateStarted: Date?
    var dateCompleted: Date?
    var readingStatus: ReadingStatus {
        didSet {
            // Auto-set dates based on status changes
            if readingStatus == .reading && oldValue != .reading && dateStarted == nil {
                dateStarted = Date()
            }
            
            if readingStatus == .read && oldValue != .read {
                if dateCompleted == nil {
                    dateCompleted = Date()
                }
                if dateStarted == nil {
                    dateStarted = Date()
                }
            }
        }
    }
    var isFavorited: Bool
    var owned: Bool
    var onWishlist: Bool
    var rating: Int? {
        didSet {
            // Validate rating range
            if let value = rating, !(1...5).contains(value) {
                rating = oldValue // Revert to previous valid value
            }
        }
    }
    var notes: String? {
        didSet {
            // Validate notes length
            if let value = notes, value.count > 5000 {
                notes = String(value.prefix(5000)) // Truncate instead of fatal error
            }
        }
    }
    var tags: [String] {
        didSet {
            // Validate tags
            if tags.count > 20 {
                tags = Array(tags.prefix(20)) // Truncate to 20 tags
            }
            // Validate individual tag lengths
            tags = tags.map { tag in
                if tag.count > 50 {
                    return String(tag.prefix(50))
                }
                return tag
            }.filter { !$0.isEmpty }
        }
    }
    
    @Relationship(deleteRule: .nullify)
    var metadata: BookMetadata?
    
    init(
        dateAdded: Date = .now,
        readingStatus: ReadingStatus = .toRead,
        isFavorited: Bool = false,
        owned: Bool = true,
        onWishlist: Bool = false,
        rating: Int? = nil,
        notes: String? = nil,
        tags: [String] = [],
        metadata: BookMetadata? = nil
    ) {
        self.id = UUID()
        self.dateAdded = dateAdded
        self.readingStatus = readingStatus
        self.isFavorited = isFavorited
        self.owned = owned
        self.onWishlist = onWishlist
        self.rating = rating
        self.notes = notes
        self.tags = tags
        self.metadata = metadata
        
        // Set initial dates based on status (non-auto since didSet won't trigger in init)
        if readingStatus == .reading {
            self.dateStarted = Date()
        } else if readingStatus == .read {
            self.dateStarted = Date()
            self.dateCompleted = Date()
        }
    }
    
    // Validation methods (non-fatal for migration safety)
    func validateRating() -> Bool {
        guard let rating = rating else { return true }
        return (1...5).contains(rating)
    }
    
    func validateNotes() -> Bool {
        guard let notes = notes else { return true }
        return notes.count <= 5000
    }
    
    func validateTags() -> Bool {
        return tags.count <= 20 && tags.allSatisfy({ $0.count >= 1 && $0.count <= 50 })
    }
}

enum ReadingStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case toRead = "To Read"
    case reading = "Reading"
    case read = "Read"
    
    var id: Self { self }
}