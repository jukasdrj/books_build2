
//
//  ModelTests.swift
//  booksTests
//
//  Created by Justin Gardner on 8/8/25.
//

import Testing
import SwiftData
import SwiftUI
@testable import books

@Suite("Model Tests")
struct ModelTests {

    // MARK: - BookMetadata Tests

    @Test("BookMetadata Computed Properties - Should handle arrays correctly")
    func testBookMetadataComputedProperties() throws {
        let metadata = BookMetadata(googleBooksID: "test-id", title: "Test Book")

        // Test authors
        metadata.authors = [" Author 1 ", "Author 2"] 
        #expect(metadata.authors == ["Author 1", "Author 2"])

        // Test genre
        metadata.genre = ["  Fantasy  ", "Sci-Fi  "]
        #expect(metadata.genre == ["Fantasy", "Sci-Fi"])

        // Test cultural themes
        metadata.culturalThemes = ["Theme A", " Theme B "]
        #expect(metadata.culturalThemes == ["Theme A", "Theme B"])
        
        // Test content warnings
        metadata.contentWarnings = ["Warning 1", "Warning 2"]
        #expect(metadata.contentWarnings == ["Warning 1", "Warning 2"])
        
        // Test awards
        metadata.awards = ["Award 1 ", " Award 2"]
        #expect(metadata.awards == ["Award 1", "Award 2"])
    }

    @Test("BookMetadata Initializer - Should set properties correctly")
    func testBookMetadataInitializer() throws {
        let metadata = BookMetadata(
            googleBooksID: "init-test",
            title: "  Initializer Test  ",
            authors: ["  Author Name  "],
            genre: ["  Genre  "],
            culturalThemes: ["  Culture  "],
            contentWarnings: ["  Warning  "],
            awards: ["  Award  "]
        )

        #expect(metadata.title == "Initializer Test")
        #expect(metadata.authors == ["Author Name"])
        #expect(metadata.genre == ["Genre"])
        #expect(metadata.culturalThemes == ["Culture"])
        #expect(metadata.contentWarnings == ["Warning"])
        #expect(metadata.awards == ["Award"])
    }
    
    @Test("BookMetadata Hashable and Equatable - Should conform correctly")
    func testBookMetadataHashableEquatable() throws {
        let metadata1 = BookMetadata(googleBooksID: "same-id", title: "Book 1")
        let metadata2 = BookMetadata(googleBooksID: "same-id", title: "Book 2")
        let metadata3 = BookMetadata(googleBooksID: "different-id", title: "Book 3")
        
        #expect(metadata1 == metadata2)
        #expect(metadata1.hashValue == metadata2.hashValue)
        #expect(metadata1 != metadata3)
    }

    @Test("BookMetadata Validation - Should validate fields")
    func testBookMetadataValidation() throws {
        let validMetadata = BookMetadata(googleBooksID: "valid", title: "A Valid Title", authors: ["An Author"], pageCount: 100, genre: ["A Genre"])
        #expect(validMetadata.validateTitle())
        #expect(validMetadata.validateAuthors())
        #expect(validMetadata.validatePageCount())
        #expect(validMetadata.validateGenres())

        let invalidMetadata = BookMetadata(googleBooksID: "invalid", title: "", authors: [], pageCount: -10, genre: Array(repeating: "genre", count: 11))
        #expect(!invalidMetadata.validateTitle())
        #expect(!invalidMetadata.validateAuthors())
        #expect(!invalidMetadata.validatePageCount())
        #expect(!invalidMetadata.validateGenres())
    }

    // MARK: - ReadingStatus Tests

    @Test("ReadingStatus Enum - Should have correct raw values and count")
    func testReadingStatusEnum() throws {
        #expect(ReadingStatus.allCases.count == 5)
        #expect(ReadingStatus.toRead.rawValue == "TBR - To Be Read")
        #expect(ReadingStatus.reading.rawValue == "Reading")
        #expect(ReadingStatus.read.rawValue == "Read")
        #expect(ReadingStatus.onHold.rawValue == "On Hold")
        #expect(ReadingStatus.dnf.rawValue == "DNF - Did Not Finish")
    }

