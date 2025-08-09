import SwiftUI
import Combine

// MARK: - Theme System Fix Documentation
/*
 This file addresses the core theme system issues:
 
 1. Theme transitions not working smoothly
 2. Views not updating correctly when themes change
 3. Library view showing multiple colors
 4. Light/dark mode transitions being broken
 
 The solution involves:
 - A centralized theme observable object
 - Proper notification system for theme changes
 - Force view updates using ID changes
 - Better coordination between SwiftUI and UIKit theme updates
 */

// MARK: - Enhanced Theme Observer
class EnhancedThemeObserver: ObservableObject {
    static let shared = EnhancedThemeObserver()
    
    @Published var currentTheme: ThemeVariant {
        didSet {
            // Update the main theme manager
            ThemeManager.shared.currentTheme = currentTheme
            
            // Update the static Color.theme reference
            Color.theme = AppColorTheme(variant: currentTheme)
            
            // Force global theme refresh
            ThemeSystemHealthCheck.forceGlobalThemeRefresh()
        }
    }
    
    private init() {
        self.currentTheme = ThemeManager.shared.currentTheme
    }
    
    func switchTheme(to theme: ThemeVariant) {
        guard theme != currentTheme else { return }
        
        withAnimation(.easeInOut(duration: 0.4)) {
            currentTheme = theme
        }
    }
}

// MARK: - Enhanced Theme Aware View Modifier
struct EnhancedThemeAwareModifier: ViewModifier {
    @ObservedObject private var themeObserver = EnhancedThemeObserver.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var refreshID = UUID()
    
    func body(content: Content) -> some View {
        content
            .environment(\.appTheme, AppColorTheme(variant: themeObserver.currentTheme))
            .id(refreshID) // Force complete view refresh on theme changes
            .onReceive(themeObserver.objectWillChange) { _ in
                // Force view refresh by changing ID
                refreshID = UUID()
            }
            .onChange(of: colorScheme) { _, _ in
                // Handle system appearance changes (light/dark mode)
                ThemeManager.shared.refreshThemeForAppearanceChange()
                refreshID = UUID()
            }
    }
}

// MARK: - Clean Theme Application Extension
extension View {
    /// Enhanced theme awareness with reliable updates
    func enhancedThemeAware() -> some View {
        modifier(EnhancedThemeAwareModifier())
    }
    
    /// Force immediate theme refresh - use sparingly
    func forceThemeRefresh() -> some View {
        let currentTheme = ThemeManager.shared.currentTheme
        return self
            .environment(\.appTheme, AppColorTheme(variant: currentTheme))
            .id(UUID()) // Force complete rebuild
    }
}

// MARK: - Theme Color Access Helper
extension Color {
    /// Always get the freshest theme colors
    static var freshTheme: AppColorTheme {
        AppColorTheme(variant: ThemeManager.shared.currentTheme)
    }
}

// MARK: - Theme System Health Check
struct ThemeSystemHealthCheck {
    static func diagnose() {
        print("🎨 Theme System Diagnosis:")
        print("   Current Theme: \(ThemeManager.shared.currentTheme.rawValue)")
        print("   Static Theme: \(Color.theme.variant.rawValue)")
        print("   Fresh Theme: \(Color.freshTheme.variant.rawValue)")
        
        let areThemesInSync = ThemeManager.shared.currentTheme == Color.theme.variant
        print("   Themes in sync: \(areThemesInSync ? "✅" : "❌")")
        
        if !areThemesInSync {
            print("   🔧 Fixing theme sync...")
            Color.theme = AppColorTheme(variant: ThemeManager.shared.currentTheme)
        }
    }
    
    static func forceGlobalThemeRefresh() {
        let currentTheme = ThemeManager.shared.currentTheme
        Color.theme = AppColorTheme(variant: currentTheme)
        NotificationCenter.default.post(name: .themeDidChange, object: nil)
        ThemeManager.shared.refreshSystemUI()
    }
}
