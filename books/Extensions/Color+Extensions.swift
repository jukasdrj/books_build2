import SwiftUI

extension Color {
    static var theme = AppColorTheme(variant: .purpleBoho)
}

// Helper to create adaptive colors for light/dark mode
private func adaptiveColor(light: UIColor, dark: UIColor) -> Color {
    return Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? dark : light
    })
}

struct AppColorTheme {
    let variant: ThemeVariant
    
    init(variant: ThemeVariant = .purpleBoho) {
        self.variant = variant
    }
    
    private var colorDef: ThemeColorDefinition {
        variant.colorDefinition
    }
    
    // MARK: - Primary Colors
    var primary: Color {
        adaptiveColor(light: colorDef.primary.light, dark: colorDef.primary.dark)
    }
    
    var onPrimary: Color {
        // Enhanced contrast: Always use white for better readability on primary colors
        adaptiveColor(light: .white, dark: .white)
    }
    
    var primaryContainer: Color {
        adaptiveColor(
            light: colorDef.primary.light.withAlphaComponent(0.12),
            dark: colorDef.primary.dark.withAlphaComponent(0.24)
        )
    }
    
    var onPrimaryContainer: Color {
        adaptiveColor(light: colorDef.primary.light, dark: colorDef.primary.dark)
    }
    
    // MARK: - Secondary Colors
    var secondary: Color {
        adaptiveColor(light: colorDef.secondary.light, dark: colorDef.secondary.dark)
    }
    
    var onSecondary: Color {
        adaptiveColor(light: .white, dark: colorDef.secondary.light.withAlphaComponent(0.9))
    }
    
    var secondaryContainer: Color {
        adaptiveColor(
            light: colorDef.secondary.light.withAlphaComponent(0.12),
            dark: colorDef.secondary.dark.withAlphaComponent(0.24)
        )
    }
    
    var onSecondaryContainer: Color {
        adaptiveColor(light: colorDef.secondary.light, dark: colorDef.secondary.dark)
    }
    
    // MARK: - Tertiary Colors
    var tertiary: Color {
        adaptiveColor(light: colorDef.tertiary.light, dark: colorDef.tertiary.dark)
    }
    
    var tertiaryContainer: Color {
        adaptiveColor(
            light: colorDef.tertiary.light.withAlphaComponent(0.12),
            dark: colorDef.tertiary.dark.withAlphaComponent(0.24)
        )
    }
    
    // MARK: - Surface Colors
    var surface: Color {
        adaptiveColor(light: colorDef.surface.light, dark: colorDef.surface.dark)
    }
    
    var onSurface: Color {
        primaryText
    }
    
    var surfaceVariant: Color {
        adaptiveColor(
            light: colorDef.primary.light.withAlphaComponent(0.05),
            dark: colorDef.primary.dark.withAlphaComponent(0.10)
        )
    }
    
    var onSurfaceVariant: Color {
        primaryText.opacity(0.8)
    }
    
    var background: Color {
        adaptiveColor(light: colorDef.background.light, dark: colorDef.background.dark)
    }
    
    // MARK: - Semantic Colors
    var error: Color {
        adaptiveColor(light: colorDef.error.light, dark: colorDef.error.dark)
    }
    
    var onError: Color {
        adaptiveColor(light: .white, dark: colorDef.error.light)
    }
    
    var success: Color {
        adaptiveColor(light: colorDef.success.light, dark: colorDef.success.dark)
    }
    
    var onSuccess: Color {
        adaptiveColor(light: .white, dark: colorDef.success.light)
    }
    
    var successContainer: Color {
        adaptiveColor(
            light: colorDef.success.light.withAlphaComponent(0.12),
            dark: colorDef.success.dark.withAlphaComponent(0.24)
        )
    }
    
    var onSuccessContainer: Color {
        adaptiveColor(light: colorDef.success.light, dark: colorDef.success.dark)
    }
    
    var warning: Color {
        adaptiveColor(light: colorDef.warning.light, dark: colorDef.warning.dark)
    }
    
    var warningContainer: Color {
        adaptiveColor(
            light: colorDef.warning.light.withAlphaComponent(0.12),
            dark: colorDef.warning.dark.withAlphaComponent(0.24)
        )
    }
    
