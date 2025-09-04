import SwiftUI

// Import all necessary theme components
// Note: These imports ensure all theme system dependencies are available

// MARK: - iOS 26 Theme System Bridge
// Safely unifies Material Design 3 and Liquid Glass theme systems
// This bridge allows gradual migration without breaking existing functionality

/// Unified theme variant that bridges both MD3 and Liquid Glass systems
enum UnifiedThemeVariant: String, CaseIterable, Identifiable {
    // Material Design 3 variants (existing)
    case purpleBoho = "Purple Boho"
    case forestSage = "Forest Sage"
    case oceanBlues = "Ocean Blues"  
    case sunsetWarmth = "Sunset Warmth"
    case monochromeElegance = "Monochrome Elegance"
    
    // Liquid Glass variants (new - iOS 26)
    case crystalClear = "Crystal Clear"
    case auroraGlow = "Aurora Glow"
    case deepOcean = "Deep Ocean"
    case forestMist = "Forest Mist"
    case sunsetBloom = "Sunset Bloom"
    case shadowElegance = "Shadow Elegance"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
    
    var description: String {
        switch self {
        // MD3 descriptions
        case .purpleBoho: return "Mystical, warm, creative vibes"
        case .forestSage: return "Earthy, grounding, natural tones"
        case .oceanBlues: return "Calming, expansive, peaceful"
        case .sunsetWarmth: return "Cozy, romantic, intimate feels"
        case .monochromeElegance: return "Sophisticated, minimalist, timeless"
        
        // Liquid Glass descriptions
        case .crystalClear: return "Pure, pristine clarity with glass effects"
        case .auroraGlow: return "Magical, ethereal luminescence with vibrancy"
        case .deepOcean: return "Mysterious, profound depths with translucency"
        case .forestMist: return "Natural, organic serenity with mist effects"
        case .sunsetBloom: return "Warm, romantic radiance with glass bloom"
        case .shadowElegance: return "Sophisticated, timeless grace with depth"
        }
    }
    
    var emoji: String {
        switch self {
        // MD3 emojis
        case .purpleBoho: return "💜"
        case .forestSage: return "🌿"
        case .oceanBlues: return "🌊"
        case .sunsetWarmth: return "🌅"
        case .monochromeElegance: return "⚫"
        
        // Liquid Glass emojis
        case .crystalClear: return "💎"
        case .auroraGlow: return "🌟"
        case .deepOcean: return "🌊"
        case .forestMist: return "🌿"
        case .sunsetBloom: return "🌅"
        case .shadowElegance: return "🖤"
        }
    }
    
    /// Determines if this variant uses Liquid Glass design system
    var isLiquidGlass: Bool {
        switch self {
        case .crystalClear, .auroraGlow, .deepOcean, .forestMist, .sunsetBloom, .shadowElegance:
            return true
        case .purpleBoho, .forestSage, .oceanBlues, .sunsetWarmth, .monochromeElegance:
            return false
        }
    }
    
    /// Maps to existing ThemeVariant for backward compatibility
    var legacyThemeVariant: ThemeVariant? {
        switch self {
        case .purpleBoho: return .purpleBoho
        case .forestSage: return .forestSage
        case .oceanBlues: return .oceanBlues
        case .sunsetWarmth: return .sunsetWarmth
        case .monochromeElegance: return .monochromeElegance
        default: return nil
        }
    }
    
    /// Maps to LiquidGlassVariant for new iOS 26 themes
    var liquidGlassVariant: LiquidGlassVariant? {
        switch self {
        case .crystalClear: return .crystalClear
        case .auroraGlow: return .auroraGlow
        case .deepOcean: return .deepOcean
        case .forestMist: return .forestMist
        case .sunsetBloom: return .sunsetBloom
        case .shadowElegance: return .shadowElegance
        default: return nil
        }
    }
    
