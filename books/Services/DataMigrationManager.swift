import SwiftUI
import SwiftData
import Foundation

@MainActor
class DataMigrationManager: ObservableObject {
    @Published var isMigrating = false
    @Published var migrationProgress: Double = 0.0
    @Published var migrationStatus = "Ready"
    @Published var showingMigrationAlert = false
    @Published var migrationError: String?
    
    private let modelContainer: ModelContainer
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    func checkForMigrationNeeds() async {
        // Check if we need to perform any migrations
        await performReadingStatusMigration()
        await performFieldDeprecationMigration()
        await performDataSourceTrackingMigration()
    }
    
    func performFullMigration() async {
        isMigrating = true
        migrationStatus = "Updating reading statuses..."
        migrationProgress = 0.2
        
        await performReadingStatusMigration()
        migrationStatus = "Deprecating unused fields..."
        migrationProgress = 0.4
        
        await performFieldDeprecationMigration()
        migrationStatus = "Migrating data source tracking..."
        migrationProgress = 0.7
        
        await performDataSourceTrackingMigration()
        migrationStatus = "Migration completed"
        migrationProgress = 1.0
        
        isMigrating = false
    }
    
    private func performReadingStatusMigration() async {
        // Note: With the custom decoder in ReadingStatus, this migration
        // should happen automatically when data is loaded. This function
        // serves as a fallback and for logging purposes.
        
        let context = modelContainer.mainContext
        
        do {
            let descriptor = FetchDescriptor<UserBook>()
            let books = try context.fetch(descriptor)
            
            // The custom decoder will handle the migration automatically
            // when each book's readingStatus is accessed
            for book in books {
                _ = book.readingStatus // This triggers the decoder if needed
            }
            
            try context.save()
// print("Reading status migration completed for \(books.count) books")
        } catch {
// print("Error during reading status migration: \(error)")
        }
    }
    
    private func performFieldDeprecationMigration() async {
        // Handle graceful deprecation of unused fields
        // This migration prepares for the removal of:
        // - marginalizedVoice, indigenousAuthor (replaced by enhanced cultural tracking)
        // - contentWarnings, awards (rarely used in practice)  
        // - series, seriesNumber (limited usage, can be part of title/notes)
        
        let context = modelContainer.mainContext
        
        do {
            let descriptor = FetchDescriptor<BookMetadata>()
            let _ = try context.fetch(descriptor)
            
            
            // Phase 3: Deprecated fields have been fully removed from the model
            // SwiftData will automatically handle schema evolution
            // No need to check for deprecated fields - they no longer exist
            
            // Phase 3 Complete: All deprecated fields have been removed
            // SwiftData automatically handles schema migration when fields are removed
            print("Field deprecation migration: Phase 3 complete - deprecated fields removed")
            
        } catch {
            print("Error during field deprecation migration: \(error)")
            migrationError = "Failed to analyze deprecated fields: \(error.localizedDescription)"
        }
    }
    
    private func enhanceBookMetadata(in context: ModelContext) async throws {
        let descriptor = FetchDescriptor<UserBook>()
        let books = try context.fetch(descriptor)
        
        for book in books {
            if book.metadata == nil {
                book.metadata = BookMetadata(
                    googleBooksID: "migrated-\(UUID().uuidString)",
                    title: "Unknown Title",
                    authors: ["Unknown Author"]
                )
            }
        }
    }
    
    // MARK: - Phase 3: Data Source Tracking Migration
    