    // MARK: - UserBook Tests

    @Test("UserBook Default Initializer - Should set correct default values")
    func testUserBookDefaultInitializer() throws {
        let book = UserBook()
        #expect(book.readingStatus == .toRead)
        #expect(book.isFavorited == false)
        #expect(book.owned == true)
        #expect(book.onWishlist == false)
        #expect(book.rating == nil)
        #expect(book.notes == nil)
        #expect(book.currentPage == 0)
        #expect(book.readingProgress == 0.0)
        #expect(book.totalReadingTimeMinutes == 0)
        #expect(book.tags.isEmpty)
        #expect(book.quotes == nil)
        #expect(book.readingSessions.isEmpty)
    }

    @Test("UserBook Computed Properties - Should get and set correctly")
    func testUserBookComputedProperties() throws {
        let book = UserBook()

        // Test tags
        book.tags = ["  a tag  ", String(repeating: "t", count: 60), "another tag"]
        #expect(book.tags == ["a tag", String(repeating: "t", count: 50), "another tag"])
        #expect(book.tags.count == 3)
        book.tags = Array(repeating: "tag", count: 25)
        #expect(book.tags.count == 20)
        
        // Test quotes
        book.quotes = ["  a quote  ", "another quote"]
        #expect(book.quotes == ["a quote", "another quote"])

        // Test reading sessions
        let session = ReadingSession(date: Date(), durationMinutes: 30, pagesRead: 20)
        book.readingSessions = [session]
        #expect(book.readingSessions.count == 1)
        #expect(book.readingSessions.first?.id == session.id)
    }

    @Test("UserBook ReadingStatus didSet - Should update dates and progress")
    func testUserBookReadingStatusDidSet() throws {
        let metadata = BookMetadata(googleBooksID: "status-test", title: "Status Book", pageCount: 200)
        let book = UserBook(metadata: metadata)

        // Change to .reading
        book.readingStatus = .reading
        #expect(book.dateStarted != nil)

        // Change to .read
        book.readingStatus = .read
        #expect(book.dateCompleted != nil)
        #expect(book.readingProgress == 1.0)
        #expect(book.currentPage == 200)
    }

    @Test("UserBook UpdateReadingProgress - Should calculate correctly")
    func testUserBookUpdateReadingProgress() throws {
        let metadata = BookMetadata(googleBooksID: "progress-test", title: "Progress Book", pageCount: 400)
        let book = UserBook(metadata: metadata)

        book.currentPage = 100
        book.updateReadingProgress()
        #expect(book.readingProgress == 0.25)

        // Test auto-completion
        book.currentPage = 400
        book.updateReadingProgress()
        #expect(book.readingStatus == .read)
    }

    @Test("UserBook AddReadingSession - Should update properties")
    func testUserBookAddReadingSession() throws {
        let book = UserBook()
        book.addReadingSession(minutes: 45, pagesRead: 30)
        #expect(book.readingSessions.count == 1)
        #expect(book.totalReadingTimeMinutes == 45)
        #expect(book.currentPage == 30)
    }
    
    @Test("UserBook Validation - Should validate rating and notes")
    func testUserBookValidation() throws {
        let book = UserBook()

        // Test rating
        book.rating = 6
        #expect(book.rating == nil)
        book.rating = 0
        #expect(book.rating == nil)
        book.rating = 3
        #expect(book.rating == 3)

        // Test notes
        let longNote = String(repeating: "a", count: 5001)
        book.notes = longNote
        #expect(book.notes?.count == 5000)
    }

    // MARK: - ReadingSession Tests

