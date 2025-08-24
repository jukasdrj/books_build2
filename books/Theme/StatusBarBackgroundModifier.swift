import SwiftUI

/// A ViewModifier that extends the theme's background color behind the status bar
/// This ensures consistent theming throughout the app including the status bar area
struct StatusBarBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appTheme) private var currentTheme
    
    // Track theme changes
    @State private var currentThemeId = UUID()
    
    private var themeBackground: Color {
        currentTheme.background
    }
    
    func body(content: Content) -> some View {
        ZStack {
            // Background layer that extends behind the status bar
            // Use a solid color view to ensure it properly fills the status bar area
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Status bar area with theme background
                    themeBackground
                        .frame(height: geometry.safeAreaInsets.top)
                        .ignoresSafeArea(.all, edges: .top)
                    
                    // Rest of the background
                    themeBackground
                }
                .ignoresSafeArea(.all, edges: .all)
            }
            
            // Main content
            content
        }
        .background(themeBackground) // Ensure the entire view has the theme background
        .onChange(of: colorScheme) { _, _ in
            // Force view refresh when color scheme changes
            currentThemeId = UUID()
        }
        .id(currentThemeId) // Force complete view refresh on theme/scheme changes
    }
}

/// A specialized version for navigation views that need proper status bar theming
struct NavigationStatusBarBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appTheme) private var currentTheme
    
    private var themeBackground: Color {
        currentTheme.background
    }
    
    private var themeSurface: Color {
        currentTheme.surface
    }
    
    func body(content: Content) -> some View {
        content
            .toolbarBackground(themeSurface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .background(themeBackground.ignoresSafeArea())
    }
}

// MARK: - View Extensions

extension View {
    /// Applies a themed background that extends behind the status bar
    /// Use this on root views to ensure the status bar area matches the theme
    func themedStatusBarBackground() -> some View {
        modifier(StatusBarBackgroundModifier())
    }
    
    /// Applies navigation-specific status bar theming
    /// Use this on NavigationStack root views
    func navigationThemedStatusBar() -> some View {
        modifier(NavigationStatusBarBackgroundModifier())
    }
    
    /// Combines both status bar background theming and status bar style management
    /// This is the recommended modifier for root views
    func fullStatusBarTheming() -> some View {
        self
            .themedStatusBarBackground()
    }
}

// MARK: - Safe Area Themed Container

/// A container view that properly handles status bar theming for its content
struct ThemedContainer<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appTheme) private var currentTheme
    
    let content: Content
    let extendBehindStatusBar: Bool
    
    init(extendBehindStatusBar: Bool = true, @ViewBuilder content: () -> Content) {
        self.extendBehindStatusBar = extendBehindStatusBar
        self.content = content()
    }
    
    private var themeBackground: Color {
        currentTheme.background
    }
    
    var body: some View {
        if extendBehindStatusBar {
            ZStack {
                // Full background including status bar area
                themeBackground
                    .ignoresSafeArea()
                
                // Content with proper safe area handling
                content
                    .background(themeBackground)
            }
        } else {
            // Standard safe area respecting layout
            content
                .background(themeBackground)
        }
    }
}

// MARK: - Usage Helper

extension View {
    /// Wraps the view in a themed container that handles status bar background
    /// - Parameter extendBehindStatusBar: Whether to extend the theme background behind the status bar
    func inThemedContainer(extendBehindStatusBar: Bool = true) -> some View {
        ThemedContainer(extendBehindStatusBar: extendBehindStatusBar) {
            self
        }
    }
}
