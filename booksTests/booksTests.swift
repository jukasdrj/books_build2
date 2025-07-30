import Testing
import SwiftData
@testable import books

@Suite("Basic Books App Tests")
struct booksTests {

    @Test("UserBook and BookMetadata Models - Should work together")
    func testBasicModelIntegration() throws {
        // CORRECTED: The initializer now correctly matches the full BookMetadata model.
        let metadata = BookMetadata(
            googleBooksID: "basic-test-123",
            title: "Basic Test Book",
            authors: ["Basic Author"]
        )
        
        let userBook = UserBook(readingStatus: .toRead)
        userBook.metadata = metadata
        
        #expect(userBook.metadata === metadata)
        #expect(userBook.readingStatus == .toRead)
        #expect(metadata.title == "Basic Test Book")
        #expect(metadata.id == "basic-test-123", "BookMetadata should be Identifiable with googleBooksID as id")
    }
    
    @Test("ReadingStatus Enum - Should handle all cases")
    func testReadingStatusEnum() throws {
        let allCases = ReadingStatus.allCases
        #expect(allCases.count == 3)
        #expect(ReadingStatus.toRead.rawValue == "To Read")
        #expect(ReadingStatus.reading.rawValue == "Reading")
        #expect(ReadingStatus.read.rawValue == "Read")
    }
    
    @Test("UserBook Default Values - Should initialize correctly")
    func testUserBookDefaults() throws {
        let userBook = UserBook()
        #expect(userBook.readingStatus == .toRead)
        #expect(userBook.isFavorited == false)
        #expect(userBook.rating == nil)
        #expect(userBook.notes == nil)
    }
}