    private func performDataSourceTrackingMigration() async {
        let context = modelContainer.mainContext
        
        do {
            // Migrate BookMetadata records
            let metadataDescriptor = FetchDescriptor<BookMetadata>()
            let metadataRecords = try context.fetch(metadataDescriptor)
            
            for metadata in metadataRecords {
                // Only migrate if dataSource is still default
                if metadata.dataSource == .manualEntry && metadata.fieldDataSources.isEmpty {
                    // Determine data source based on existing data
                    if metadata.googleBooksID.starts(with: "csv_") {
                        metadata.dataSource = .csvImport
                        metadata.dataCompleteness = 0.7 // CSV import typically has moderate completeness
                        metadata.dataQualityScore = 0.8 // Good quality but needs validation
                    } else if !metadata.googleBooksID.isEmpty && !metadata.googleBooksID.starts(with: "migrated-") {
                        metadata.dataSource = .googleBooksAPI
                        metadata.dataCompleteness = 0.9 // API data is typically quite complete
                        metadata.dataQualityScore = 1.0 // High quality from API
                    } else {
                        metadata.dataSource = .manualEntry
                        metadata.dataCompleteness = calculateInitialCompleteness(for: metadata)
                        metadata.dataQualityScore = 0.9 // Manual entry is high quality when present
                    }
                    
                    metadata.lastDataUpdate = Date()
                    
                    // Set field-level sources for key fields
                    var fieldSources: [String: DataSourceInfo] = [:]
                    let confidence = metadata.dataSource == .googleBooksAPI ? 1.0 : 0.8
                    let sourceInfo = DataSourceInfo(source: metadata.dataSource, confidence: confidence)
                    
                    if !metadata.title.isEmpty {
                        fieldSources["title"] = sourceInfo
                    }
                    if !metadata.authors.isEmpty {
                        fieldSources["authors"] = sourceInfo
                    }
                    if metadata.publishedDate != nil {
                        fieldSources["publishedDate"] = sourceInfo
                    }
                    if metadata.pageCount != nil {
                        fieldSources["pageCount"] = sourceInfo
                    }
                    
                    metadata.fieldDataSources = fieldSources
                }
            }
            
            // Migrate UserBook records
            let userBookDescriptor = FetchDescriptor<UserBook>()
            let userBooks = try context.fetch(userBookDescriptor)
            
            for userBook in userBooks {
                // Initialize user engagement tracking
                userBook.userDataCompleteness = calculateUserCompleteness(for: userBook)
                userBook.userEngagementScore = calculateEngagementScore(for: userBook)
                
                // Set personal data sources for user fields
                var personalSources: [String: DataSourceInfo] = [:]
                let userSourceInfo = DataSourceInfo(source: .userInput, confidence: 1.0)
                
                if userBook.rating != nil {
                    personalSources["rating"] = userSourceInfo
                }
                if userBook.notes != nil && !userBook.notes!.isEmpty {
                    personalSources["notes"] = userSourceInfo
                }
                if !userBook.tags.isEmpty {
                    personalSources["tags"] = userSourceInfo
                }
                if userBook.readingStatus != .toRead {
                    personalSources["readingStatus"] = userSourceInfo
                }
                
                userBook.personalDataSources = personalSources
                
                // Generate initial user prompts based on missing data
                userBook.needsUserInput = generateInitialPrompts(for: userBook)
            }
            
            try context.save()
            print("Data source tracking migration completed for \(metadataRecords.count) books and \(userBooks.count) user records")
            
        } catch {
            print("Error during data source tracking migration: \(error)")
            migrationError = "Failed to migrate data source tracking: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Migration Helper Methods
    
    private func calculateInitialCompleteness(for metadata: BookMetadata) -> Double {
        var completeness: Double = 0.0
        let totalFields: Double = 10.0 // Key fields to check
        
        if !metadata.title.isEmpty { completeness += 1.0 }
        if !metadata.authors.isEmpty { completeness += 1.0 }
        if metadata.publishedDate != nil { completeness += 1.0 }
        if metadata.pageCount != nil { completeness += 1.0 }
        if metadata.bookDescription != nil && !metadata.bookDescription!.isEmpty { completeness += 1.0 }
        if metadata.imageURL != nil { completeness += 1.0 }
        if metadata.publisher != nil { completeness += 1.0 }
        if metadata.isbn != nil { completeness += 1.0 }
        if !metadata.genre.isEmpty { completeness += 1.0 }
        if metadata.language != nil { completeness += 1.0 }
        
        return completeness / totalFields
    }
    
    private func calculateUserCompleteness(for userBook: UserBook) -> Double {
        var completeness: Double = 0.0
        let totalFields: Double = 6.0 // Key user fields
        
        if userBook.rating != nil { completeness += 1.0 }
        if userBook.notes != nil && !userBook.notes!.isEmpty { completeness += 1.0 }
        if !userBook.tags.isEmpty { completeness += 1.0 }
        if userBook.readingStatus != .toRead { completeness += 1.0 }
        if userBook.currentPage > 0 { completeness += 1.0 }
        if userBook.dateStarted != nil || userBook.dateCompleted != nil { completeness += 1.0 }
        
        return completeness / totalFields
    }
    
    private func calculateEngagementScore(for userBook: UserBook) -> Double {
        var score: Double = 0.0
        
        // Recent activity boosts engagement
        let daysSinceAdded = Calendar.current.dateComponents([.day], from: userBook.dateAdded, to: Date()).day ?? 0
        if daysSinceAdded < 30 { score += 0.3 }
        
        // User input indicates engagement
        if userBook.rating != nil { score += 0.2 }
        if userBook.notes != nil && !userBook.notes!.isEmpty { score += 0.2 }
        if !userBook.tags.isEmpty { score += 0.1 }
        if userBook.isFavorited { score += 0.1 }
        if userBook.readingProgress > 0 { score += 0.1 }
        
        return min(score, 1.0)
    }
    
    private func generateInitialPrompts(for userBook: UserBook) -> [UserInputPrompt] {
        var prompts: [UserInputPrompt] = []
        
        // Check for missing user data
        if userBook.rating == nil {
            prompts.append(.addPersonalRating)
        }
        
        if userBook.notes == nil || userBook.notes!.isEmpty {
            prompts.append(.addPersonalNotes)
        }
        
        if userBook.tags.isEmpty {
            prompts.append(.addTags)
        }
        
        // Check if book was imported from CSV (needs validation)
        if userBook.metadata?.dataSource == .csvImport {
            prompts.append(.validateImportedData)
        }
        
        // Check for missing cultural data
        if userBook.metadata?.culturalRegion == nil || userBook.metadata?.authorGender == nil {
            prompts.append(.reviewCulturalData)
        }
        
        // Check reading progress for active books
        if userBook.readingStatus == .reading && userBook.readingProgress == 0.0 {
            prompts.append(.updateReadingProgress)
        }
        
        return prompts
    }
}