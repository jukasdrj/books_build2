import XCTest
import SwiftData
@testable import books

/// Tests for Library Reset Feature with iOS-compliant destructive action flow
final class LibraryResetTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var resetService: LibraryResetService!
    var resetViewModel: LibraryResetViewModel!
    
    override func setUp() async throws {
        // Create in-memory container for testing
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(
            for: UserBook.self, BookMetadata.self,
            configurations: config
        )
        modelContext = await modelContainer.mainContext
        
        await MainActor.run {
            resetService = LibraryResetService(modelContext: modelContext)
            resetViewModel = LibraryResetViewModel(modelContext: modelContext)
        }
        
        // Add test data
        try await addTestData()
    }
    
    override func tearDown() async throws {
        resetService = nil
        resetViewModel = nil
        modelContext = nil
        modelContainer = nil
    }
    
    // MARK: - Helper Methods
    
    private func addTestData() async throws {
        let metadata1 = BookMetadata(
            googleBooksID: "test-id-1",
            title: "Test Book 1",
            authors: ["Author 1"],
            publishedDate: "2023",
            pageCount: 300,
            bookDescription: "Test description",
            language: "en",
            publisher: "Test Publisher",
            isbn: "1234567890",
            genre: ["Fiction"]
        )
        
        let metadata2 = BookMetadata(
            googleBooksID: "test-id-2",
            title: "Test Book 2",
            authors: ["Author 2"],
            publishedDate: "2024",
            pageCount: 250,
            bookDescription: "Another test",
            language: "en",
            publisher: "Another Publisher",
            isbn: "0987654321",
            genre: ["Non-fiction"]
        )
        
        let book1 = UserBook(
            readingStatus: .reading,
            rating: 4,
            notes: "Great book!",
            tags: ["favorite", "2024"],
            metadata: metadata1
        )
        
        let book2 = UserBook(
            readingStatus: .toRead,
            metadata: metadata2
        )
        
        modelContext.insert(metadata1)
        modelContext.insert(metadata2)
        modelContext.insert(book1)
        modelContext.insert(book2)
        
        try modelContext.save()
    }
    
    // MARK: - Reset Service Tests
    
    func testCountItemsToDelete() async {
        await resetService.countItemsToDelete()
        
        await MainActor.run {
            XCTAssertEqual(resetService.booksToDelete, 2)
            XCTAssertEqual(resetService.metadataToDelete, 2)
        }
    }
    
    func testExportToCSV() async throws {
        await MainActor.run {
            _ = Task {
                do {
                    let exportURL = try await resetService.exportLibraryData(format: .csv)
                    
                    // Verify file exists
                    XCTAssertTrue(FileManager.default.fileExists(atPath: exportURL.path))
                    
                    // Read and verify content
                    let csvContent = try String(contentsOf: exportURL, encoding: .utf8)
                    XCTAssertTrue(csvContent.contains("Test Book 1"))
                    XCTAssertTrue(csvContent.contains("Test Book 2"))
                    XCTAssertTrue(csvContent.contains("Author 1"))
                    XCTAssertTrue(csvContent.contains("Author 2"))
                    XCTAssertTrue(csvContent.contains("1234567890"))
                    
                    // Clean up
                    try? FileManager.default.removeItem(at: exportURL)
                } catch {
                    XCTFail("Export failed: \(error)")
                }
            }
        }
    }
    
    func testExportToJSON() async throws {
        await MainActor.run {
            _ = Task {
                do {
                    let exportURL = try await resetService.exportLibraryData(format: .json)
                    
                    // Verify file exists
                    XCTAssertTrue(FileManager.default.fileExists(atPath: exportURL.path))
                    
                    // Read and verify JSON structure
                    let jsonData = try Data(contentsOf: exportURL)
                    let books = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]]
                    
                    XCTAssertEqual(books?.count, 2)
                    XCTAssertEqual(books?[0]["title"] as? String, "Test Book 1")
                    XCTAssertEqual(books?[1]["title"] as? String, "Test Book 2")
                    
                    // Clean up
                    try? FileManager.default.removeItem(at: exportURL)
                } catch {
                    XCTFail("JSON export failed: \(error)")
                }
            }
        }
    }
    
    func testResetLibrary() async throws {
        await MainActor.run {
            _ = Task {
                // Count before reset
                await resetService.countItemsToDelete()
                let initialBooks = resetService.booksToDelete
                let initialMetadata = resetService.metadataToDelete
                
                XCTAssertGreaterThan(initialBooks, 0)
                XCTAssertGreaterThan(initialMetadata, 0)
                
                // Perform reset
                do {
                    try await resetService.resetLibrary()
                    
                    // Verify all data deleted
                    let booksDescriptor = FetchDescriptor<UserBook>()
                    let remainingBooks = try modelContext.fetch(booksDescriptor)
                    XCTAssertEqual(remainingBooks.count, 0)
                    
                    let metadataDescriptor = FetchDescriptor<BookMetadata>()
                    let remainingMetadata = try modelContext.fetch(metadataDescriptor)
                    XCTAssertEqual(remainingMetadata.count, 0)
                    
                    // Verify state
                    if case .completed = resetService.resetState {
                        // Success
                    } else {
                        XCTFail("Reset should be in completed state")
                    }
                } catch {
                    XCTFail("Reset failed: \(error)")
                }
            }
        }
    }
    
    func testExportProgress() async {
        await MainActor.run {
            _ = Task {
                // Start export
                _ = try? await resetService.exportLibraryData(format: .csv)
                
                // Progress should be complete
                XCTAssertEqual(resetService.exportProgress, 1.0)
            }
        }
    }
    
    // MARK: - View Model Tests
    
    func testConfirmationSteps() async {
        await MainActor.run {
            // Initial state
            XCTAssertEqual(resetViewModel.currentStep, .initial)
            
            // Progress through steps
            _ = Task {
                await resetViewModel.proceedToNextStep()
                XCTAssertEqual(resetViewModel.currentStep, .warning)
                
                await resetViewModel.proceedToNextStep()
                XCTAssertEqual(resetViewModel.currentStep, .typeToConfirm)
                
                // Can't proceed without correct text
                await resetViewModel.proceedToNextStep()
                XCTAssertEqual(resetViewModel.currentStep, .typeToConfirm)
                
                // Enter correct text
                resetViewModel.confirmationText = "RESET"
                await resetViewModel.proceedToNextStep()
                XCTAssertEqual(resetViewModel.currentStep, .holdToConfirm)
            }
        }
    }
    
    func testTypeToConfirmValidation() async {
        await MainActor.run {
            // Test case insensitive matching
            resetViewModel.confirmationText = "reset"
            XCTAssertTrue(resetViewModel.canProceedFromTypeConfirm)
            
            resetViewModel.confirmationText = "RESET"
            XCTAssertTrue(resetViewModel.canProceedFromTypeConfirm)
            
            resetViewModel.confirmationText = "ReSEt"
            XCTAssertTrue(resetViewModel.canProceedFromTypeConfirm)
            
            // Test invalid text
            resetViewModel.confirmationText = "DELETE"
            XCTAssertFalse(resetViewModel.canProceedFromTypeConfirm)
            
            resetViewModel.confirmationText = ""
            XCTAssertFalse(resetViewModel.canProceedFromTypeConfirm)
        }
    }
    
    func testGoBackToPreviousStep() async {
        await MainActor.run {
            resetViewModel.currentStep = .finalConfirmation
            
            _ = Task {
                await resetViewModel.goBackToPreviousStep()
                XCTAssertEqual(resetViewModel.currentStep, .holdToConfirm)
                
                await resetViewModel.goBackToPreviousStep()
                XCTAssertEqual(resetViewModel.currentStep, .typeToConfirm)
                
                await resetViewModel.goBackToPreviousStep()
                XCTAssertEqual(resetViewModel.currentStep, .warning)
                
                await resetViewModel.goBackToPreviousStep()
                XCTAssertEqual(resetViewModel.currentStep, .initial)
            }
        }
    }
    
    func testCancelReset() async {
        await MainActor.run {
            // Set up state
            resetViewModel.currentStep = .typeToConfirm
            resetViewModel.confirmationText = "RESET"
            resetViewModel.holdProgress = 0.5
            resetViewModel.exportCompleted = true
            
            // Cancel
            resetViewModel.cancel()
            
            // Verify reset to initial state
            XCTAssertFalse(resetViewModel.showingResetSheet)
            XCTAssertEqual(resetViewModel.currentStep, .initial)
            XCTAssertEqual(resetViewModel.confirmationText, "")
            XCTAssertEqual(resetViewModel.holdProgress, 0.0)
            XCTAssertFalse(resetViewModel.exportCompleted)
        }
    }
    
    func testHoldToConfirmMechanism() async {
        // Start hold
        await resetViewModel.startHoldToConfirm()
        await MainActor.run {
            XCTAssertTrue(resetViewModel.isHoldingButton)
            XCTAssertEqual(resetViewModel.holdProgress, 0.0)
        }
        
        // Stop hold before completion
        await resetViewModel.stopHoldToConfirm()
        await MainActor.run {
            XCTAssertFalse(resetViewModel.isHoldingButton)
        }
        
        // Progress should reset if not completed
        let expectation = XCTestExpectation(description: "Hold progress reset")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            XCTAssertEqual(self.resetViewModel.holdProgress, 0.0)
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testItemsToDeleteDescription() async {
        await MainActor.run {
            _ = Task {
                await resetService.countItemsToDelete()
                
                let description = resetViewModel.itemsToDeleteDescription
                XCTAssertTrue(description.contains("2 books"))
                XCTAssertTrue(description.contains("2 metadata entries"))
            }
        }
    }
    
    func testEmptyLibraryDescription() async {
        // Clear all data first
        let booksDescriptor = FetchDescriptor<UserBook>()
        let books = try! modelContext.fetch(booksDescriptor)
        for book in books {
            modelContext.delete(book)
        }
        
        let metadataDescriptor = FetchDescriptor<BookMetadata>()
        let metadata = try! modelContext.fetch(metadataDescriptor)
        for meta in metadata {
            modelContext.delete(meta)
        }
        
        try! modelContext.save()
        
        await MainActor.run {
            // Create new service with empty context
            let emptyResetService = LibraryResetService(modelContext: modelContext)
            let emptyViewModel = LibraryResetViewModel(modelContext: modelContext)
            
            _ = Task {
                await emptyResetService.countItemsToDelete()
                
                let description = emptyViewModel.itemsToDeleteDescription
                XCTAssertEqual(description, "Your library is already empty")
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testResetDuringExport() async {
        await MainActor.run {
            _ = Task {
                // Start export
                let exportTask = Task {
                    try await resetService.exportLibraryData(format: .csv)
                }
                
                // Immediately try to reset
                do {
                    try await resetService.resetLibrary()
                    
                    // Should complete successfully
                    if case .completed = resetService.resetState {
                        // Success
                    } else {
                        XCTFail("Reset should complete even if export is running")
                    }
                } catch {
                    XCTFail("Reset failed: \(error)")
                }
                
                // Clean up export task
                _ = try? await exportTask.value
            }
        }
    }
    
    func testCSVEscaping() async {
        // Add book with special characters
        let specialMetadata = BookMetadata(
            googleBooksID: "special-id",
            title: "Book with, comma",
            authors: ["Author \"Quoted\""],
            bookDescription: "Special test book"
        )
        
        let specialBook = UserBook(
            readingStatus: .reading,
            notes: "Notes with\nnewline",
            metadata: specialMetadata
        )
        modelContext.insert(specialMetadata)
        modelContext.insert(specialBook)
        try! modelContext.save()
        
        await MainActor.run {
            _ = Task {
                do {
                    let exportURL = try await resetService.exportLibraryData(format: .csv)
                    let csvContent = try String(contentsOf: exportURL, encoding: .utf8)
                    
                    // Verify proper escaping
                    XCTAssertTrue(csvContent.contains("\"Book with, comma\""))
                    XCTAssertTrue(csvContent.contains("\"Author \"\"Quoted\"\"\""))
                    XCTAssertTrue(csvContent.contains("\"Notes with\nnewline\""))
                    
                    // Clean up
                    try? FileManager.default.removeItem(at: exportURL)
                } catch {
                    XCTFail("Export with special characters failed: \(error)")
                }
            }
        }
    }
}