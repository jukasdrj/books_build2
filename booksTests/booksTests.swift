//
// UPDATED: booksTests/booksTests.swift
//
import Testing
import SwiftData
import SwiftUI
@testable import books

@Suite("Basic Books App Tests")
struct booksTests {

    @Test("UserBook and BookMetadata Models - Should work together")
    func testBasicModelIntegration() throws {
        let metadata = BookMetadata(
            googleBooksID: "basic-test-123",
            title: "Basic Test Book",
            authors: ["Basic Author"]
        )
        
        let userBook = UserBook(readingStatus: .toRead, metadata: metadata)
        
        #expect(userBook.metadata === metadata)
        #expect(userBook.readingStatus == .toRead)
        #expect(metadata.title == "Basic Test Book")
        #expect(metadata.id == "basic-test-123", "BookMetadata should be Identifiable with googleBooksID as id")
    }
    
    @Test("ReadingStatus Enum - Should handle all cases")
    func testReadingStatusEnum() throws {
        let allCases = ReadingStatus.allCases
        #expect(allCases.count == 5)
        #expect(ReadingStatus.toRead.rawValue == "TBR - To Be Read")
        #expect(ReadingStatus.reading.rawValue == "Reading")
        #expect(ReadingStatus.read.rawValue == "Read")
        #expect(ReadingStatus.onHold.rawValue == "On Hold")
        #expect(ReadingStatus.dnf.rawValue == "DNF - Did Not Finish")
    }
    
    @Test("UserBook Default Values - Should initialize correctly")
    func testUserBookDefaults() throws {
        let userBook = UserBook()
        #expect(userBook.readingStatus == .toRead)
        #expect(userBook.isFavorited == false)
        #expect(userBook.owned == true) // Default is true
        #expect(userBook.onWishlist == false)
        #expect(userBook.rating == nil)
        #expect(userBook.notes == nil)
        #expect(userBook.currentPage == 0)
        #expect(userBook.readingProgress == 0.0)
        #expect(userBook.totalReadingTimeMinutes == 0)
        #expect(userBook.tags.isEmpty)
    }
    
    @Test("UserBook Reading Progress - Should calculate correctly")
    func testReadingProgressCalculation() throws {
        let metadata = BookMetadata(
            googleBooksID: "progress-test",
            title: "Progress Test Book",
            authors: ["Test Author"],
            pageCount: 200
        )
        
        let userBook = UserBook(metadata: metadata)
        userBook.currentPage = 50
        userBook.updateReadingProgress()
        
        #expect(userBook.readingProgress == 0.25, "Progress should be 25% for 50/200 pages")
    }
    
    @Test("UserBook Tags - Should handle array properly")
    func testUserBookTags() throws {
        let userBook = UserBook()
        userBook.tags = ["fiction", "sci-fi", "favorite"]
        
        #expect(userBook.tags.count == 3)
        #expect(userBook.tags.contains("fiction"))
        #expect(userBook.tags.contains("sci-fi"))
        #expect(userBook.tags.contains("favorite"))
    }
}