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
    
    // NEW: Add a property for storing quotes
    var quotes: [String]?
    
    // NEW: Enhanced reading progress tracking
    var currentPage: Int = 0 {
        didSet {
            // Auto-calculate progress percentage
            updateReadingProgress()
        }
    }
    var readingProgress: Double = 0.0 // 0.0 to 1.0
    var estimatedFinishDate: Date?
    var readingSessions: [ReadingSession] = []
    var totalReadingTimeMinutes: Int = 0
    var dailyReadingGoal: Int? // pages per day
    var personalRating: Double? // 0.0 to 5.0 for more granular ratings
    
    // NEW: Cultural reading goals tracking
    var contributesToCulturalGoal: Bool = false
    var culturalGoalCategory: String? // e.g., "African Literature", "Translated Works"
    
    // NEW: Social and sharing features
    var isPublic: Bool = false
    var recommendedBy: String?
    var wouldRecommend: Bool?
    var discussionNotes: String? // for book clubs or discussions

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
        quotes: [String]? = nil,
        currentPage: Int = 0,
        dailyReadingGoal: Int? = nil,
        personalRating: Double? = nil,
        contributesToCulturalGoal: Bool = false,
        culturalGoalCategory: String? = nil,
        isPublic: Bool = false,
        recommendedBy: String? = nil,
        wouldRecommend: Bool? = nil,
        discussionNotes: String? = nil,
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
        self.quotes = quotes
        self.currentPage = currentPage
        self.dailyReadingGoal = dailyReadingGoal
        self.personalRating = personalRating
        self.contributesToCulturalGoal = contributesToCulturalGoal
        self.culturalGoalCategory = culturalGoalCategory
        self.isPublic = isPublic
        self.recommendedBy = recommendedBy
        self.wouldRecommend = wouldRecommend
        self.discussionNotes = discussionNotes
        self.metadata = metadata
        
        // Set initial dates based on status (non-auto since didSet won't trigger in init)
        if readingStatus == .reading {
            self.dateStarted = Date()
        } else if readingStatus == .read {
            self.dateStarted = Date()
            self.dateCompleted = Date()
        }
        
        // Calculate initial progress
        updateReadingProgress()
    }
    
    // NEW: Enhanced progress tracking methods
    func updateReadingProgress() {
        guard let pageCount = metadata?.pageCount, pageCount > 0 else {
            readingProgress = 0.0
            return
        }
        
        readingProgress = min(Double(currentPage) / Double(pageCount), 1.0)
        
        // Auto-complete if fully read
        if readingProgress >= 1.0 && readingStatus != .read {
            readingStatus = .read
        }
        
        // Calculate estimated finish date based on current progress and reading pace
        updateEstimatedFinishDate()
    }
    
    private func updateEstimatedFinishDate() {
        guard let pageCount = metadata?.pageCount,
              let dailyGoal = dailyReadingGoal,
              dailyGoal > 0,
              readingProgress < 1.0 else {
            estimatedFinishDate = nil
            return
        }
        
        let remainingPages = pageCount - currentPage
        let daysToFinish = Double(remainingPages) / Double(dailyGoal)
        estimatedFinishDate = Calendar.current.date(byAdding: .day, value: Int(ceil(daysToFinish)), to: Date())
    }
    
    func addReadingSession(minutes: Int, pagesRead: Int) {
        let session = ReadingSession(date: Date(), durationMinutes: minutes, pagesRead: pagesRead)
        readingSessions.append(session)
        totalReadingTimeMinutes += minutes
        currentPage += pagesRead
    }
    
    func averageReadingPace() -> Double? {
        guard !readingSessions.isEmpty else { return nil }
        
        let totalPages = readingSessions.reduce(0) { $0 + $1.pagesRead }
        let totalMinutes = readingSessions.reduce(0) { $0 + $1.durationMinutes }
        
        guard totalMinutes > 0 else { return nil }
        return Double(totalPages) / Double(totalMinutes) * 60.0 // pages per hour
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

// NEW: Reading session tracking
struct ReadingSession: Codable, Identifiable {
    let id = UUID()
    let date: Date
    let durationMinutes: Int
    let pagesRead: Int
    
    var pagesPerHour: Double {
        guard durationMinutes > 0 else { return 0 }
        return Double(pagesRead) / (Double(durationMinutes) / 60.0)
    }
}

enum ReadingStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case toRead = "To Read"
    case reading = "Reading"
    case read = "Read"
    case onHold = "On Hold"
    case dnf = "Did Not Finish"
    
    var id: Self { self }
}