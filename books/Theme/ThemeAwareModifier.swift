import SwiftUI

// Add a notification name for theme changes
extension Notification.Name {
    static let themeDidChange = Notification.Name("ThemeDidChangeNotification")
}

/// A view modifier that ensures views update when the theme changes
struct ThemeAwareModifier: ViewModifier {
    @State private var themeManager = ThemeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    // Force views to update when theme changes
    @State private var themeUpdateTrigger = UUID()
    
    func body(content: Content) -> some View {
        content
            .onChange(of: colorScheme) { _, _ in
                // Refresh theme when system color scheme changes (light/dark mode)
                themeManager.refreshThemeForAppearanceChange()
            }
            .environment(\.appTheme, AppColorTheme(variant: themeManager.currentTheme))
            .id(themeUpdateTrigger) // Force view to fully rebuild on theme changes
            .onReceive(NotificationCenter.default.publisher(for: .themeDidChange)) { _ in
                // Force update when theme changes
                themeUpdateTrigger = UUID()
            }
    }
}

extension View {
    /// Applies theme awareness to a view, ensuring it updates when theme changes
    func themeAware() -> some View {
        modifier(ThemeAwareModifier())
    }
    
    /// Simple theme refresh modifier - forces view to use current theme colors
    func withCurrentTheme() -> some View {
        self.environment(\.appTheme, Color.currentTheme)
    }
}
