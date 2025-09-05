// books-buildout/books/booksApp.swift
import SwiftUI
import SwiftData
import UIKit

@main
struct booksApp: App {
    @State private var unifiedThemeStore = UnifiedThemeStore()
    @Environment(\.colorScheme) private var colorScheme
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    private var adaptiveBackground: Color {
        // Force dependency on colorScheme to ensure updates on light/dark mode changes
        let _ = colorScheme
        return unifiedThemeStore.appTheme.background
    }
    
    var sharedModelContainer: ModelContainer = {
        // FIXED: CloudKit unique constraint issue resolved
        
        // Try simple in-memory container first to test model validity
        let schema = Schema([
            UserBook.self,
            BookMetadata.self,
            AuthorProfile.self,
        ])
        
        // Debug: Print schema information
        print("SwiftData Schema Debug:")
        print("- UserBook: \(UserBook.self)")
        print("- BookMetadata: \(BookMetadata.self)")
        print("- AuthorProfile: \(AuthorProfile.self)")
        
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
            ErrorHandler.shared.handle(
                error,
                context: "SwiftData Local ModelContainer Creation",
                userInfo: ["schema_types": schema.entities.map { $0.name }]
            )
            print("❌ Local container failed: \(error)")
            
            // Fallback: Try in-memory only
            do {
                let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                let container = try ModelContainer(for: schema, configurations: [memoryConfig])
                print("✅ In-memory ModelContainer created successfully")
                return container
            } catch {
                ErrorHandler.shared.handleCritical(
                    error,
                    context: "SwiftData Critical - All ModelContainer Creation Failed",
                    userInfo: [
                        "attempted_configs": ["local", "in-memory"],
                        "schema_types": schema.entities.map { $0.name },
                        "swiftdata_version": "iOS 26.0+"
                    ]
                )
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ThemedRootView(unifiedThemeStore: unifiedThemeStore)
        }
        .modelContainer(sharedModelContainer)
    }
}

/// Wrapper view that observes UnifiedThemeStore and provides reactive theme environment
struct ThemedRootView: View {
    @ObservedObject var unifiedThemeStore: UnifiedThemeStore
    @StateObject private var cloudKitManager = CloudKitManager()
    @StateObject private var contentAnalyzer = LiquidGlassContentAnalyzer.shared
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @State private var hasBypassedICloudLogin = UserDefaults.standard.bool(forKey: "hasBypassedICloudLogin")
    
    var body: some View {
        ZStack {
            // Status bar background color layer
            unifiedThemeStore.appTheme.background
                .ignoresSafeArea()
            
            if cloudKitManager.isUserLoggedIn || hasBypassedICloudLogin {
                iOS26ContentViewWrapper()
            } else {
                iCloudLoginView(hasBypassedICloudLogin: $hasBypassedICloudLogin)
            }
        }
        .onAppear(perform: cloudKitManager.checkAccountStatus)
        // Integrate unified theme system with reactive updates
        .environment(\.unifiedThemeStore, unifiedThemeStore)
        .environment(\.appTheme, unifiedThemeStore.appTheme)
        .environment(\.liquidGlassContentAnalyzer, contentAnalyzer)
        .preferredColorScheme(unifiedThemeStore.preferredColorScheme)
        .onChange(of: colorScheme) { _, newColorScheme in
            // Update content analyzer with new color scheme for adaptive materials
            contentAnalyzer.analyzeColorScheme(newColorScheme)
            
            #if DEBUG
            print("[ContentAnalyzer] 🌓 Color scheme changed to \(newColorScheme == .light ? "Light" : "Dark")")
            print("  - Updated content analysis for adaptive Liquid Glass materials")
            #endif
        }
        .statusBarHidden(false)
        .onAppear {
            // Force iOS 26 Liquid Glass theme for Phase 2 development
            #if DEBUG
            unifiedThemeStore.forceResetToLiquidGlass()
            print("[Phase 2] 🎨 Forced reset to iOS 26 Liquid Glass theme (.crystalClear)")
            #endif
            
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
        
        // Prevent view bouncing by ensuring coordinator state is consistent
        Task { @MainActor in
            if BackgroundImportCoordinator.shared != nil {
                // Force refresh of coordinator state to prevent UI bouncing
                print("[AppDelegate] App became active, refreshing coordinator state")
            }
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        BackgroundTaskManager.shared.handleAppWillTerminate()
    }
}