    var previewGradient: LinearGradient {
        if isLiquidGlass, let liquidVariant = liquidGlassVariant {
            // Use Liquid Glass gradient with vibrancy
            return LinearGradient(
                gradient: Gradient(colors: liquidVariant.colorDefinition.previewColors),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else if let legacyVariant = legacyThemeVariant {
            // Use existing MD3 gradient
            return legacyVariant.previewGradient
        } else {
            // Fallback gradient
            return LinearGradient(
                gradient: Gradient(colors: [.blue, .purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Unified Theme Store
/// Enhanced ThemeStore that bridges both design systems
@MainActor
class UnifiedThemeStore: ObservableObject {
    private let userDefaults = UserDefaults.standard
    
    /// Current unified theme variant - defaulting to iOS 26 Liquid Glass for Phase 2
    @Published var currentTheme: UnifiedThemeVariant = .crystalClear {
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
    
    /// Computed property for backward compatibility with existing AppColorTheme
    var appTheme: AppColorTheme {
        if currentTheme.isLiquidGlass {
            // For Liquid Glass themes, create a bridged AppColorTheme
            return bridgedAppTheme
        } else if let legacyVariant = currentTheme.legacyThemeVariant {
            // For MD3 themes, use existing system
            return AppColorTheme(variant: legacyVariant)
        } else {
            // Fallback to default
            return AppColorTheme(variant: .purpleBoho)
        }
    }
    
    /// Computed property for Liquid Glass themes
    var liquidGlassTheme: LiquidGlassTheme? {
        guard currentTheme.isLiquidGlass,
              let _ = currentTheme.liquidGlassVariant else {
            return nil
        }
        return LiquidGlassTheme()
    }
    
    /// Converts AppearancePreference to ColorScheme for SwiftUI
    var preferredColorScheme: ColorScheme? {
        switch appearancePreference {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil // Let system decide
        }
    }
    
    /// Bridged AppColorTheme for Liquid Glass variants
    private var bridgedAppTheme: AppColorTheme {
        // Create an AppColorTheme that maps Liquid Glass colors to MD3 structure
        // This ensures compatibility with existing views during migration
        guard let liquidVariant = currentTheme.liquidGlassVariant else {
            return AppColorTheme(variant: .purpleBoho)
        }
        
        // Create a bridge ThemeVariant for compatibility
        // For now, map to closest MD3 equivalent
        let bridgeVariant: ThemeVariant = {
            switch liquidVariant {
            case .crystalClear: return .oceanBlues
            case .auroraGlow: return .purpleBoho
            case .deepOcean: return .oceanBlues
            case .forestMist: return .forestSage
            case .sunsetBloom: return .sunsetWarmth
            case .shadowElegance: return .monochromeElegance
            }
        }()
        
        return AppColorTheme(variant: bridgeVariant)
    }
    
    init() {
        loadPersistedTheme()
        loadPersistedAppearancePreference()
    }
    
    /// Sets a new theme with animation and haptic feedback
    func setTheme(_ theme: UnifiedThemeVariant) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentTheme = theme
        }
        HapticFeedbackManager.shared.mediumImpact()
    }
    
    /// Sets appearance preference
    func setAppearance(_ preference: AppearancePreference) {
        withAnimation(.easeInOut(duration: 0.3)) {
            appearancePreference = preference
        }
        HapticFeedbackManager.shared.lightImpact()
    }
    
    /// Forces reset to iOS 26 Liquid Glass default for Phase 2 development
    func forceResetToLiquidGlass() {
        UserDefaults.standard.removeObject(forKey: "selectedTheme")
        withAnimation(.easeInOut(duration: 0.5)) {
            currentTheme = .crystalClear
        }
        HapticFeedbackManager.shared.mediumImpact()
        
        #if DEBUG
        print("[UnifiedThemeStore] 🔧 Force reset completed:")
        print("  - Theme: \(currentTheme.rawValue)")
        print("  - Is Liquid Glass: \(currentTheme.isLiquidGlass)")
        print("  - UserDefaults cleared for 'selectedTheme'")
        #endif
    }
    
    /// Loads the persisted theme from UserDefaults
    private func loadPersistedTheme() {
        if let themeName = UserDefaults.standard.string(forKey: "selectedTheme") {
            // Try to load as UnifiedThemeVariant first
            if let unifiedTheme = UnifiedThemeVariant(rawValue: themeName) {
                currentTheme = unifiedTheme
                return
            }
            
            // Fallback: try to load as legacy ThemeVariant and convert
            if let legacyTheme = ThemeVariant(rawValue: themeName) {
                currentTheme = convertLegacyTheme(legacyTheme)
                return
            }
        }
        
        // Default fallback - iOS 26 Liquid Glass for Phase 2
        currentTheme = .crystalClear
    }
    
    /// Converts legacy ThemeVariant to UnifiedThemeVariant
    private func convertLegacyTheme(_ legacy: ThemeVariant) -> UnifiedThemeVariant {
        switch legacy {
        case .purpleBoho: return .purpleBoho
        case .forestSage: return .forestSage
        case .oceanBlues: return .oceanBlues
        case .sunsetWarmth: return .sunsetWarmth
        case .monochromeElegance: return .monochromeElegance
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
    static var availableThemes: [UnifiedThemeVariant] {
        UnifiedThemeVariant.allCases
    }
    
    /// Returns only MD3 themes for compatibility
    static var legacyThemes: [UnifiedThemeVariant] {
        UnifiedThemeVariant.allCases.filter { !$0.isLiquidGlass }
    }
    
    /// Returns only Liquid Glass themes
    static var liquidGlassThemes: [UnifiedThemeVariant] {
        UnifiedThemeVariant.allCases.filter { $0.isLiquidGlass }
    }
}

// MARK: - Bridge Environment Keys
struct UnifiedThemeStoreKey: @preconcurrency EnvironmentKey {
    @MainActor
    static let defaultValue = UnifiedThemeStore()
}

extension EnvironmentValues {
    var unifiedThemeStore: UnifiedThemeStore {
        get { self[UnifiedThemeStoreKey.self] }
        set { self[UnifiedThemeStoreKey.self] = newValue }
    }
}

// MARK: - Migration Helper Extensions
extension LiquidGlassColorDefinition {
    /// Preview colors for theme selection UI
    var previewColors: [Color] {
        return [
            Color(primary.color),
            Color(secondary.color),
            Color(accent.color)
        ]
    }
}

extension VibrancyColor {
    /// Get the actual SwiftUI Color based on environment
    var color: Color {
        return Color.adaptive(light: light, dark: dark)
    }
}

// MARK: - Migration Safety Check
/// Ensures that migration doesn't break existing functionality
struct ThemeMigrationValidator {
    static func validateBridge() -> Bool {
        // Test that all legacy themes map correctly
        let legacyVariants: [ThemeVariant] = [.purpleBoho, .forestSage, .oceanBlues, .sunsetWarmth, .monochromeElegance]
        
        for legacy in legacyVariants {
            let unified = UnifiedThemeVariant(rawValue: legacy.rawValue)
            guard unified != nil else {
                print("❌ Migration Error: Legacy theme \(legacy.rawValue) not found in UnifiedThemeVariant")
                return false
            }
        }
        
        print("✅ Theme migration bridge validation passed")
        return true
    }
    
    static func validateLiquidGlassThemes() -> Bool {
        let liquidVariants: [LiquidGlassVariant] = [.crystalClear, .auroraGlow, .deepOcean, .forestMist, .sunsetBloom, .shadowElegance]
        
        for liquid in liquidVariants {
            let unified = UnifiedThemeVariant(rawValue: liquid.displayName)
            guard unified?.liquidGlassVariant == liquid else {
                print("❌ Liquid Glass Error: Variant \(liquid.displayName) mapping failed")
                return false
            }
        }
        
        print("✅ Liquid Glass theme validation passed")
        return true
    }
}