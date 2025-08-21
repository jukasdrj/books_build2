import SwiftUI

// MARK: - iOS 26 Liquid Glass Theme Variants
// Enhanced color palettes optimized for translucent materials and vibrancy

enum LiquidGlassVariant: String, CaseIterable, Identifiable {
    case crystalClear = "crystalClear"
    case auroraGlow = "auroraGlow"
    case deepOcean = "deepOcean"
    case forestMist = "forestMist"
    case sunsetBloom = "sunsetBloom"
    case shadowElegance = "shadowElegance"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .crystalClear: return "Crystal Clear"
        case .auroraGlow: return "Aurora Glow"
        case .deepOcean: return "Deep Ocean"
        case .forestMist: return "Forest Mist"
        case .sunsetBloom: return "Sunset Bloom"
        case .shadowElegance: return "Shadow Elegance"
        }
    }
    
    var emoji: String {
        switch self {
        case .crystalClear: return "💎"
        case .auroraGlow: return "🌟"
        case .deepOcean: return "🌊"
        case .forestMist: return "🌿"
        case .sunsetBloom: return "🌅"
        case .shadowElegance: return "🖤"
        }
    }
    
    var description: String {
        switch self {
        case .crystalClear: return "Pure, pristine clarity"
        case .auroraGlow: return "Magical, ethereal luminescence"
        case .deepOcean: return "Mysterious, profound depths"
        case .forestMist: return "Natural, organic serenity"
        case .sunsetBloom: return "Warm, romantic radiance"
        case .shadowElegance: return "Sophisticated, timeless grace"
        }
    }
    
    // Enhanced color system optimized for liquid glass materials
    var colorDefinition: LiquidGlassColorDefinition {
        switch self {
        case .crystalClear:
            return LiquidGlassColorDefinition(
                // Primary colors with enhanced vibrancy
                primary: VibrancyColor(
                    light: Color(red: 0.2, green: 0.6, blue: 1.0),
                    dark: Color(red: 0.4, green: 0.7, blue: 1.0),
                    vibrancy: 0.9
                ),
                secondary: VibrancyColor(
                    light: Color(red: 0.7, green: 0.9, blue: 1.0),
                    dark: Color(red: 0.6, green: 0.85, blue: 1.0),
                    vibrancy: 0.7
                ),
                accent: VibrancyColor(
                    light: Color(red: 0.0, green: 0.5, blue: 1.0),
                    dark: Color(red: 0.2, green: 0.6, blue: 1.0),
                    vibrancy: 1.0
                ),
                // Background materials
                background: GlassMaterial.ultraThin,
                surface: GlassMaterial.thin,
                card: GlassMaterial.regular
            )
            
        case .auroraGlow:
            return LiquidGlassColorDefinition(
                primary: VibrancyColor(
                    light: Color(red: 0.8, green: 0.3, blue: 1.0),
                    dark: Color(red: 0.9, green: 0.4, blue: 1.0),
                    vibrancy: 0.95
                ),
                secondary: VibrancyColor(
                    light: Color(red: 1.0, green: 0.6, blue: 0.8),
                    dark: Color(red: 1.0, green: 0.7, blue: 0.85),
                    vibrancy: 0.8
                ),
                accent: VibrancyColor(
                    light: Color(red: 0.6, green: 0.2, blue: 1.0),
                    dark: Color(red: 0.7, green: 0.3, blue: 1.0),
                    vibrancy: 1.0
                ),
                background: GlassMaterial.thin,
                surface: GlassMaterial.regular,
                card: GlassMaterial.thick
            )
            
        case .deepOcean:
            return LiquidGlassColorDefinition(
                primary: VibrancyColor(
                    light: Color(red: 0.0, green: 0.4, blue: 0.8),
                    dark: Color(red: 0.2, green: 0.6, blue: 1.0),
                    vibrancy: 0.85
                ),
                secondary: VibrancyColor(
                    light: Color(red: 0.0, green: 0.6, blue: 0.6),
                    dark: Color(red: 0.2, green: 0.8, blue: 0.8),
                    vibrancy: 0.75
                ),
                accent: VibrancyColor(
                    light: Color(red: 0.0, green: 0.3, blue: 0.9),
                    dark: Color(red: 0.1, green: 0.5, blue: 1.0),
                    vibrancy: 0.95
                ),
                background: GlassMaterial.regular,
                surface: GlassMaterial.thick,
                card: GlassMaterial.chrome
            )
            
        case .forestMist:
            return LiquidGlassColorDefinition(
                primary: VibrancyColor(
                    light: Color(red: 0.2, green: 0.7, blue: 0.3),
                    dark: Color(red: 0.3, green: 0.8, blue: 0.4),
                    vibrancy: 0.8
                ),
                secondary: VibrancyColor(
                    light: Color(red: 0.6, green: 0.8, blue: 0.4),
                    dark: Color(red: 0.7, green: 0.9, blue: 0.5),
                    vibrancy: 0.7
                ),
                accent: VibrancyColor(
                    light: Color(red: 0.1, green: 0.6, blue: 0.2),
                    dark: Color(red: 0.2, green: 0.7, blue: 0.3),
                    vibrancy: 0.9
                ),
                background: GlassMaterial.ultraThin,
                surface: GlassMaterial.thin,
                card: GlassMaterial.regular
            )
            
        case .sunsetBloom:
            return LiquidGlassColorDefinition(
                primary: VibrancyColor(
                    light: Color(red: 1.0, green: 0.5, blue: 0.2),
                    dark: Color(red: 1.0, green: 0.6, blue: 0.3),
                    vibrancy: 0.9
                ),
                secondary: VibrancyColor(
                    light: Color(red: 1.0, green: 0.7, blue: 0.5),
                    dark: Color(red: 1.0, green: 0.8, blue: 0.6),
                    vibrancy: 0.75
                ),
                accent: VibrancyColor(
                    light: Color(red: 0.9, green: 0.3, blue: 0.1),
                    dark: Color(red: 1.0, green: 0.4, blue: 0.2),
                    vibrancy: 0.95
                ),
                background: GlassMaterial.thin,
                surface: GlassMaterial.regular,
                card: GlassMaterial.thick
            )
            
        case .shadowElegance:
            return LiquidGlassColorDefinition(
                primary: VibrancyColor(
                    light: Color(red: 0.2, green: 0.2, blue: 0.2),
                    dark: Color(red: 0.9, green: 0.9, blue: 0.9),
                    vibrancy: 0.95
                ),
                secondary: VibrancyColor(
                    light: Color(red: 0.5, green: 0.5, blue: 0.5),
                    dark: Color(red: 0.7, green: 0.7, blue: 0.7),
                    vibrancy: 0.8
                ),
                accent: VibrancyColor(
                    light: Color(red: 0.1, green: 0.1, blue: 0.1),
                    dark: Color(red: 1.0, green: 1.0, blue: 1.0),
                    vibrancy: 1.0
                ),
                background: GlassMaterial.chrome,
                surface: GlassMaterial.thick,
                card: GlassMaterial.regular
            )
        }
    }
}

