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
        adaptiveColor(light: .white, dark: colorDef.primary.light.withAlphaComponent(0.9))
    }
    
    var primaryContainer: Color {
        adaptiveColor(
            light: colorDef.primary.light.withAlphaComponent(0.12),
            dark: colorDef.primary.dark.withAlphaComponent(0.24)
        )
    }
    
    // MARK: - Secondary Colors
    var secondary: Color {
        adaptiveColor(light: colorDef.secondary.light, dark: colorDef.secondary.dark)
    }
    
    var secondaryContainer: Color {
        adaptiveColor(
            light: colorDef.secondary.light.withAlphaComponent(0.12),
            dark: colorDef.secondary.dark.withAlphaComponent(0.24)
        )
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
    
    var background: Color {
        adaptiveColor(light: colorDef.background.light, dark: colorDef.background.dark)
    }
    
    // MARK: - Semantic Colors
    var error: Color {
        adaptiveColor(light: colorDef.error.light, dark: colorDef.error.dark)
    }
    
    var success: Color {
        adaptiveColor(light: colorDef.success.light, dark: colorDef.success.dark)
    }
    
    var warning: Color {
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
    
    // MARK: - Component Colors
    var cardBackground: Color {
        surface
    }
    
    var primaryAction: Color {
        primary
    }
    
    var surfaceVariant: Color {
        adaptiveColor(
            light: colorDef.primary.light.withAlphaComponent(0.05),
            dark: colorDef.primary.dark.withAlphaComponent(0.10)
        )
    }
    
    var onSurface: Color {
        primaryText
    }

    // MARK: - Gradients (for that extra boho touch!)
    var gradientStart: Color { primary.opacity(0.6) }
    var gradientEnd: Color { secondary.opacity(0.4) }
}