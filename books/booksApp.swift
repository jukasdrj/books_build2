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
        
        // Force a clean migration due to BookFormat enum changes
        let modelConfiguration = ModelConfiguration(
            "BooksModel_v2", // Version bump to force clean migration
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // If there are any issues, fall back to in-memory storage
            print("Could not create ModelContainer: \(error)")
            return try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}