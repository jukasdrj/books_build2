//
// UPDATED: booksTests/booksTests.swift
//
import Testing
import SwiftData
import SwiftUI
@testable import books

@Suite("Integration Tests")
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
}
