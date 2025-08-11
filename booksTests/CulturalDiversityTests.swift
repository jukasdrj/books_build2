import XCTest
import SwiftData
@testable import books

/// Tests for cultural diversity tracking features
@MainActor
final class CulturalDiversityTests: BookTrackerTestSuite {
    
    // MARK: - Cultural Region Distribution Tests
    
    func testCulturalRegionTracking() async throws {
        let diverseBooks = createDiverseBookCollection()
        try saveContext()
        
        // Verify each region is represented
        let africaBooks = diverseBooks.filter { $0.metadata?.culturalRegion == .africa }
        let southAmericaBooks = diverseBooks.filter { $0.metadata?.culturalRegion == .southAmerica }
        let asiaBooks = diverseBooks.filter { $0.metadata?.culturalRegion == .asia }
        let europeBooks = diverseBooks.filter { $0.metadata?.culturalRegion == .europe }
        let northAmericaBooks = diverseBooks.filter { $0.metadata?.culturalRegion == .northAmerica }
        
        XCTAssertEqual(africaBooks.count, 1, "Should have 1 African book")
        XCTAssertEqual(southAmericaBooks.count, 1, "Should have 1 South American book")
        XCTAssertEqual(asiaBooks.count, 1, "Should have 1 Asian book")
        XCTAssertEqual(europeBooks.count, 1, "Should have 1 European book")
        XCTAssertEqual(northAmericaBooks.count, 1, "Should have 1 North American book")
        
        // Test specific cultural regions
        XCTAssertEqual(africaBooks.first?.metadata?.title, "Things Fall Apart")
        XCTAssertEqual(africaBooks.first?.metadata?.authors.first, "Chinua Achebe")
    }
    
    func testCulturalGoalContribution() async throws {
        let africanBook = createTestUserBook(
            title: "Half of a Yellow Sun",
            author: "Chimamanda Ngozi Adichie",
            culturalRegion: .africa
        )
        
        africanBook.contributesToCulturalGoal = true
        africanBook.culturalGoalCategory = "African Literature"
        
        try saveContext()
        
        let fetchedBooks = try fetchAllUserBooks()
        let culturalBooks = fetchedBooks.filter { $0.contributesToCulturalGoal }
        
        XCTAssertEqual(culturalBooks.count, 1)
        XCTAssertEqual(culturalBooks.first?.culturalGoalCategory, "African Literature")
        XCTAssertEqual(culturalBooks.first?.metadata?.culturalRegion, .africa)
    }
    
    // MARK: - Author Diversity Tests
    
    func testAuthorNationalityTracking() async throws {
        let nigerianBook = createTestBookMetadata(
            title: "Purple Hibiscus",
            authors: ["Chimamanda Ngozi Adichie"],
            culturalRegion: .africa,
            authorNationality: "Nigerian"
        )
        
        let japaneseBook = createTestBookMetadata(
            title: "The Tale of Genji",
            authors: ["Murasaki Shikibu"],
            culturalRegion: .asia,
            authorNationality: "Japanese"
        )
        
        try saveContext()
        
        let allMetadata = try fetchAllBookMetadata()
        let nationalityMap = Dictionary(grouping: allMetadata) { $0.authorNationality }
        
        XCTAssertNotNil(nationalityMap["Nigerian"])
        XCTAssertNotNil(nationalityMap["Japanese"])
        XCTAssertEqual(nationalityMap["Nigerian"]?.count, 1)
        XCTAssertEqual(nationalityMap["Japanese"]?.count, 1)
    }
    
    func testAuthorGenderTracking() async throws {
        let femaleAuthorBook = createTestBookMetadata(
            title: "The Handmaid's Tale",
            authors: ["Margaret Atwood"]
        )
        femaleAuthorBook.authorGender = .female
        
        let maleAuthorBook = createTestBookMetadata(
            title: "1984",
            authors: ["George Orwell"]
        )
        maleAuthorBook.authorGender = .male
        
        let nonBinaryAuthorBook = createTestBookMetadata(
            title: "Pet",
            authors: ["Akwaeke Emezi"]
        )
        nonBinaryAuthorBook.authorGender = .nonBinary
        
        try saveContext()
        
        let allMetadata = try fetchAllBookMetadata()
        let femaleAuthors = allMetadata.filter { $0.authorGender == .female }
        let maleAuthors = allMetadata.filter { $0.authorGender == .male }
        let nonBinaryAuthors = allMetadata.filter { $0.authorGender == .nonBinary }
        
        XCTAssertEqual(femaleAuthors.count, 1)
        XCTAssertEqual(maleAuthors.count, 1)
        XCTAssertEqual(nonBinaryAuthors.count, 1)
    }
    
    // MARK: - Language and Translation Tests
    
