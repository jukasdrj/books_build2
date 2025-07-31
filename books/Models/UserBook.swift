import Foundation
import SwiftData

@Model
final class UserBook: Identifiable, @unchecked Sendable {
    var id: UUID
    var dateAdded: Date
    var dateStarted: Date?
    var dateCompleted: Date?
    var readingStatus: ReadingStatus
    var isFavorited: Bool
    var owned: Bool
    var onWishlist: Bool
    var rating: Int?
    var notes: String?
    var tags: [String]
    
    @Relationship(deleteRule: .cascade, inverse: \BookMetadata.userBook)
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
        self.id = UUID() // Generate UUID once during initialization
        self.dateAdded = dateAdded
        self.readingStatus = readingStatus
        self.isFavorited = isFavorited
        self.owned = owned
        self.onWishlist = onWishlist
        self.rating = rating
        self.notes = notes
        self.tags = tags
        self.metadata = metadata
    }
}

enum ReadingStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case toRead = "To Read"
    case reading = "Reading"
    case read = "Read"
    
    var id: Self { self }
}