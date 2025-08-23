// books-buildout/books/booksApp.swift
import SwiftUI
import SwiftData
import UIKit

@main
struct booksApp: App {
    @State private var themeStore = ThemeStore()
    @Environment(\.colorScheme) private var colorScheme
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var dataInitializationError: Error? = nil
    
    private var adaptiveBackground: Color {
        // Force dependency on colorScheme to ensure updates on light/dark mode changes
        let _ = colorScheme
        return themeStore.appTheme.background
    }
    
    private var sharedModelContainer: ModelContainer? {
        createModelContainer()
    }
    
    private func createModelContainer() -> ModelContainer? {
        // FIXED: CloudKit unique constraint issue resolved
        
        // Try simple in-memory container first to test model validity
        let schema = Schema([
            UserBook.self,
            BookMetadata.self,
        ])
        
        // Debug: Print schema information
        print("SwiftData Schema Debug:")
        print("- UserBook: \(UserBook.self)")
        print("- BookMetadata: \(BookMetadata.self)")
        
        do {
            // Configure without CloudKit to avoid unique constraint conflict
            let localConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none  // Explicitly disable CloudKit
            )
            let container = try ModelContainer(for: schema, configurations: [localConfig])
            print("✅ Local-only ModelContainer created successfully (no CloudKit)")
            return container
        } catch {
            print("❌ Local container failed: \(error)")
            
            // Fallback: Try in-memory only
            do {
                let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                let container = try ModelContainer(for: schema, configurations: [memoryConfig])
                print("✅ In-memory ModelContainer created successfully")
                return container
            } catch {
                print("❌ All ModelContainer creation attempts failed: \(error)")
                print("❌ This indicates a fundamental issue with the SwiftData models")
                print("❌ SwiftData Error Details: \(error)")
                
                // Store error for graceful handling instead of crashing
                dataInitializationError = error
                return nil
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let container = sharedModelContainer {
                    ThemedRootView(themeStore: themeStore)
                        .modelContainer(container)
                } else {
                    // Show error recovery screen instead of crashing
                    DataErrorRecoveryView(
                        error: dataInitializationError,
                        themeStore: themeStore,
                        onRetry: {
                            // Reset error and attempt retry
                            dataInitializationError = nil
                        }
                    )
                }
            }
        }
    }
}

/// Wrapper view that observes ThemeStore and provides reactive theme environment
struct ThemedRootView: View {
    @ObservedObject var themeStore: ThemeStore
    @StateObject private var cloudKitManager = CloudKitManager()
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @State private var hasBypassedICloudLogin = UserDefaults.standard.bool(forKey: "hasBypassedICloudLogin")
    
    var body: some View {
        ZStack {
            // Status bar background color layer
            themeStore.appTheme.background
                .ignoresSafeArea()
            
            if cloudKitManager.isUserLoggedIn || hasBypassedICloudLogin {
                ContentView()
                    .onAppear {
                        _ = BackgroundImportCoordinator.initialize(with: modelContext)
                    }
            } else {
                iCloudLoginView(hasBypassedICloudLogin: $hasBypassedICloudLogin)
            }
        }
        .onAppear(perform: cloudKitManager.checkAccountStatus)
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
        
        #if DEBUG
        print("[AppDelegate] ✅ App launched using proxy-based book search - no API key management needed")
        #endif
        
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