    func testOriginalLanguageTracking() async throws {
        let spanishOriginal = createTestBookMetadata(
            title: "One Hundred Years of Solitude",
            authors: ["Gabriel García Márquez"],
            originalLanguage: "Spanish"
        )
        
        let frenchOriginal = createTestBookMetadata(
            title: "The Stranger",
            authors: ["Albert Camus"],
            originalLanguage: "French"
        )
        
        try saveContext()
        
        let allMetadata = try fetchAllBookMetadata()
        let translatedBooks = allMetadata.filter { $0.originalLanguage != nil && $0.originalLanguage != "English" }
        
        XCTAssertEqual(translatedBooks.count, 2)
        
        let spanishBooks = allMetadata.filter { $0.originalLanguage == "Spanish" }
        let frenchBooks = allMetadata.filter { $0.originalLanguage == "French" }
        
        XCTAssertEqual(spanishBooks.count, 1)
        XCTAssertEqual(frenchBooks.count, 1)
    }
    
    func testTranslatorTracking() async throws {
        let translatedBook = createTestBookMetadata(
            title: "The Metamorphosis",
            authors: ["Franz Kafka"],
            originalLanguage: "German"
        )
        translatedBook.translator = "David Wyllie"
        translatedBook.translatorNationality = "British"
        
        try saveContext()
        
        let allMetadata = try fetchAllBookMetadata()
        let booksWithTranslators = allMetadata.filter { $0.translator != nil }
        
        XCTAssertEqual(booksWithTranslators.count, 1)
        XCTAssertEqual(booksWithTranslators.first?.translator, "David Wyllie")
        XCTAssertEqual(booksWithTranslators.first?.translatorNationality, "British")
    }
    
    // MARK: - Cultural Themes Tests
    
    func testCulturalThemesTracking() async throws {
        let culturalBook = createTestBookMetadata(
            title: "Persepolis",
            authors: ["Marjane Satrapi"],
            culturalRegion: .middleEast
        )
        culturalBook.culturalThemes = ["Immigration", "Identity", "Political Oppression", "Coming of Age"]
        
        try saveContext()
        
        let allMetadata = try fetchAllBookMetadata()
        let booksWithCulturalThemes = allMetadata.filter { !$0.culturalThemes.isEmpty }
        
        XCTAssertEqual(booksWithCulturalThemes.count, 1)
        XCTAssertTrue(booksWithCulturalThemes.first?.culturalThemes.contains("Immigration") == true)
        XCTAssertTrue(booksWithCulturalThemes.first?.culturalThemes.contains("Identity") == true)
        XCTAssertEqual(booksWithCulturalThemes.first?.culturalThemes.count, 4)
    }
    
    // MARK: - Marginalized Voices Tests
    
    func testIndigenousAuthorTracking() async throws {
        let indigenousBook = createTestBookMetadata(
            title: "There There",
            authors: ["Tommy Orange"],
            culturalRegion: .northAmerica
        )
        indigenousBook.indigenousAuthor = true
        indigenousBook.authorEthnicity = "Cheyenne and Arapaho"
        
        try saveContext()
        
        let allMetadata = try fetchAllBookMetadata()
        let indigenousBooks = allMetadata.filter { $0.indigenousAuthor }
        
        XCTAssertEqual(indigenousBooks.count, 1)
        XCTAssertEqual(indigenousBooks.first?.authorEthnicity, "Cheyenne and Arapaho")
    }
    
    func testMarginalizedVoiceTracking() async throws {
        let marginalizedVoiceBook = createTestBookMetadata(
            title: "The Water Will Come",
            authors: ["Jeff Goodell"]
        )
        marginalizedVoiceBook.marginalizedVoice = true
        
        try saveContext()
        
        let allMetadata = try fetchAllBookMetadata()
        let marginalizedVoiceBooks = allMetadata.filter { $0.marginalizedVoice }
        
        XCTAssertEqual(marginalizedVoiceBooks.count, 1)
    }
    
    // MARK: - Cultural Statistics Tests
    
    func testCulturalDiversityStatistics() async throws {
        let diverseBooks = createDiverseBookCollection()
        try saveContext()
        
        let allBooks = try fetchAllUserBooks()
        let totalBooks = allBooks.count
        
        // Calculate regional distribution
        let regionCounts = Dictionary(grouping: allBooks) { $0.metadata?.culturalRegion }
            .mapValues { $0.count }
        
        // Test diversity metrics
        let representedRegions = regionCounts.keys.compactMap { $0 }.count
        let diversityScore = Double(representedRegions) / Double(CulturalRegion.allCases.count)
        
        XCTAssertEqual(totalBooks, 5)
        XCTAssertEqual(representedRegions, 5, "Should have 5 different regions represented")
        XCTAssertGreaterThan(diversityScore, 0.5, "Diversity score should be greater than 50%")
        
        // Verify no single region dominates
        let maxRegionCount = regionCounts.values.max() ?? 0
        let dominanceRatio = Double(maxRegionCount) / Double(totalBooks)
        XCTAssertLessThanOrEqual(dominanceRatio, 0.5, "No single region should dominate more than 50%")
    }
    
