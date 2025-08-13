// books-buildout/books/booksApp.swift
import SwiftUI
import SwiftData
import UIKit

@main
struct booksApp: App {
    @State private var themeStore = ThemeStore()
    @Environment(\.colorScheme) private var colorScheme
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
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


        let modelConfiguration = ModelConfiguration(
            schema: schema,
            cloudKitContainerIdentifier: "iCloud.userLibrary"
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
    @ObservedObject var themeStore: ThemeStore
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Status bar background color layer
            themeStore.appTheme.background
                .ignoresSafeArea()
            
            ContentView()
                .onAppear {
                    BackgroundImportCoordinator.initialize(with: self.sharedModelContainer.mainContext)
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
        .preferredColorScheme(nil)
        .onAppear {
            // Set up import state manager with model context
            Task { @MainActor in
                // We'll set up the model context in the ContentView where it has access to the environment
            }
        }
    }
}

// MARK: - App Delegate for Background Task Management

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Register background tasks
        BackgroundTaskManager.shared.registerBackgroundTasks()
        
        print("[AppDelegate] App launched - background tasks registered")
        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        BackgroundTaskManager.shared.handleAppDidEnterBackground()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        BackgroundTaskManager.shared.handleAppDidBecomeActive()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        BackgroundTaskManager.shared.handleAppWillTerminate()
    }
}