    @Test("ReadingSession Codable - Should encode and decode correctly")
    func testReadingSessionCodable() throws {
        let session = ReadingSession(date: Date(), durationMinutes: 60, pagesRead: 50)
        let encoded = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(ReadingSession.self, from: encoded)
        
        #expect(decoded.id == session.id)
        #expect(decoded.durationMinutes == 60)
        #expect(decoded.pagesRead == 50)
    }

    @Test("ReadingSession pagesPerHour - Should calculate correctly")
    func testReadingSessionPagesPerHour() throws {
        let session1 = ReadingSession(date: Date(), durationMinutes: 60, pagesRead: 50)
        #expect(session1.pagesPerHour == 50.0)
        
        let session2 = ReadingSession(date: Date(), durationMinutes: 30, pagesRead: 30)
        #expect(session2.pagesPerHour == 60.0)
        
        let session3 = ReadingSession(date: Date(), durationMinutes: 0, pagesRead: 10)
        #expect(session3.pagesPerHour == 0)
    }

    // MARK: - ImportModels Tests

    @Test("CSVImportSession isValidGoodreadsFormat - Should detect correctly")
    func testCSVImportSessionIsValidGoodreadsFormat() throws {
        let validColumns = [CSVColumn(originalName: "Title", index: 0, sampleValues: []), CSVColumn(originalName: "Author", index: 1, sampleValues: [])]
        let invalidColumns = [CSVColumn(originalName: "Book Name", index: 0, sampleValues: []), CSVColumn(originalName: "Writer", index: 1, sampleValues: [])]

        let validSession = CSVImportSession(fileName: "goodreads.csv", fileSize: 1024, totalRows: 1, detectedColumns: validColumns, sampleData: [[]])
        let invalidSession = CSVImportSession(fileName: "not_goodreads.csv", fileSize: 1024, totalRows: 1, detectedColumns: invalidColumns, sampleData: [[]])

        #expect(validSession.isValidGoodreadsFormat)
        #expect(!invalidSession.isValidGoodreadsFormat)
    }

    @Test("ParsedBook Validation - Should validate correctly")
    func testParsedBookValidation() throws {
        var validBook = ParsedBook(rowIndex: 0, title: "A Book", author: "An Author", pageCount: 150, rating: 4)
        #expect(validBook.isValid)
        #expect(validBook.validationErrors.isEmpty)

        var invalidBook = ParsedBook(rowIndex: 1, title: " ", author: nil, pageCount: -5, rating: 6)
        #expect(!invalidBook.isValid)
        #expect(invalidBook.validationErrors.contains("Missing title"))
        #expect(invalidBook.validationErrors.contains("Missing author"))
        #expect(invalidBook.validationErrors.contains("Invalid rating (must be 1-5)"))
        #expect(invalidBook.validationErrors.contains("Invalid page count"))
    }

    @Test("GoodreadsColumnMappings autoMap - Should map columns")
    func testGoodreadsColumnMappingsAutoMap() throws {
        let columns = ["Title", "Author", "My Rating", "Date Read"]
        let mappings = GoodreadsColumnMappings.autoMap(columns: columns)

        #expect(mappings["Title"] == .title)
        #expect(mappings["Author"] == .author)
        #expect(mappings["My Rating"] == .rating)
        #expect(mappings["Date Read"] == .dateRead)
    }

    @Test("GoodreadsColumnMappings mapReadingStatus - Should map statuses")
    func testGoodreadsColumnMappingsMapReadingStatus() throws {
        #expect(GoodreadsColumnMappings.mapReadingStatus("read") == .read)
        #expect(GoodreadsColumnMappings.mapReadingStatus("currently-reading") == .reading)
        #expect(GoodreadsColumnMappings.mapReadingStatus("to-read") == .toRead)
        #expect(GoodreadsColumnMappings.mapReadingStatus("did not finish") == .dnf)
        #expect(GoodreadsColumnMappings.mapReadingStatus("unknown-status") == .toRead)
    }
}
