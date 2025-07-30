// books-buildout/books/booksApp.swift
import SwiftUI
import SwiftData

@main
struct booksApp: App {
    let container: ModelContainer
    
    init() {
        do {
            // This line is crucial: it tells SwiftData about all the data models the app will use.
            container = try ModelContainer(for: UserBook.self, BookMetadata.self)
        } catch {
            // If the container fails to initialize, the app cannot run.
            fatalError("Failed to initialize ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                // This passes the initialized data container into the SwiftUI environment,
                // making it accessible to all child views like LibraryView, SearchView, etc.
                .modelContainer(container)
        }
    }
}
