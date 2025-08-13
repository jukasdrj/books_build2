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
    }
    
    func performFullMigration() async {
        isMigrating = true
        migrationStatus = "Updating reading statuses..."
        migrationProgress = 0.3
        
        await performReadingStatusMigration()
        migrationStatus = "Deprecating unused fields..."
        migrationProgress = 0.6
        
        await performFieldDeprecationMigration()
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
}