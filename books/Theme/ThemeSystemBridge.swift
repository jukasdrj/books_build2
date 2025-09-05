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

// MARK: - iOS 26 Layer Separation System
/// Defines the proper usage of glass effects vs standard materials per Apple HIG
enum LayerType {
    case functional    // Navigation, tabs, sidebars, modals - USE GLASS
    case content       // Books, text, data displays - USE MATERIALS
    
    var displayName: String {
        switch self {
        case .functional: return "Functional Layer"
        case .content: return "Content Layer"
        }
    }
    
    var description: String {
        switch self {
        case .functional:
            return "Controls and navigation elements that float above content. Uses Liquid Glass effects."
        case .content:
            return "App content like books, text, and data. Uses standard materials for clarity."
        }
    }
    
    /// Returns appropriate background material for this layer type
    func backgroundMaterial(intensity: MaterialIntensity = .medium) -> Material {
        switch self {
        case .functional:
            // Glass effects for functional elements (tabs, navigation, sidebars)
            switch intensity {
            case .ultraLight: return .ultraThinMaterial
            case .light: return .thinMaterial
            case .medium: return .regularMaterial
            case .heavy: return .thickMaterial
            case .maximum: return .ultraThickMaterial
            }
        case .content:
            // Standard materials for content clarity and readability
            switch intensity {
            case .ultraLight: return .ultraThinMaterial
            case .light: return .thinMaterial
            case .medium: return .regularMaterial
            case .heavy: return .regularMaterial  // Cap at regular for content readability
            case .maximum: return .thickMaterial  // Maximum for content should still be readable
            }
        }
    }
    
    /// Returns whether this layer type should use glass effects
    var shouldUseGlassEffects: Bool {
        switch self {
        case .functional: return true   // Glass effects for functional layers
        case .content: return false     // NO glass effects for content layers
        }
    }
    
    /// Returns appropriate text opacity for this layer type
    func textOpacity(for prominence: TextProminence = .primary) -> Double {
        switch self {
        case .functional:
            // Functional layer text needs high contrast over glass
            switch prominence {
            case .primary: return 0.95
            case .secondary: return 0.8
            case .tertiary: return 0.65
            case .hint: return 0.5
            }
        case .content:
            // Content layer text optimized for readability
            switch prominence {
            case .primary: return 1.0     // Maximum readability for content
            case .secondary: return 0.85
            case .tertiary: return 0.7
            case .hint: return 0.55
            }
        }
    }
}

/// Material intensity levels for both functional and content layers
enum MaterialIntensity {
    case ultraLight, light, medium, heavy, maximum
    
    var displayName: String {
        switch self {
        case .ultraLight: return "Ultra Light"
        case .light: return "Light"
        case .medium: return "Medium"
        case .heavy: return "Heavy"
        case .maximum: return "Maximum"
        }
    }
}

/// Text prominence levels for proper hierarchy
enum TextProminence {
    case primary, secondary, tertiary, hint
    
    var displayName: String {
        switch self {
        case .primary: return "Primary"
        case .secondary: return "Secondary"
        case .tertiary: return "Tertiary"
        case .hint: return "Hint"
        }
    }
}

// MARK: - Layer-Aware Theme Extensions
extension UnifiedThemeStore {
    /// Get appropriate background material for a specific layer type
    func backgroundMaterial(for layerType: LayerType, intensity: MaterialIntensity = .medium) -> Material {
        return layerType.backgroundMaterial(intensity: intensity)
    }
    
    /// Get appropriate text color with proper opacity for layer type
    func textColor(for layerType: LayerType, prominence: TextProminence = .primary) -> Color {
        let opacity = layerType.textOpacity(for: prominence)
        
        if currentTheme.isLiquidGlass, let liquidVariant = currentTheme.liquidGlassVariant {
            switch prominence {
            case .primary: return liquidVariant.colorDefinition.primary.color.opacity(opacity)
            case .secondary: return liquidVariant.colorDefinition.secondary.color.opacity(opacity)
            case .tertiary: return liquidVariant.colorDefinition.accent.color.opacity(opacity)
            case .hint: return liquidVariant.colorDefinition.secondary.color.opacity(opacity * 0.7)
            }
        } else {
            switch prominence {
            case .primary: return appTheme.primaryText.opacity(opacity)
            case .secondary: return appTheme.secondaryText.opacity(opacity)
            case .tertiary: return appTheme.primaryText.opacity(opacity * 0.7)
            case .hint: return appTheme.secondaryText.opacity(opacity * 0.6)
            }
        }
    }
    
    /// Check if glass effects are appropriate for this layer type
    func shouldUseGlass(for layerType: LayerType) -> Bool {
        return layerType.shouldUseGlassEffects && currentTheme.isLiquidGlass
    }
}

// MARK: - HIG Compliance Extensions
extension View {
    /// Apply layer-appropriate styling based on iOS 26 HIG guidelines
    func layerStyle(
        _ layerType: LayerType,
        intensity: MaterialIntensity = .medium,
        themeStore: UnifiedThemeStore
    ) -> some View {
        Group {
            if layerType.shouldUseGlassEffects && themeStore.currentTheme.isLiquidGlass {
                // Functional layer: Use glass effects
                self.background(themeStore.backgroundMaterial(for: layerType, intensity: intensity))
                    .liquidGlassCard(
                        material: LiquidGlassTheme.GlassMaterial.regular,
                        depth: .floating,
                        radius: .comfortable,
                        vibrancy: .medium
                    )
            } else {
                // Content layer or legacy theme: Use standard materials
                self.background(themeStore.backgroundMaterial(for: layerType, intensity: intensity))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }
    
    /// Quick access to layer-appropriate text styling
    func layerText(
        _ layerType: LayerType,
        prominence: TextProminence = .primary,
        themeStore: UnifiedThemeStore
    ) -> some View {
        self.foregroundColor(themeStore.textColor(for: layerType, prominence: prominence))
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