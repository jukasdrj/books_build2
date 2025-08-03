import SwiftUI

// From ThemeVariant.swift
enum ThemeVariant: String, CaseIterable, Identifiable {
    case purpleBoho = "Purple Boho"
    case forestSage = "Forest Sage"
    case oceanBlues = "Ocean Blues"
    case sunsetWarmth = "Sunset Warmth"
    case monochromeElegance = "Monochrome Elegance"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
    
    var description: String {
        switch self {
        case .purpleBoho:
            return "Mystical, warm, creative vibes"
        case .forestSage:
            return "Earthy, grounding, natural tones"
        case .oceanBlues:
            return "Calming, expansive, peaceful"
        case .sunsetWarmth:
            return "Cozy, romantic, intimate feels"
        case .monochromeElegance:
            return "Sophisticated, minimalist, timeless"
        }
    }
    
    var emoji: String {
        switch self {
        case .purpleBoho: return "💜"
        case .forestSage: return "🌿"
        case .oceanBlues: return "🌊"
        case .sunsetWarmth: return "🌅"
        case .monochromeElegance: return "⚫"
        }
    }
    
    var previewGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: self.colorDefinition.previewColors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// From ThemeColorDefinitions.swift
extension ThemeVariant {
    var colorDefinition: ThemeColorDefinition {
        switch self {
        case .purpleBoho:
            return ThemeColorDefinition.purpleBoho
        case .forestSage:
            return ThemeColorDefinition.forestSage
        case .oceanBlues:
            return ThemeColorDefinition.oceanBlues
        case .sunsetWarmth:
            return ThemeColorDefinition.sunsetWarmth
        case .monochromeElegance:
            return ThemeColorDefinition.monochromeElegance
        }
    }
}

struct ThemeColorDefinition {
    let primary: (light: UIColor, dark: UIColor)
    let secondary: (light: UIColor, dark: UIColor)
    let tertiary: (light: UIColor, dark: UIColor)
    let surface: (light: UIColor, dark: UIColor)
    let background: (light: UIColor, dark: UIColor)
    let error: (light: UIColor, dark: UIColor)
    let success: (light: UIColor, dark: UIColor)
    let warning: (light: UIColor, dark: UIColor)
    
    var previewColors: [Color] {
        [
            Color(primary.light),
            Color(secondary.light),
            Color(tertiary.light)
        ]
    }
    
    // MARK: - Purple Boho (Current)
    static let purpleBoho = ThemeColorDefinition(
        primary: (
            light: UIColor(red: 0.45, green: 0.25, blue: 0.75, alpha: 1.0),
            dark: UIColor(red: 0.75, green: 0.60, blue: 0.95, alpha: 1.0)
        ),
        secondary: (
            light: UIColor(red: 0.65, green: 0.45, blue: 0.55, alpha: 1.0),
            dark: UIColor(red: 0.85, green: 0.70, blue: 0.80, alpha: 1.0)
        ),
        tertiary: (
            light: UIColor(red: 0.75, green: 0.55, blue: 0.35, alpha: 1.0),
            dark: UIColor(red: 0.95, green: 0.80, blue: 0.65, alpha: 1.0)
        ),
        surface: (
            light: UIColor(red: 0.98, green: 0.97, blue: 0.99, alpha: 1.0),
            dark: UIColor(red: 0.12, green: 0.10, blue: 0.15, alpha: 1.0)
        ),
        background: (
            light: UIColor.systemBackground,
            dark: UIColor.systemBackground
        ),
        error: (
            light: UIColor(red: 0.75, green: 0.25, blue: 0.35, alpha: 1.0),
            dark: UIColor(red: 0.95, green: 0.70, blue: 0.75, alpha: 1.0)
        ),
        success: (
            light: UIColor(red: 0.25, green: 0.65, blue: 0.45, alpha: 1.0),
            dark: UIColor(red: 0.60, green: 0.85, blue: 0.70, alpha: 1.0)
        ),
        warning: (
            light: UIColor(red: 0.85, green: 0.65, blue: 0.25, alpha: 1.0),
            dark: UIColor(red: 0.95, green: 0.80, blue: 0.55, alpha: 1.0)
        )
    )
    
