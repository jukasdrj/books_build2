import Foundation
import SwiftData
import SwiftUI

/// Service for managing library reset operations with iOS-compliant safety measures
@MainActor
class LibraryResetService: ObservableObject {
    
    // MARK: - Reset State
    
    enum ResetState {
        case idle
        case confirmingReset
        case exportingData
        case resetting
        case completed
        case failed(Error)
    }
    
    // MARK: - Export Format
    
    enum ExportFormat {
        case csv
        case json
    }
    
    // MARK: - Test Compatibility Typealiases
    
    /// Test compatibility typealias
    typealias LibraryResetState = ResetState
    
    /// Test compatibility typealias
    typealias LibraryExportFormat = ExportFormat
    
    // MARK: - Properties
    
    @Published private(set) var resetState: ResetState = .idle
    @Published private(set) var exportProgress: Double = 0.0
    @Published private(set) var exportedFileURL: URL?
    @Published private(set) var booksToDelete: Int = 0
    @Published private(set) var metadataToDelete: Int = 0
    
    private let modelContext: ModelContext
    private let imageCache: ImageCache
    private let hapticManager = HapticFeedbackManager.shared
    
    // MARK: - Initialization
    
    init(modelContext: ModelContext, imageCache: ImageCache = ImageCache.shared) {
        self.modelContext = modelContext
        self.imageCache = imageCache
    }
    
    // MARK: - Public Interface
    
    /// Count items that will be deleted
    func countItemsToDelete() async {
        do {
            // Count UserBooks
            let userBookDescriptor = FetchDescriptor<UserBook>()
            let userBooks = try modelContext.fetch(userBookDescriptor)
            booksToDelete = userBooks.count
            
            // Count BookMetadata
            let metadataDescriptor = FetchDescriptor<BookMetadata>()
            let metadata = try modelContext.fetch(metadataDescriptor)
            metadataToDelete = metadata.count
            
            print("[LibraryResetService] Items to delete - Books: \(booksToDelete), Metadata: \(metadataToDelete)")
        } catch {
            print("[LibraryResetService] Error counting items: \(error)")
            booksToDelete = 0
            metadataToDelete = 0
        }
    }
    
    /// Export library data before reset
    func exportLibraryData(format: ExportFormat = .csv) async throws -> URL {
        resetState = .exportingData
        exportProgress = 0.0
        
        do {
            // Fetch all user books
            let descriptor = FetchDescriptor<UserBook>(
                sortBy: [SortDescriptor<UserBook>(\.dateAdded, order: .forward)]
            )
            let userBooks = try modelContext.fetch(descriptor)
            
            // Generate export file
            let exportURL: URL
            switch format {
            case .csv:
                exportURL = try await exportToCSV(userBooks: userBooks)
            case .json:
                exportURL = try await exportToJSON(userBooks: userBooks)
            }
            
            exportedFileURL = exportURL
            exportProgress = 1.0
            
            print("[LibraryResetService] Exported \(userBooks.count) books to: \(exportURL.lastPathComponent)")
            return exportURL
            
        } catch {
            resetState = .failed(error)
            throw error
        }
    }
    
    /// Perform the actual library reset
    func resetLibrary() async throws {
        resetState = .resetting
        
        do {
            // Haptic feedback for destructive action
            await hapticManager.destructiveAction()
            
            // 0. Cancel and clean up any active imports
            await cleanupActiveImports()
            
            // 1. Delete all UserBooks
            let userBookDescriptor = FetchDescriptor<UserBook>()
            let userBooks = try modelContext.fetch(userBookDescriptor)
            for book in userBooks {
                modelContext.delete(book)
            }
            
            // 2. Delete all BookMetadata
            let metadataDescriptor = FetchDescriptor<BookMetadata>()
            let metadata = try modelContext.fetch(metadataDescriptor)
            for meta in metadata {
                modelContext.delete(meta)
            }
            
            // 3. Save context
            try modelContext.save()
            
            // 4. Clear image cache
            imageCache.clear()
            
            // 5. Clear UserDefaults for app preferences (except theme)
            clearUserDefaults()
            
            // 6. Clear temporary files
            clearTemporaryFiles()
            
            resetState = .completed
            
            // Success haptic
            await hapticManager.success()
            
            print("[LibraryResetService] Library reset completed successfully")
            
        } catch {
            resetState = .failed(error)
            await hapticManager.error()
            throw error
        }
    }
    
    /// Cancel reset operation
    func cancelReset() {
        resetState = .idle
        exportProgress = 0.0
        exportedFileURL = nil
    }
    
    /// Reset to idle state
    func resetToIdle() {
        resetState = .idle
        exportProgress = 0.0
        exportedFileURL = nil
        booksToDelete = 0
        metadataToDelete = 0
    }
    
    // MARK: - Private Implementation
    
    /// Clean up any active or paused imports
    private func cleanupActiveImports() async {
        // 1. Cancel any active background import
        if let coordinator = BackgroundImportCoordinator.shared {
            await coordinator.cancelImport()
        }
        
        // 2. Clear any persisted import state
        ImportStateManager.shared.clearImportState()
        
        print("[LibraryResetService] Cleaned up active imports and import state")
    }
    
