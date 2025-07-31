import Foundation
import SwiftData

@Model
final class UserBook: Identifiable, @unchecked Sendable {
    var id: UUID
    var dateAdded: Date
    var dateStarted: Date?
    var dateCompleted: Date?
    private var _readingStatus: ReadingStatus
    var isFavorited: Bool
    var owned: Bool
    var onWishlist: Bool
    private var _rating: Int?
    private var _notes: String?
    private var _tags: [String]
    
    @Relationship(deleteRule: .nullify)
    var metadata: BookMetadata?
    
    // Computed property for readingStatus with auto-date logic
    var readingStatus: ReadingStatus {
        get { _readingStatus }
        set {
            let oldValue = _readingStatus
            _readingStatus = newValue
            
            // Auto-set dates based on status changes
            if newValue == .reading && oldValue != .reading && dateStarted == nil {
                dateStarted = Date()
            }
            
            if newValue == .read && oldValue != .read {
                if dateCompleted == nil {
                    dateCompleted = Date()
                }
                if dateStarted == nil {
                    dateStarted = Date()
                }
            }
        }
    }
    
    // Computed property for rating with validation
    var rating: Int? {
        get { _rating }
        set {
            if let value = newValue {
                guard value >= 1 && value <= 5 else {
                    fatalError("Rating must be 1-5 inclusive")
                }
            }
            _rating = newValue
        }
    }
    
    // Computed property for notes with validation
    var notes: String? {
        get { _notes }
        set {
            if let value = newValue, value.count > 5000 {
                fatalError("Notes must be max 5,000 characters")
            }
            _notes = newValue
        }
    }
    
    // Computed property for tags with validation
    var tags: [String] {
        get { _tags }
        set {
            guard newValue.count <= 20 else {
                fatalError("Maximum 20 tags allowed")
            }
            guard newValue.allSatisfy({ $0.count >= 1 && $0.count <= 50 }) else {
                fatalError("Each tag must be 1-50 characters")
            }
            _tags = newValue
        }
    }
    
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
        // Validate rating
        if let ratingValue = rating {
            guard ratingValue >= 1 && ratingValue <= 5 else {
                fatalError("Rating must be 1-5 inclusive")
            }
        }
        
        // Validate notes
        if let notesValue = notes, notesValue.count > 5000 {
            fatalError("Notes must be max 5,000 characters")
        }
        
        // Validate tags
        guard tags.count <= 20 else {
            fatalError("Maximum 20 tags allowed")
        }
        guard tags.allSatisfy({ $0.count >= 1 && $0.count <= 50 }) else {
            fatalError("Each tag must be 1-50 characters")
        }
        
        self.id = UUID()
        self.dateAdded = dateAdded
        self._readingStatus = readingStatus
        self.isFavorited = isFavorited
        self.owned = owned
        self.onWishlist = onWishlist
        self._rating = rating
        self._notes = notes
        self._tags = tags
        self.metadata = metadata
        
        // Set initial dates based on status
        if readingStatus == .reading {
            self.dateStarted = Date()
        } else if readingStatus == .read {
            self.dateStarted = Date()
            self.dateCompleted = Date()
        }
    }
}

enum ReadingStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case toRead = "To Read"
    case reading = "Reading"
    case read = "Read"
    
    var id: Self { self }
}