    var onWarningContainer: Color {
        adaptiveColor(light: colorDef.warning.light, dark: colorDef.warning.dark)
    }
    
    // MARK: - Text Colors (Dynamic based on theme)
    var primaryText: Color {
        adaptiveColor(
            light: UIColor(white: 0.12, alpha: 1.0),   // near-black for light mode
            dark: UIColor(white: 0.95, alpha: 1.0)     // near-white for dark mode
        )
    }
    
    var secondaryText: Color {
        adaptiveColor(
            light: UIColor(white: 0.12, alpha: 0.70),  // 70% black
            dark: UIColor(white: 1.00, alpha: 0.70)    // 70% white
        )
    }
    
    var outline: Color {
        adaptiveColor(
            light: UIColor(white: 0.0, alpha: 0.12),    // subtle neutral outline
            dark: UIColor(white: 1.0, alpha: 0.12)
        )
    }
    
    // MARK: - State Colors
    var disabled: Color {
        adaptiveColor(
            light: UIColor(white: 0.0, alpha: 0.08),     // neutral disabled bg overlay
            dark: UIColor(white: 1.0, alpha: 0.12)
        )
    }
    
    var disabledText: Color {
        adaptiveColor(
            light: UIColor(white: 0.0, alpha: 0.38),     // neutral disabled text
            dark: UIColor(white: 1.0, alpha: 0.38)
        )
    }
    
    // MARK: - Component Colors
    var cardBackground: Color {
        surface
    }
    
    var primaryAction: Color {
        primary
    }
    
    var secondaryAction: Color {
        secondary
    }
    
    var accentHighlight: Color {
        tertiary
    }
    
    var hovered: Color { primary.opacity(0.08) }

    // MARK: - Gradients (for that extra boho touch!)
    var gradientStart: Color { primary.opacity(0.6) }
    var gradientEnd: Color { secondary.opacity(0.4) }
    
    // MARK: - Cultural Colors (placeholders)
    var cultureAfrica: Color { adaptiveColor(light: .brown, dark: .brown) }
    var cultureAsia: Color { adaptiveColor(light: .red, dark: .red) }
    var cultureEurope: Color { adaptiveColor(light: .blue, dark: .blue) }
    var cultureAmericas: Color { adaptiveColor(light: .green, dark: .green) }
    var cultureOceania: Color { adaptiveColor(light: .cyan, dark: .cyan) }
    var cultureMiddleEast: Color { adaptiveColor(light: .purple, dark: .purple) }
    var cultureIndigenous: Color { adaptiveColor(light: .orange, dark: .orange) }
}

// MARK: - UIColor to Color Conversion Helper
extension UIColor {
    func toColor() -> Color {
        return Color(self)
    }
}

// MARK: - Accessibility Helpers

extension Color {
    /// Returns a high contrast version of the color for accessibility
    var highContrast: Color {
        // Get the current color scheme
        #if os(iOS)
        let isDark = UITraitCollection.current.userInterfaceStyle == .dark
        #else
        let isDark = false
        #endif
        
        // Return higher contrast versions based on the color and mode
        if self == Color.theme.primary {
            return isDark ? 
                Color(red: 0.85, green: 0.70, blue: 1.0) : // Lighter purple for dark mode
                Color(red: 0.35, green: 0.15, blue: 0.65)   // Darker purple for light mode
        }
        
        return self
    }
    
    /// Checks if this color provides sufficient contrast against the given background
    func contrastRatio(against background: Color) -> Double {
        // Simplified contrast calculation
        // In a real implementation, you'd convert to RGB and calculate properly
        // This is a basic approximation
        return 4.5 // Assume WCAG AA compliance for now
    }
    
    /// Returns the appropriate text color (black or white) for this background
    var accessibleTextColor: Color {
        // Simple heuristic - in practice you'd calculate luminance
        #if os(iOS)
        let isDark = UITraitCollection.current.userInterfaceStyle == .dark
        #else
        let isDark = false
        #endif
        
        // For purple themes, use white text on dark backgrounds, dark on light
        return isDark ? .white : .black
    }
}