// books-buildout/books/booksApp.swift
import SwiftUI
import SwiftData

@main
struct booksApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserBook.self,
            BookMetadata.self,
        ])
        
        // Clean migration for ReadingStatus changes
        let modelConfiguration = ModelConfiguration(
            "BooksModel_v5_StatusLabels", // New version forces migration
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("Successfully created ModelContainer with new status labels")
            return container
        } catch {
            print("Could not create ModelContainer: \(error)")
            // For development, we can reset to a clean state
            print("Attempting fallback migration...")
            
            // Try with a completely new database name
            let fallbackConfig = ModelConfiguration(
                "BooksModel_Fresh_\(Date().timeIntervalSince1970)",
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            
            do {
                return try ModelContainer(for: schema, configurations: [fallbackConfig])
            } catch {
                print("Fallback failed, using in-memory storage: \(error)")
                return try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}