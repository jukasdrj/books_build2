// books-buildout/books/booksApp.swift
import SwiftUI
import SwiftData

@main
struct booksApp: App {
    let container: ModelContainer
    
    init() {
        do {
            // Try to create container with default configuration first
            container = try ModelContainer(for: UserBook.self, BookMetadata.self)
        } catch {
            // If migration fails, try creating a fresh container
            print("Migration failed, attempting fresh container: \(error)")
            do {
                // Create a new configuration that starts fresh
                let configuration = ModelConfiguration(isStoredInMemoryOnly: false)
                container = try ModelContainer(
                    for: UserBook.self, BookMetadata.self,
                    configurations: configuration
                )
            } catch {
                // Last resort: in-memory container
                print("Failed to create persistent container, using in-memory: \(error)")
                do {
                    container = try ModelContainer(
                        for: UserBook.self, BookMetadata.self,
                        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                    )
                } catch {
                    fatalError("Failed to create any ModelContainer: \(error)")
                }
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
}