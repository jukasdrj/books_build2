// books-buildout/books/booksApp.swift
import SwiftUI
import SwiftData

@main
struct booksApp: App {
    @State private var themeStore = ThemeStore()
    @Environment(\.colorScheme) private var colorScheme
    
    private var adaptiveBackground: Color {
        // Force dependency on colorScheme to ensure updates on light/dark mode changes
        let _ = colorScheme
        return themeStore.appTheme.background
    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserBook.self,
            BookMetadata.self,
        ])

        // --- Screenshot Mode block ---
        if ScreenshotMode.isEnabled {
            // Always use in-memory storage for screenshots
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            do {
                let container = try ModelContainer(for: schema, configurations: [config])

                // Wipe and seed demo data
                let context = ModelContext(container)
                let books = ScreenshotMode.demoBooks()
                for book in books {
                    context.insert(book)
                    if let metadata = book.metadata {
                        context.insert(metadata)
                    }
                }

                // Demo data loaded for screenshots
                return container
            } catch {
                fatalError("ScreenshotMode: Failed to create in-memory ModelContainer: \(error)")
            }
        }
        // --- End Screenshot Mode block ---

        // Configure model container with version-based naming
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let schemaVersion = "v6" // Update this when schema changes
        let databaseName = "BooksModel_\(schemaVersion)_\(appVersion.replacingOccurrences(of: ".", with: "_"))"
        
        let modelConfiguration = ModelConfiguration(
            databaseName,
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            // Successfully created ModelContainer
            return container
        } catch {
            // Could not create ModelContainer, attempting fallback migration

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
                // Fallback failed, using in-memory storage as last resort
                do {
                    return try ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
                } catch {
                    fatalError("Critical: Unable to create even in-memory ModelContainer: \(error)")
                }
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ThemedRootView(themeStore: themeStore)
        }
        .modelContainer(sharedModelContainer)
    }
}

/// Wrapper view that observes ThemeStore and provides reactive theme environment
struct ThemedRootView: View {
    @Bindable var themeStore: ThemeStore
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Status bar background color layer
            themeStore.appTheme.background
                .ignoresSafeArea()
            
            Group {
                if ScreenshotMode.forceLightMode {
                    ContentView()
                        .environment(\.colorScheme, .light)
                } else {
                    ContentView()
                }
            }
        }
        // Integrate environment-based theme system with reactive updates
        .environment(\.themeStore, themeStore)
        .environment(\.appTheme, themeStore.appTheme)
        .onChange(of: colorScheme) { _, _ in
            // Force refresh system UI when color scheme changes
            // No longer needed with new theming system
        }
        .statusBarHidden(false)
        .preferredColorScheme(ScreenshotMode.forceLightMode ? .light : nil)
    }
}