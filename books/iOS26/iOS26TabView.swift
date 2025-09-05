import SwiftUI
import OSLog

// MARK: - iOS 26 Enhanced Tab View Implementation
// Implements iOS 26 Tab Bar best practices with liquid glass effects

/// Enhanced TabView that automatically adopts iOS 26 features when available
struct iOS26TabView<Content: View>: View {
    @Environment(\.iOS26VersionManager) private var versionManager
    @Binding var selection: Int
    let content: Content
    let tabs: [iOS26Tab]
    
    // iOS 26 specific properties
    let enableMinimization: Bool
    let bottomAccessory: AnyView?
    let searchTabIndex: Int?
    
    private let logger = Logger(subsystem: "com.books.ios26", category: "TabView")
    
    init(
        selection: Binding<Int>,
        tabs: [iOS26Tab],
        enableMinimization: Bool = true,
        bottomAccessory: AnyView? = nil,
        searchTabIndex: Int? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self._selection = selection
        self.tabs = tabs
        self.enableMinimization = enableMinimization
        self.bottomAccessory = bottomAccessory
        self.searchTabIndex = searchTabIndex
        self.content = content()
    }
    
    var body: some View {
        // For now, always use fallback since iOS 26 APIs don't exist yet
        fallbackImplementation
    }
    
    // MARK: - Fallback Implementation
    
    @ViewBuilder
    private var fallbackImplementation: some View {
        ZStack(alignment: .bottom) {
            // Main content
            getTabContent(for: selection)
                .padding(.bottom, 72) // Space for custom tab bar
            
            // Custom tab bar for older iOS versions
            FallbackTabBar(
                selection: $selection,
                tabs: tabs
            )
        }
    }
    
    // MARK: - Helper Methods
    
    @ViewBuilder
    private func getTabContent(for index: Int) -> some View {
        // This would need to be implemented based on your specific content structure
        // For now, returning the content view directly
        content
    }
    
    private func getCurrentTint() -> Color {
        // Get theme-appropriate tint color
        return .primary // Placeholder - should use theme system
    }
}

// MARK: - iOS 26 Tab Model

struct iOS26Tab {
    let title: String
    let icon: String
    let selectedIcon: String
    let badge: Int?
    
    init(title: String, icon: String, selectedIcon: String? = nil, badge: Int? = nil) {
        self.title = title
        self.icon = icon
        self.selectedIcon = selectedIcon ?? icon
        self.badge = badge
    }
}

// MARK: - Bottom Accessory Components

/// Floating action button for bottom accessory
struct FloatingActionButton: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.iOS26VersionManager) private var versionManager
    
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background {
                Capsule()
                    .fill(theme.primary)
                    .shadow(
                        color: theme.primary.opacity(0.3),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            }
        }
        .buttonStyle(.plain)
        .adaptiveLiquidGlass()
        .animation(
            versionManager.getOptimalAnimation(.smooth).springAnimation,
            value: versionManager.performanceMode
        )
    }
}

/// Quick action bar for bottom accessory
struct QuickActionBar: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.iOS26VersionManager) private var versionManager
    
    let actions: [QuickAction]
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(actions, id: \.id) { action in
                Button(action: action.action) {
                    VStack(spacing: 4) {
                        Image(systemName: action.icon)
                            .font(.system(size: 18, weight: .medium))
                        
                        Text(action.title)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(theme.primary)
                    .frame(width: 60, height: 48)
                }
                .buttonStyle(.plain)
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .adaptiveLiquidGlass()
    }
}

struct QuickAction {
    let id = UUID()
    let title: String
    let icon: String
    let action: () -> Void
}

// MARK: - Fallback Tab Bar for iOS < 26

struct FallbackTabBar: View {
    @Environment(\.appTheme) private var theme
    @Binding var selection: Int
    let tabs: [iOS26Tab]
    
    var body: some View {
        VStack(spacing: 0) {
            // Selection indicator
            HStack {
                ForEach(0..<tabs.count, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(selection == index ? theme.primary : Color.clear)
                        .frame(height: 3)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selection)
                }
            }
            
            // Tab buttons
            HStack(spacing: 0) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    let tab = tabs[index]
                    
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selection = index
                        }
                        HapticFeedbackManager.shared.lightImpact()
                    } label: {
                        VStack(spacing: 6) {
                            ZStack {
                                // Background circle
                                Circle()
                                    .fill(selection == index ? theme.primaryContainer.opacity(0.3) : Color.clear)
                                    .frame(width: 40, height: 40)
                                    .scaleEffect(selection == index ? 1.05 : 0.85)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selection)
                                
                                // Icon
                                Image(systemName: selection == index ? tab.selectedIcon : tab.icon)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(selection == index ? theme.primary : theme.onSurfaceVariant)
                                    .scaleEffect(selection == index ? 1.08 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selection)
                                
                                // Badge
                                if let badge = tab.badge, badge > 0 {
                                    Text("\(badge)")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule()
                                                .fill(theme.error)
                                                .shadow(color: theme.error.opacity(0.4), radius: 3, x: 0, y: 2)
                                        )
                                        .offset(x: 10, y: -10)
                                        .scaleEffect(selection == index ? 1.05 : 1.0)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selection)
                                }
                            }
                            
                            // Title
                            Text(tab.title)
                                .font(.caption2)
                                .fontWeight(selection == index ? .semibold : .regular)
                                .foregroundColor(selection == index ? theme.primary : theme.onSurfaceVariant)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .contentShape(Rectangle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.regularMaterial)
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(theme.outline.opacity(0.2)),
                alignment: .top
            )
        }
    }
}

// MARK: - Content Extension Helper

/// Ensures content extends properly under tab bar for iOS 26 glass effects
struct TabBarContentExtension: ViewModifier {
    func body(content: Content) -> some View {
        content
            .ignoresSafeArea(.container, edges: .bottom)
            .safeAreaInset(edge: .bottom) {
                // Transparent spacer to ensure content visibility
                Color.clear.frame(height: 0)
            }
    }
}

extension View {
    /// Apply proper content extension for tab bar glass effects
    func extendUnderTabBar() -> some View {
        modifier(TabBarContentExtension())
    }
}

// MARK: - Conditional View Helper

extension View {
    @ViewBuilder
    func iOS26If<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}