    // MARK: - Cultural Goal Progress Tests
    
    func testCulturalGoalProgress() async throws {
        // Create books with cultural goal contributions
        let book1 = createTestUserBook(title: "Book 1", culturalRegion: .africa)
        book1.contributesToCulturalGoal = true
        book1.readingStatus = .read
        
        let book2 = createTestUserBook(title: "Book 2", culturalRegion: .asia)
        book2.contributesToCulturalGoal = true
        book2.readingStatus = .reading
        
        let book3 = createTestUserBook(title: "Book 3", culturalRegion: .europe)
        book3.contributesToCulturalGoal = false
        book3.readingStatus = .read
        
        try saveContext()
        
        let allBooks = try fetchAllUserBooks()
        let culturalGoalBooks = allBooks.filter { $0.contributesToCulturalGoal }
        let completedCulturalBooks = culturalGoalBooks.filter { $0.readingStatus == .read }
        
        XCTAssertEqual(culturalGoalBooks.count, 2)
        XCTAssertEqual(completedCulturalBooks.count, 1)
        
        // Calculate progress toward cultural diversity goal
        let goalProgress = Double(completedCulturalBooks.count) / Double(culturalGoalBooks.count)
        XCTAssertEqual(goalProgress, 0.5, accuracy: 0.01)
    }
    
    // MARK: - Content Warning Tests
    
    func testContentWarnings() async throws {
        let bookWithWarnings = createTestBookMetadata(
            title: "Sensitive Content Book",
            authors: ["Author Name"]
        )
        bookWithWarnings.contentWarnings = ["Violence", "Sexual Content", "Drug Use"]
        
        try saveContext()
        
        let allMetadata = try fetchAllBookMetadata()
        let booksWithWarnings = allMetadata.filter { !$0.contentWarnings.isEmpty }
        
        XCTAssertEqual(booksWithWarnings.count, 1)
        XCTAssertEqual(booksWithWarnings.first?.contentWarnings.count, 3)
        XCTAssertTrue(booksWithWarnings.first?.contentWarnings.contains("Violence") == true)
    }
    
    // MARK: - Award Recognition Tests
    
    func testAwardTracking() async throws {
        let awardWinningBook = createTestBookMetadata(
            title: "Award Winner",
            authors: ["Celebrated Author"]
        )
        awardWinningBook.awards = ["Pulitzer Prize", "National Book Award", "Hugo Award"]
        
        try saveContext()
        
        let allMetadata = try fetchAllBookMetadata()
        let awardWinningBooks = allMetadata.filter { !$0.awards.isEmpty }
        
        XCTAssertEqual(awardWinningBooks.count, 1)
        XCTAssertEqual(awardWinningBooks.first?.awards.count, 3)
        XCTAssertTrue(awardWinningBooks.first?.awards.contains("Pulitzer Prize") == true)
    }
    
    // MARK: - Reading Difficulty and Accessibility Tests
    
    func testReadingDifficultyTracking() async throws {
        let beginnerBook = createTestBookMetadata(title: "Easy Read")
        beginnerBook.readingDifficulty = .beginner
        
        let intermediateBook = createTestBookMetadata(title: "Medium Read")
        intermediateBook.readingDifficulty = .intermediate
        
        let advancedBook = createTestBookMetadata(title: "Complex Read")
        advancedBook.readingDifficulty = .advanced
        
        try saveContext()
        
        let allMetadata = try fetchAllBookMetadata()
        let beginnerBooks = allMetadata.filter { $0.readingDifficulty == .beginner }
        let intermediateBooks = allMetadata.filter { $0.readingDifficulty == .intermediate }
        let advancedBooks = allMetadata.filter { $0.readingDifficulty == .advanced }
        
        XCTAssertEqual(beginnerBooks.count, 1)
        XCTAssertEqual(intermediateBooks.count, 1)
        XCTAssertEqual(advancedBooks.count, 1)
    }
    
    func testTimeToReadEstimation() async throws {
        let quickRead = createTestBookMetadata(title: "Quick Read")
        quickRead.timeToRead = 240 // 4 hours in minutes
        
        let longRead = createTestBookMetadata(title: "Long Read")
        longRead.timeToRead = 900 // 15 hours in minutes
        
        try saveContext()
        
        let allMetadata = try fetchAllBookMetadata()
        let booksWithTimeEstimates = allMetadata.filter { $0.timeToRead != nil }
        
        XCTAssertEqual(booksWithTimeEstimates.count, 2)
        
        let quickBooks = booksWithTimeEstimates.filter { ($0.timeToRead ?? 0) <= 300 }
        let longBooks = booksWithTimeEstimates.filter { ($0.timeToRead ?? 0) > 600 }
        
        XCTAssertEqual(quickBooks.count, 1)
        XCTAssertEqual(longBooks.count, 1)
    }
}