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
                sortBy: [SortDescriptor(\.title)]
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
            imageCache.clearCache()
            
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
    
    /// Export books to CSV format
    private func exportToCSV(userBooks: [UserBook]) async throws -> URL {
        var csvContent = "Title,Author,ISBN,Status,Rating,Progress,Start Date,Finish Date,Notes,Tags,Genre,Publisher,Published Date,Page Count,Author Nationality,Original Language\n"
        
        let totalBooks = userBooks.count
        for (index, book) in userBooks.enumerated() {
            // Update progress
            exportProgress = Double(index) / Double(totalBooks)
            
            // Build CSV row
            let row = [
                book.title.csvEscaped,
                book.author.csvEscaped,
                book.isbn?.csvEscaped ?? "",
                book.status.rawValue,
                "\(book.rating)",
                "\(book.progress)",
                book.startDate?.ISO8601Format() ?? "",
                book.finishDate?.ISO8601Format() ?? "",
                book.notes?.csvEscaped ?? "",
                book.tags.joined(separator: ";").csvEscaped,
                book.genre?.csvEscaped ?? "",
                book.publisher?.csvEscaped ?? "",
                book.publishedDate?.ISO8601Format() ?? "",
                book.pageCount.map { "\($0)" } ?? "",
                book.authorNationality?.csvEscaped ?? "",
                book.originalLanguage?.csvEscaped ?? ""
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
        
        // Create export data structure
        let exportData = userBooks.map { book in
            [
                "title": book.title,
                "author": book.author,
                "isbn": book.isbn ?? "",
                "status": book.status.rawValue,
                "rating": "\(book.rating)",
                "progress": "\(book.progress)",
                "startDate": book.startDate?.ISO8601Format() ?? "",
                "finishDate": book.finishDate?.ISO8601Format() ?? "",
                "notes": book.notes ?? "",
                "tags": book.tags.joined(separator: ","),
                "genre": book.genre ?? "",
                "publisher": book.publisher ?? "",
                "publishedDate": book.publishedDate?.ISO8601Format() ?? "",
                "pageCount": book.pageCount.map { "\($0)" } ?? "",
                "authorNationality": book.authorNationality ?? "",
                "originalLanguage": book.originalLanguage ?? "",
                "coverImageURL": book.coverImageURL ?? "",
                "googleBooksID": book.googleBooksID ?? ""
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