    // MARK: - Forest Sage
    static let forestSage = ThemeColorDefinition(
        primary: (
            light: UIColor(red: 0.25, green: 0.45, blue: 0.35, alpha: 1.0), // Deep forest
            dark: UIColor(red: 0.65, green: 0.85, blue: 0.75, alpha: 1.0)   // Soft sage
        ),
        secondary: (
            light: UIColor(red: 0.55, green: 0.40, blue: 0.30, alpha: 1.0), // Warm brown
            dark: UIColor(red: 0.85, green: 0.80, blue: 0.75, alpha: 1.0)   // Cream
        ),
        tertiary: (
            light: UIColor(red: 0.70, green: 0.45, blue: 0.25, alpha: 1.0), // Burnt orange
            dark: UIColor(red: 0.95, green: 0.75, blue: 0.65, alpha: 1.0)   // Soft coral
        ),
        surface: (
            light: UIColor(red: 0.97, green: 0.98, blue: 0.96, alpha: 1.0),
            dark: UIColor(red: 0.15, green: 0.18, blue: 0.16, alpha: 1.0)
        ),
        background: (
            light: UIColor.systemBackground,
            dark: UIColor.systemBackground
        ),
        error: (
            light: UIColor(red: 0.70, green: 0.30, blue: 0.25, alpha: 1.0),
            dark: UIColor(red: 0.90, green: 0.70, blue: 0.65, alpha: 1.0)
        ),
        success: (
            light: UIColor(red: 0.30, green: 0.60, blue: 0.40, alpha: 1.0),
            dark: UIColor(red: 0.70, green: 0.90, blue: 0.80, alpha: 1.0)
        ),
        warning: (
            light: UIColor(red: 0.80, green: 0.60, blue: 0.20, alpha: 1.0),
            dark: UIColor(red: 0.95, green: 0.85, blue: 0.60, alpha: 1.0)
        )
    )
    
    // MARK: - Ocean Blues
    static let oceanBlues = ThemeColorDefinition(
        primary: (
            light: UIColor(red: 0.15, green: 0.35, blue: 0.65, alpha: 1.0), // Deep navy
            dark: UIColor(red: 0.70, green: 0.85, blue: 0.95, alpha: 1.0)   // Soft periwinkle
        ),
        secondary: (
            light: UIColor(red: 0.25, green: 0.55, blue: 0.60, alpha: 1.0), // Teal
            dark: UIColor(red: 0.75, green: 0.90, blue: 0.95, alpha: 1.0)   // Light aqua
        ),
        tertiary: (
            light: UIColor(red: 0.70, green: 0.45, blue: 0.55, alpha: 1.0), // Coral
            dark: UIColor(red: 0.95, green: 0.80, blue: 0.85, alpha: 1.0)   // Soft peach
        ),
        surface: (
            light: UIColor(red: 0.96, green: 0.98, blue: 0.99, alpha: 1.0),
            dark: UIColor(red: 0.10, green: 0.15, blue: 0.20, alpha: 1.0)
        ),
        background: (
            light: UIColor.systemBackground,
            dark: UIColor.systemBackground
        ),
        error: (
            light: UIColor(red: 0.70, green: 0.25, blue: 0.30, alpha: 1.0),
            dark: UIColor(red: 0.90, green: 0.70, blue: 0.75, alpha: 1.0)
        ),
        success: (
            light: UIColor(red: 0.20, green: 0.60, blue: 0.50, alpha: 1.0),
            dark: UIColor(red: 0.65, green: 0.90, blue: 0.85, alpha: 1.0)
        ),
        warning: (
            light: UIColor(red: 0.80, green: 0.55, blue: 0.25, alpha: 1.0),
            dark: UIColor(red: 0.95, green: 0.80, blue: 0.65, alpha: 1.0)
        )
    )
    
