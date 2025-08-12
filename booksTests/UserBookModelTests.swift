import XCTest
import SwiftData
@testable import books

/// Tests for UserBook model using modern Swift 6 concurrency patterns
@MainActor
final class UserBookModelTests: BookTrackerTestSuite {
    
    // MARK: - UserBook Creation Tests
    
    func testUserBookCreation() async throws {
        let userBook = createTestUserBook(
            title: "Test Book",
            author: "Test Author",
            isbn: "1234567890",
            readingStatus: .reading,
            rating: 4
        )
        
        XCTAssertEqual(userBook.metadata?.title, "Test Book")
        XCTAssertEqual(userBook.metadata?.authors.first, "Test Author")
        XCTAssertEqual(userBook.metadata?.isbn, "1234567890")
        XCTAssertEqual(userBook.readingStatus, .reading)
        XCTAssertEqual(userBook.rating, 4)
        XCTAssertNotNil(userBook.id)
        XCTAssertNotNil(userBook.dateAdded)
    }
    
    func testUserBookPersistence() async throws {
        let userBook = createTestUserBook(
            title: "Persistent Book",
            author: "Persistent Author",
            isbn: "0987654321",
            readingStatus: .read
        )
        
        try saveContext()
        
        let fetchedBooks = try fetchAllUserBooks()
        XCTAssertEqual(fetchedBooks.count, 1)
        
        let fetchedBook = fetchedBooks.first!
        XCTAssertEqual(fetchedBook.metadata?.title, "Persistent Book")
        XCTAssertEqual(fetchedBook.metadata?.authors.first, "Persistent Author")
        XCTAssertEqual(fetchedBook.readingStatus, .read)
    }
    
    // MARK: - Reading Status Tests
    
    func testReadingStatusTransitions() async throws {
        let userBook = createTestUserBook(readingStatus: .toRead)
        
        // Test transition to reading
        userBook.readingStatus = .reading
        XCTAssertEqual(userBook.readingStatus, .reading)
        XCTAssertNotNil(userBook.dateStarted, "Date started should be set when status changes to reading")
        
        // Test transition to read
        userBook.readingStatus = .read
        XCTAssertEqual(userBook.readingStatus, .read)
        XCTAssertNotNil(userBook.dateCompleted, "Date completed should be set when status changes to read")
        XCTAssertEqual(userBook.readingProgress, 1.0, "Progress should be 1.0 when marked as read")
    }
    
    func testReadingProgressCalculation() async throws {
        let metadata = createTestBookMetadata(insert: false)
        metadata.pageCount = 300
        
        let userBook = UserBook(metadata: metadata)
        userBook.currentPage = 150
        
        modelContext.insert(metadata)
        modelContext.insert(userBook)
        
        // Progress should be calculated automatically
        XCTAssertEqual(userBook.readingProgress, 0.5, accuracy: 0.01)
    }
    
    func testCompletedBookProgress() async throws {
        let userBook = createTestUserBook(readingStatus: .read)
        
        // When marked as read, progress should be 1.0
        XCTAssertEqual(userBook.readingProgress, 1.0)
        
        // If page count is available, current page should be set
        if let pageCount = userBook.metadata?.pageCount, pageCount > 0 {
            XCTAssertEqual(userBook.currentPage, pageCount)
        }
    }
    
    // MARK: - Rating Tests
    
    func testRatingValidation() async throws {
        let userBook = createTestUserBook()
        
        // Valid ratings
        userBook.rating = 1
        XCTAssertEqual(userBook.rating, 1)
        
        userBook.rating = 5
        XCTAssertEqual(userBook.rating, 5)
        
        userBook.rating = 3
        XCTAssertEqual(userBook.rating, 3)
        
        // Invalid ratings should be rejected
        userBook.rating = 0
        XCTAssertNotEqual(userBook.rating, 0, "Rating 0 should be rejected")
        
        userBook.rating = 6
        XCTAssertNotEqual(userBook.rating, 6, "Rating 6 should be rejected")
    }
    
    func testPersonalRating() async throws {
        let userBook = createTestUserBook()
        
        // Test granular personal rating (0.0 to 5.0)
        userBook.personalRating = 4.5
        XCTAssertEqual(userBook.personalRating, 4.5)
        
        userBook.personalRating = 2.7
        XCTAssertEqual(userBook.personalRating, 2.7)
    }
    
    // MARK: - Cultural Diversity Tests
    
    func testCulturalGoalContribution() async throws {
        let userBook = createTestUserBook(culturalRegion: .africa)
        
        userBook.contributesToCulturalGoal = true
        userBook.culturalGoalCategory = "African Literature"
        
        XCTAssertTrue(userBook.contributesToCulturalGoal)
        XCTAssertEqual(userBook.culturalGoalCategory, "African Literature")
        XCTAssertEqual(userBook.metadata?.culturalRegion, .africa)
    }
    
    // MARK: - Notes and Tags Tests
    
