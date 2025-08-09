import SwiftUI

/// A ViewModifier that applies the correct status bar style based on theme
struct StatusBarStyleModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @State private var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                updateStatusBarStyle()
            }
            .onChange(of: colorScheme) { oldValue, newValue in
                updateStatusBarStyle()
            }
            .onChange(of: themeManager.currentTheme) { oldTheme, newTheme in
                updateStatusBarStyle()
            }
    }
    
    private func updateStatusBarStyle() {
        DispatchQueue.main.async {
            // Get all windows and update their status bar style
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
            
            for window in windowScene.windows {
                window.rootViewController?.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
}

extension View {
    /// Applies theme-aware status bar styling
    func statusBarStyleThemed() -> some View {
        modifier(StatusBarStyleModifier())
    }
}
