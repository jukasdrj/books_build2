// Example Usage of the Updated StatusBarStyleManager
// This demonstrates how to use the new updateStyle method

import SwiftUI

// Example 1: Using in a SwiftUI View
struct ContentView: View {
    @State private var selectedTheme: ThemeVariant = .purpleBoho
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            Text("Current Theme: \(selectedTheme.displayName)")
            
            // Theme picker or other content
        }
        .onAppear {
            updateStatusBarStyle()
        }
        .onChange(of: selectedTheme) { _ in
            updateStatusBarStyle()
        }
        .onChange(of: colorScheme) { _ in
            updateStatusBarStyle()
        }
    }
    
    private func updateStatusBarStyle() {
        // Update the status bar style based on current theme and color scheme
        StatusBarStyleManager.shared.updateStyle(
            for: selectedTheme,
            colorScheme: colorScheme
        )
    }
}

// Example 2: Using in a Theme Manager
class ThemeManager {
    func applyTheme(_ theme: ThemeVariant, colorScheme: ColorScheme) {
        // Apply other theme settings...
        
        // Update status bar style
        StatusBarStyleManager.shared.updateStyle(
            for: theme,
            colorScheme: colorScheme
        )
    }
}

// Example 3: Handling system appearance changes
extension View {
    func handleThemeAndStatusBar(theme: ThemeVariant) -> some View {
        self
            .preferredColorScheme(nil) // Let system handle light/dark mode
            .onReceive(NotificationCenter.default.publisher(
                for: UIApplication.didBecomeActiveNotification
            )) { _ in
                // Get current color scheme from UITraitCollection
                let currentColorScheme = UITraitCollection.current.userInterfaceStyle == .dark 
                    ? ColorScheme.dark 
                    : ColorScheme.light
                
                // Update status bar when app becomes active
                StatusBarStyleManager.shared.updateStyle(
                    for: theme,
                    colorScheme: currentColorScheme
                )
            }
    }
}

// How the calculation works:
// 1. The method gets the appropriate background color (light or dark) based on the current color scheme
// 2. It calculates the luminance using the WCAG formula for accessibility
// 3. If luminance < 0.5 (dark background), it uses .lightContent (white status bar text)
// 4. If luminance >= 0.5 (light background), it uses .darkContent (black status bar text)
//
// This ensures the status bar text is always readable against the theme's background color