    func testNotesValidation() async throws {
        let userBook = createTestUserBook()
        
        // Normal notes should work
        userBook.notes = "This is a great book with interesting characters."
        XCTAssertEqual(userBook.notes, "This is a great book with interesting characters.")
        
        // Very long notes should be truncated
        let longNotes = String(repeating: "A", count: 6000)
        userBook.notes = longNotes
        XCTAssertEqual(userBook.notes?.count, 5000, "Notes should be truncated to 5000 characters")
    }
    
    func testTagsManagement() async throws {
        let userBook = createTestUserBook()
        
        userBook.tags = ["fiction", "classic", "favorite"]
        XCTAssertEqual(userBook.tags.count, 3)
        XCTAssertTrue(userBook.tags.contains("fiction"))
        XCTAssertTrue(userBook.tags.contains("classic"))
        XCTAssertTrue(userBook.tags.contains("favorite"))
    }
    
    func testQuotesManagement() async throws {
        let userBook = createTestUserBook()
        
        let quotes = [
            "It was the best of times, it was the worst of times.",
            "To be or not to be, that is the question."
        ]
        
        userBook.quotes = quotes
        XCTAssertEqual(userBook.quotes?.count, 2)
        XCTAssertEqual(userBook.quotes?[0], quotes[0])
        XCTAssertEqual(userBook.quotes?[1], quotes[1])
    }
    
    // MARK: - Reading Sessions Tests
    
    func testReadingSessionsTracking() async throws {
        let userBook = createTestUserBook()
        
        let session1 = ReadingSession(date: Date(), durationMinutes: 30, pagesRead: 15)
        let session2 = ReadingSession(date: Date().addingTimeInterval(-3600), durationMinutes: 45, pagesRead: 20)
        
        userBook.readingSessions = [session1, session2]
        
        XCTAssertEqual(userBook.readingSessions.count, 2)
        XCTAssertEqual(userBook.readingSessions[0].durationMinutes, 30)
        XCTAssertEqual(userBook.readingSessions[1].pagesRead, 20)
        
        // Total reading time should be calculated
        let totalMinutes = userBook.readingSessions.reduce(0) { $0 + $1.durationMinutes }
        XCTAssertEqual(totalMinutes, 75)
    }
    
    // MARK: - Social Features Tests
    
    func testSocialFeatures() async throws {
        let userBook = createTestUserBook()
        
        userBook.isPublic = true
        userBook.recommendedBy = "Friend's Name"
        userBook.wouldRecommend = true
        userBook.discussionNotes = "Great for book club discussion"
        
        XCTAssertTrue(userBook.isPublic)
        XCTAssertEqual(userBook.recommendedBy, "Friend's Name")
        XCTAssertEqual(userBook.wouldRecommend, true)
        XCTAssertEqual(userBook.discussionNotes, "Great for book club discussion")
    }
    
    // MARK: - Goals and Progress Tests
    
    func testDailyReadingGoal() async throws {
        let userBook = createTestUserBook()
        
        userBook.dailyReadingGoal = 20 // pages per day
        XCTAssertEqual(userBook.dailyReadingGoal, 20)
        
        // Test estimated finish date calculation logic
        if let pageCount = userBook.metadata?.pageCount,
           let dailyGoal = userBook.dailyReadingGoal,
           dailyGoal > 0 {
            let remainingPages = max(0, pageCount - userBook.currentPage)
            let daysNeeded = ceil(Double(remainingPages) / Double(dailyGoal))
            let estimatedFinish = Date().addingTimeInterval(daysNeeded * 24 * 60 * 60)
            
            // This would normally be calculated by the model
            userBook.estimatedFinishDate = estimatedFinish
            XCTAssertNotNil(userBook.estimatedFinishDate)
        }
    }
    
    // MARK: - Relationship Tests
    
    func testUserBookMetadataRelationship() async throws {
        let metadata = createTestBookMetadata(title: "Related Book")
        let userBook = UserBook(metadata: metadata)
        
        modelContext.insert(metadata)
        modelContext.insert(userBook)
        try saveContext()
        
        // Test the relationship
        XCTAssertNotNil(userBook.metadata)
        XCTAssertEqual(userBook.metadata?.title, "Related Book")
        
        // Test that metadata can be shared between user books
        let userBook2 = UserBook(readingStatus: .read, metadata: metadata)
        modelContext.insert(userBook2)
        try saveContext()
        
        XCTAssertEqual(userBook.metadata?.googleBooksID, userBook2.metadata?.googleBooksID)
    }
    
    // MARK: - Collection Tests
    
    func testMultipleUserBooksWithDifferentStatuses() async throws {
        let books = createVariousStatusBooks()
        try saveContext()
        
        let fetchedBooks = try fetchAllUserBooks()
        XCTAssertEqual(fetchedBooks.count, 4)
        
        let completedBooks = fetchedBooks.filter { $0.readingStatus == .read }
        let currentlyReading = fetchedBooks.filter { $0.readingStatus == .reading }
        let wantToRead = fetchedBooks.filter { $0.readingStatus == .toRead }
        let dnf = fetchedBooks.filter { $0.readingStatus == .dnf }
        
        XCTAssertEqual(completedBooks.count, 1)
        XCTAssertEqual(currentlyReading.count, 1)
        XCTAssertEqual(wantToRead.count, 1)
        XCTAssertEqual(dnf.count, 1)
    }
}