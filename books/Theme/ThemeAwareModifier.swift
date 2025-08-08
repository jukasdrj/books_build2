import SwiftUI

/// A view modifier that ensures views update when the theme changes
struct ThemeAwareModifier: ViewModifier {
    @State private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .onChange(of: colorScheme) { _, _ in
                // Refresh theme when system color scheme changes (light/dark mode)
                themeManager.refreshThemeForAppearanceChange()
            }
            .environment(\.appTheme, AppColorTheme(variant: themeManager.currentTheme))
    }
}

extension View {
    /// Applies theme awareness to a view, ensuring it updates when theme changes
    func themeAware() -> some View {
        modifier(ThemeAwareModifier())
    }
}