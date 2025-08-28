import SwiftUI

/// Represents app appearance preferences
enum AppearancePreference: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// Observable theme store that manages the current app theme
/// Provides persistence and reactive updates throughout the app
@MainActor
class ThemeStore: ObservableObject {
    private let userDefaults = UserDefaults.standard
    
    /// Current selected theme variant
    @Published var currentTheme: ThemeVariant = .purpleBoho {
        didSet {
            persistTheme()
        }
    }
    
    /// Current appearance preference
    @Published var appearancePreference: AppearancePreference = .system {
        didSet {
            persistAppearancePreference()
        }
    }
    
    /// Computed property for the current AppColorTheme
    var appTheme: AppColorTheme {
        AppColorTheme(variant: currentTheme)
    }
    
    init() {
        loadPersistedTheme()
        loadPersistedAppearancePreference()
    }
    
    /// Sets a new theme with animation and haptic feedback
    /// - Parameter theme: The theme variant to set
    func setTheme(_ theme: ThemeVariant) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentTheme = theme
        }
        HapticFeedbackManager.shared.mediumImpact()
    }
    
    /// Sets appearance preference
    /// - Parameter preference: The appearance preference to set
    func setAppearance(_ preference: AppearancePreference) {
        withAnimation(.easeInOut(duration: 0.3)) {
            appearancePreference = preference
        }
        HapticFeedbackManager.shared.lightImpact()
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
    
    /// Loads the persisted appearance preference from UserDefaults
    private func loadPersistedAppearancePreference() {
        if let preferenceName = UserDefaults.standard.string(forKey: "appearancePreference"),
           let preference = AppearancePreference(rawValue: preferenceName) {
            appearancePreference = preference
        }
    }
    
    /// Persists the current appearance preference to UserDefaults
    private func persistAppearancePreference() {
        UserDefaults.standard.set(appearancePreference.rawValue, forKey: "appearancePreference")
    }
    
    /// Returns all available themes for selection UI
    static var availableThemes: [ThemeVariant] {
        ThemeVariant.allCases
    }
}

// MARK: - Theme Store Environment Key

struct ThemeStoreKey: @preconcurrency EnvironmentKey {
    @MainActor
    static let defaultValue = ThemeStore()
}

extension EnvironmentValues {
    var themeStore: ThemeStore {
        get { self[ThemeStoreKey.self] }
        set { self[ThemeStoreKey.self] = newValue }
    }
}