// MARK: - Enhanced Color System for Liquid Glass

struct VibrancyColor {
    let light: Color
    let dark: Color
    let vibrancy: Double // 0.0 - 1.0, controls material vibrancy
    
    @Environment(\.colorScheme) private var colorScheme
    
    var adaptive: Color {
        colorScheme == .dark ? dark : light
    }
    
    func withVibrancy(_ level: Double = 1.0) -> Color {
        adaptive.opacity(vibrancy * level)
    }
}

enum GlassMaterial: CaseIterable {
    case ultraThin
    case thin  
    case regular
    case thick
    case chrome
    
    var material: Material {
        switch self {
        case .ultraThin: return .ultraThinMaterial
        case .thin: return .thinMaterial
        case .regular: return .regularMaterial
        case .thick: return .thickMaterial
        case .chrome: return .regularMaterial // Will be .chromeGlass in iOS 26
        }
    }
}

struct LiquidGlassColorDefinition {
    let primary: VibrancyColor
    let secondary: VibrancyColor
    let accent: VibrancyColor
    let background: GlassMaterial
    let surface: GlassMaterial
    let card: GlassMaterial
    
    // Computed semantic colors
    var success: Color { Color.green.opacity(0.8) }
    var warning: Color { Color.orange.opacity(0.8) }
    var error: Color { Color.red.opacity(0.8) }
    var info: Color { primary.adaptive.opacity(0.7) }
    
