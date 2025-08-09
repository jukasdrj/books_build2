import SwiftUI
import Observation

/// Observable theme store that manages the current app theme
/// Provides persistence and reactive updates throughout the app
@Observable
class ThemeStore {
    /// Current selected theme variant
    var currentTheme: ThemeVariant = .purpleBoho
    
    /// Computed property for the current AppColorTheme
    var appTheme: AppColorTheme {
        AppColorTheme(variant: currentTheme)
    }
    
    init() {
        loadPersistedTheme()
    }
    
    /// Sets a new theme and persists the selection
    /// - Parameter theme: The theme variant to set
    @MainActor
    func setTheme(_ theme: ThemeVariant) {
        currentTheme = theme
        persistTheme()
        
        // Post notification for components that need to react to theme changes
        NotificationCenter.default.post(name: .themeDidChange, object: nil)
        
        // Add haptic feedback for better UX
        HapticFeedbackManager.shared.mediumImpact()
    }
    
    /// Loads the persisted theme from UserDefaults
    private func loadPersistedTheme() {
        if let themeName = UserDefaults.standard.string(forKey: "selectedTheme"),
           let theme = ThemeVariant(rawValue: themeName) {
            currentTheme = theme
        }
    }
    
    /// Persists the current theme to UserDefaults
    private func persistTheme() {
        UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedTheme")
    }
    
    /// Returns all available themes for selection UI
    static var availableThemes: [ThemeVariant] {
        ThemeVariant.allCases
    }
}

// MARK: - Theme Store Environment Key

struct ThemeStoreKey: EnvironmentKey {
    static let defaultValue = ThemeStore()
}

extension EnvironmentValues {
    var themeStore: ThemeStore {
        get { self[ThemeStoreKey.self] }
        set { self[ThemeStoreKey.self] = newValue }
    }
}