    // MARK: - Sunset Warmth
    static let sunsetWarmth = ThemeColorDefinition(
        primary: (
            light: UIColor(red: 0.55, green: 0.25, blue: 0.35, alpha: 1.0), // Deep burgundy
            dark: UIColor(red: 0.90, green: 0.75, blue: 0.80, alpha: 1.0)   // Soft rose
        ),
        secondary: (
            light: UIColor(red: 0.75, green: 0.55, blue: 0.25, alpha: 1.0), // Golden amber
            dark: UIColor(red: 0.95, green: 0.90, blue: 0.80, alpha: 1.0)   // Cream
        ),
        tertiary: (
            light: UIColor(red: 0.70, green: 0.40, blue: 0.25, alpha: 1.0), // Burnt orange
            dark: UIColor(red: 0.95, green: 0.80, blue: 0.70, alpha: 1.0)   // Soft apricot
        ),
        surface: (
            light: UIColor(red: 0.99, green: 0.97, blue: 0.95, alpha: 1.0),
            dark: UIColor(red: 0.20, green: 0.15, blue: 0.12, alpha: 1.0)
        ),
        background: (
            light: UIColor.systemBackground,
            dark: UIColor.systemBackground
        ),
        error: (
            light: UIColor(red: 0.75, green: 0.30, blue: 0.25, alpha: 1.0),
            dark: UIColor(red: 0.90, green: 0.75, blue: 0.70, alpha: 1.0)
        ),
        success: (
            light: UIColor(red: 0.35, green: 0.60, blue: 0.40, alpha: 1.0),
            dark: UIColor(red: 0.75, green: 0.90, blue: 0.80, alpha: 1.0)
        ),
        warning: (
            light: UIColor(red: 0.85, green: 0.65, blue: 0.30, alpha: 1.0),
            dark: UIColor(red: 0.95, green: 0.85, blue: 0.70, alpha: 1.0)
        )
    )
    
    // MARK: - Monochrome Elegance
    static let monochromeElegance = ThemeColorDefinition(
        primary: (
            light: UIColor(red: 0.20, green: 0.20, blue: 0.25, alpha: 1.0), // Charcoal
            dark: UIColor(red: 0.85, green: 0.85, blue: 0.88, alpha: 1.0)   // Soft gray
        ),
        secondary: (
            light: UIColor(red: 0.45, green: 0.45, blue: 0.50, alpha: 1.0), // Warm gray
            dark: UIColor(red: 0.75, green: 0.75, blue: 0.78, alpha: 1.0)   // Light gray
        ),
        tertiary: (
            light: UIColor(red: 0.75, green: 0.65, blue: 0.35, alpha: 1.0), // Gold accent
            dark: UIColor(red: 0.90, green: 0.85, blue: 0.70, alpha: 1.0)   // Champagne
        ),
        surface: (
            light: UIColor(red: 0.98, green: 0.98, blue: 0.99, alpha: 1.0),
            dark: UIColor(red: 0.15, green: 0.15, blue: 0.17, alpha: 1.0)
        ),
        background: (
            light: UIColor.systemBackground,
            dark: UIColor.systemBackground
        ),
        error: (
            light: UIColor(red: 0.65, green: 0.25, blue: 0.25, alpha: 1.0),
            dark: UIColor(red: 0.85, green: 0.70, blue: 0.70, alpha: 1.0)
        ),
        success: (
            light: UIColor(red: 0.25, green: 0.55, blue: 0.35, alpha: 1.0),
            dark: UIColor(red: 0.70, green: 0.85, blue: 0.75, alpha: 1.0)
        ),
        warning: (
            light: UIColor(red: 0.70, green: 0.55, blue: 0.25, alpha: 1.0),
            dark: UIColor(red: 0.90, green: 0.80, blue: 0.65, alpha: 1.0)
        )
    )
}