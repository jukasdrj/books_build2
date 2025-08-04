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
        primary
    }
    
    var secondaryText: Color {
        secondary.opacity(0.8)
    }
    
    var outline: Color {
        primary.opacity(0.4)
    }
    
    // MARK: - State Colors
    var disabled: Color {
        Color.primary.opacity(0.12)
    }
    
    var disabledText: Color {
        Color.primary.opacity(0.38)
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