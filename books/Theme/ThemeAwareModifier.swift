import SwiftUI

// Add a notification name for theme changes
extension Notification.Name {
    static let themeDidChange = Notification.Name("ThemeDidChangeNotification")
}

/// An optimized view modifier that ensures efficient theme updates without expensive view rebuilds
struct ThemeAwareModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appTheme) private var currentTheme
    @Environment(\.unifiedThemeStore) private var unifiedThemeStore
    
    func body(content: Content) -> some View {
        content
            .environment(\.appTheme, unifiedThemeStore.appTheme)
            .animation(.easeInOut(duration: 0.3), value: unifiedThemeStore.currentTheme)
            .animation(.easeInOut(duration: 0.3), value: colorScheme)
            // Removed .id() - let SwiftUI handle efficient updates naturally
    }
}

extension View {
    /// Applies theme awareness to a view, ensuring it updates when theme changes
    func themeAware() -> some View {
        modifier(ThemeAwareModifier())
    }
    
    /// Simple theme refresh modifier - forces view to use current theme colors
    func withCurrentTheme() -> some View {
        self.environment(\.appTheme, UnifiedThemeStore().appTheme)
    }
}
