// books-buildout/books/booksApp.swift
import SwiftUI
import SwiftData

@main
struct booksApp: App {
    @State private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    private var adaptiveBackground: Color {
        // Force dependency on colorScheme to ensure updates on light/dark mode changes
        let _ = colorScheme
        return AppColorTheme(variant: themeManager.currentTheme).background
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

                print("[ScreenshotMode] Loaded demo data for screenshots.")
                return container
            } catch {
                fatalError("ScreenshotMode: Failed to create in-memory ModelContainer: \(error)")
            }
        }
        // --- End Screenshot Mode block ---

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
            ZStack {
                // Status bar background color layer
                Color.theme.background
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
            // Integrate new EnvironmentKey-based theme provider
            .environment(\.appTheme, AppColorTheme(variant: themeManager.currentTheme))
            .onChange(of: colorScheme) { _, _ in
                // Force refresh system UI when color scheme changes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    themeManager.refreshSystemUI()
                }
            }
            .onChange(of: themeManager.currentTheme) { _, _ in
                // Force refresh when theme changes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    themeManager.refreshSystemUI()
                }
            }
            .statusBarHidden(false)
            .preferredColorScheme(ScreenshotMode.forceLightMode ? .light : nil)
        }
        .modelContainer(sharedModelContainer)
    }
}