    /// Export books to CSV format
    private func exportToCSV(userBooks: [UserBook]) async throws -> URL {
        var csvContent = "Title,Author,ISBN,Status,Rating,Progress,Start Date,Finish Date,Notes,Tags,Genre,Publisher,Published Date,Page Count,Author Nationality,Original Language\n"
        
        let totalBooks = userBooks.count
        for (index, book) in userBooks.enumerated() {
            // Update progress
            exportProgress = Double(index) / Double(totalBooks)
            
            // Build CSV row - break down complex expressions
            let title = book.metadata?.title.csvEscaped ?? ""
            let author = book.metadata?.authors.first?.csvEscaped ?? ""
            let isbn = book.metadata?.isbn?.csvEscaped ?? ""
            let status = book.readingStatus.rawValue
            let rating = book.rating != nil ? "\(book.rating!)" : ""
            let progress = "\(book.readingProgress)"
            let startDate = book.dateStarted?.ISO8601Format() ?? ""
            let finishDate = book.dateCompleted?.ISO8601Format() ?? ""
            let notes = book.notes?.csvEscaped ?? ""
            let tags = book.tags.joined(separator: ";").csvEscaped
            let genre = book.metadata?.genre.first?.csvEscaped ?? ""
            
            let row = [
                title,
                author,
                isbn,
                status,
                rating,
                progress,
                startDate,
                finishDate,
                notes,
                tags,
                genre,
                book.metadata?.publisher?.csvEscaped ?? "",
                book.metadata?.publishedDate?.csvEscaped ?? "",
                book.metadata?.pageCount.map(String.init) ?? "",
                book.metadata?.authorNationality?.csvEscaped ?? "",
                book.metadata?.originalLanguage?.csvEscaped ?? ""
            ].joined(separator: ",")
            
            csvContent += row + "\n"
        }
        
        // Save to file
        let fileName = "library_backup_\(Date().ISO8601Format().replacingOccurrences(of: ":", with: "-")).csv"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
        
        return fileURL
    }
    
    /// Export books to JSON format
    private func exportToJSON(userBooks: [UserBook]) async throws -> URL {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        // Create export data structure - break down complex expressions
        let exportData = userBooks.map { book -> [String: String] in
            // Extract all values first
            let title = book.metadata?.title ?? ""
            let author = book.metadata?.authors.first ?? ""
            let isbn = book.metadata?.isbn ?? ""
            let status = book.readingStatus.rawValue
            let rating = book.rating != nil ? "\(book.rating!)" : ""
            let progress = "\(book.readingProgress)"
            let startDate = book.dateStarted?.ISO8601Format() ?? ""
            let finishDate = book.dateCompleted?.ISO8601Format() ?? ""
            let notes = book.notes ?? ""
            let tags = book.tags.joined(separator: ",")
            let genre = book.metadata?.genre.first ?? ""
            let publisher = book.metadata?.publisher ?? ""
            let publishedDate = book.metadata?.publishedDate ?? ""
            let pageCount = book.metadata?.pageCount != nil ? "\(book.metadata!.pageCount!)" : ""
            let authorNationality = book.metadata?.authorNationality ?? ""
            let originalLanguage = book.metadata?.originalLanguage ?? ""
            let coverImageURL = book.metadata?.imageURL?.absoluteString ?? ""
            let googleBooksID = book.metadata?.googleBooksID ?? ""
            
            // Build dictionary
            return [
                "title": title,
                "author": author,
                "isbn": isbn,
                "status": status,
                "rating": rating,
                "progress": progress,
                "startDate": startDate,
                "finishDate": finishDate,
                "notes": notes,
                "tags": tags,
                "genre": genre,
                "publisher": publisher,
                "publishedDate": publishedDate,
                "pageCount": pageCount,
                "authorNationality": authorNationality,
                "originalLanguage": originalLanguage,
                "coverImageURL": coverImageURL,
                "googleBooksID": googleBooksID
            ]
        }
        
        let jsonData = try encoder.encode(exportData)
        
        // Save to file
        let fileName = "library_backup_\(Date().ISO8601Format().replacingOccurrences(of: ":", with: "-")).json"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        try jsonData.write(to: fileURL)
        
        return fileURL
    }
    
    /// Clear UserDefaults (except theme settings)
    private func clearUserDefaults() {
        let defaults = UserDefaults.standard
        let preserveKeys = ["selectedTheme", "hasCompletedOnboarding"] // Keys to preserve
        
        // Get current values to preserve
        var preservedValues: [String: Any] = [:]
        for key in preserveKeys {
            if let value = defaults.object(forKey: key) {
                preservedValues[key] = value
            }
        }
        
        // Clear all defaults
        if let bundleID = Bundle.main.bundleIdentifier {
            defaults.removePersistentDomain(forName: bundleID)
        }
        
        // Restore preserved values
        for (key, value) in preservedValues {
            defaults.set(value, forKey: key)
        }
        
        defaults.synchronize()
    }
    
    /// Clear temporary files
    private func clearTemporaryFiles() {
        let tempDirectory = FileManager.default.temporaryDirectory
        
        do {
            let tempFiles = try FileManager.default.contentsOfDirectory(
                at: tempDirectory,
                includingPropertiesForKeys: nil
            )
            
            for file in tempFiles {
                // Don't delete our export file
                if file != exportedFileURL {
                    try? FileManager.default.removeItem(at: file)
                }
            }
            
            print("[LibraryResetService] Cleared temporary files")
        } catch {
            print("[LibraryResetService] Error clearing temp files: \(error)")
        }
    }
}

// MARK: - String Extension for CSV

private extension String {
    var csvEscaped: String {
        // Escape quotes and wrap in quotes if contains comma, newline, or quotes
        let needsQuotes = self.contains(",") || self.contains("\n") || self.contains("\"")
        if needsQuotes {
            let escaped = self.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(escaped)\""
        }
        return self
    }
}