    // Text colors with vibrancy
    var primaryText: Color { primary.withVibrancy(0.9) }
    var secondaryText: Color { secondary.withVibrancy(0.7) }
    var tertiaryText: Color { primary.withVibrancy(0.5) }
}

// MARK: - Cultural Diversity Colors Enhanced for Glass

extension CulturalRegion {
    func liquidGlassColor(theme: LiquidGlassVariant) -> VibrancyColor {
        switch self {
        case .africa:
            return VibrancyColor(
                light: Color(red: 0.9, green: 0.4, blue: 0.2),
                dark: Color(red: 1.0, green: 0.5, blue: 0.3),
                vibrancy: 0.85
            )
        case .asia:
            return VibrancyColor(
                light: Color(red: 0.8, green: 0.2, blue: 0.4),
                dark: Color(red: 0.9, green: 0.3, blue: 0.5),
                vibrancy: 0.8
            )
        case .europe:
            return VibrancyColor(
                light: Color(red: 0.2, green: 0.5, blue: 0.8),
                dark: Color(red: 0.3, green: 0.6, blue: 0.9),
                vibrancy: 0.75
            )
        case .northAmerica:
            return VibrancyColor(
                light: Color(red: 0.4, green: 0.7, blue: 0.3),
                dark: Color(red: 0.5, green: 0.8, blue: 0.4),
                vibrancy: 0.8
            )
        case .southAmerica:
            return VibrancyColor(
                light: Color(red: 0.9, green: 0.6, blue: 0.1),
                dark: Color(red: 1.0, green: 0.7, blue: 0.2),
                vibrancy: 0.85
            )
        case .oceania:
            return VibrancyColor(
                light: Color(red: 0.1, green: 0.6, blue: 0.9),
                dark: Color(red: 0.2, green: 0.7, blue: 1.0),
                vibrancy: 0.9
            )
        case .middleEast:
            return VibrancyColor(
                light: Color(red: 0.8, green: 0.5, blue: 0.2),
                dark: Color(red: 0.9, green: 0.6, blue: 0.3),
                vibrancy: 0.8
            )
        case .caribbean:
            return VibrancyColor(
                light: Color(red: 0.2, green: 0.8, blue: 0.6),
                dark: Color(red: 0.3, green: 0.9, blue: 0.7),
                vibrancy: 0.85
            )
        case .centralAsia:
            return VibrancyColor(
                light: Color(red: 0.6, green: 0.4, blue: 0.8),
                dark: Color(red: 0.7, green: 0.5, blue: 0.9),
                vibrancy: 0.8
            )
        case .indigenous:
            return VibrancyColor(
                light: Color(red: 0.5, green: 0.3, blue: 0.1),
                dark: Color(red: 0.6, green: 0.4, blue: 0.2),
                vibrancy: 0.9
            )
        case .antarctica:
            return VibrancyColor(
                light: Color(red: 0.8, green: 0.9, blue: 1.0),
                dark: Color(red: 0.7, green: 0.8, blue: 0.9),
                vibrancy: 0.6
            )
        case .international:
            return VibrancyColor(
                light: Color(red: 0.6, green: 0.6, blue: 0.6),
                dark: Color(red: 0.7, green: 0.7, blue: 0.7),
                vibrancy: 0.7
            )
        }
    }
}