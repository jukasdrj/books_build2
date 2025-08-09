import SwiftUI

// MARK: - Material Design 3 Theme System
// Comprehensive design system following Material Design 3 guidelines
// Optimized for reading tracking app with cultural diversity features

enum Theme {
    
    // MARK: - Typography Scale (Material Design 3)
    enum Typography {
        // Display styles - Large, prominent text
        static let displayLarge = Font.system(size: 57, weight: .light, design: .default)
        static let displayMedium = Font.system(size: 45, weight: .light, design: .default)
        static let displaySmall = Font.system(size: 36, weight: .regular, design: .default)
        
        // Headline styles - High-emphasis text
        static let headlineLarge = Font.system(size: 32, weight: .medium, design: .default)
        static let headlineMedium = Font.system(size: 28, weight: .medium, design: .default)
        static let headlineSmall = Font.system(size: 24, weight: .medium, design: .default)
        
        // Title styles - Medium-emphasis text
        static let titleLarge = Font.system(size: 22, weight: .semibold, design: .default)
        static let titleMedium = Font.system(size: 16, weight: .semibold, design: .default)
        static let titleSmall = Font.system(size: 14, weight: .semibold, design: .default)
        
        // Body styles - Main content text
        static let bodyLarge = Font.system(size: 16, weight: .regular, design: .default)
        static let bodyMedium = Font.system(size: 14, weight: .regular, design: .default)
        static let bodySmall = Font.system(size: 12, weight: .regular, design: .default)
        
        // Label styles - Component text
        static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)
        static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)
        static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)
        
        // Reading-specific typography
        static let bookTitle = Font.system(size: 18, weight: .semibold, design: .serif)
        static let authorName = Font.system(size: 14, weight: .medium, design: .default)
        static let readingStats = Font.system(size: 16, weight: .semibold, design: .rounded)
        static let culturalTag = Font.system(size: 12, weight: .medium, design: .default)
    }
    
    // MARK: - Spacing System (8pt grid)
    enum Spacing {
        static let xs: CGFloat = 4      // 0.5 units
        static let sm: CGFloat = 8      // 1 unit
        static let md: CGFloat = 16     // 2 units
        static let lg: CGFloat = 24     // 3 units
        static let xl: CGFloat = 32     // 4 units
        static let xxl: CGFloat = 48    // 6 units
        static let xxxl: CGFloat = 64   // 8 units
        
        // Component-specific spacing
        static let cardPadding: CGFloat = 16
        static let sectionSpacing: CGFloat = 24
        static let itemSpacing: CGFloat = 12
        static let iconSpacing: CGFloat = 8
    }
    
    // MARK: - Corner Radius System
    enum CornerRadius {
        static let none: CGFloat = 0
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 28
        static let full: CGFloat = 1000  // For fully rounded elements
        
        // Component-specific radii
        static let card: CGFloat = 12
        static let button: CGFloat = 20
        static let chip: CGFloat = 16
        static let fab: CGFloat = 16
    }
    
    // MARK: - Elevation System (Shadows)
    enum Elevation {
        static let level0 = (color: SwiftUI.Color.black.opacity(0), radius: CGFloat(0), x: CGFloat(0), y: CGFloat(0))
        static let level1 = (color: SwiftUI.Color.black.opacity(0.05), radius: CGFloat(1), x: CGFloat(0), y: CGFloat(1))
        static let level2 = (color: SwiftUI.Color.black.opacity(0.08), radius: CGFloat(3), x: CGFloat(0), y: CGFloat(1))
        static let level3 = (color: SwiftUI.Color.black.opacity(0.11), radius: CGFloat(6), x: CGFloat(0), y: CGFloat(2))
        static let level4 = (color: SwiftUI.Color.black.opacity(0.12), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        static let level5 = (color: SwiftUI.Color.black.opacity(0.14), radius: CGFloat(12), x: CGFloat(0), y: CGFloat(8))
        
        // Component-specific elevations
        static let card = level1
        static let fab = level3
        static let navigationBar = level2
        static let modal = level5
    }
    
    // MARK: - Animation System
    enum Animation {
        // Duration constants
        static let quick: TimeInterval = 0.1
        static let standard: TimeInterval = 0.2
        static let emphasized: TimeInterval = 0.5
        static let extended: TimeInterval = 1.0
        
        // Animation presets
        static let fastEaseIn = SwiftUI.Animation.easeIn(duration: quick)
        static let fastEaseOut = SwiftUI.Animation.easeOut(duration: quick)
        static let standardEaseInOut = SwiftUI.Animation.easeInOut(duration: standard)
        static let emphasizedDecelerate = SwiftUI.Animation.easeOut(duration: emphasized)
        static let emphasizedAccelerate = SwiftUI.Animation.easeIn(duration: emphasized)
        
        // Spring animations for organic feel
        static let gentleSpring = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.8)
        static let bouncySpring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
        static let playfulSpring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
        
        // Page transitions
        static let pageTransition = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let modalPresentation = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.9)
        
        // Add smooth animation
        static let smooth = SwiftUI.Animation.easeInOut(duration: standard)
        
        // MARK: - Accessibility-Aware Animations
        
        /// Returns animation that respects reduce motion preference
        static func respectingReduceMotion(_ animation: SwiftUI.Animation?) -> SwiftUI.Animation? {
            #if os(iOS)
            return UIAccessibility.isReduceMotionEnabled ? nil : animation
            #else
            return animation
            #endif
        }
        
        /// Standard animation that respects accessibility preferences
        static var accessible: SwiftUI.Animation? {
            respectingReduceMotion(standardEaseInOut)
        }
        
        /// Gentle animation that respects accessibility preferences
        static var accessibleSpring: SwiftUI.Animation? {
            respectingReduceMotion(gentleSpring)
        }
    }
    
    // MARK: - Size System
    enum Size {
        // Touch target sizes
        static let minTouchTarget: CGFloat = 44
        static let preferredTouchTarget: CGFloat = 48
        
        // Icon sizes
        static let iconSmall: CGFloat = 16
        static let iconMedium: CGFloat = 24
        static let iconLarge: CGFloat = 32
        static let iconXLarge: CGFloat = 48
        
        // Component heights
        static let buttonHeight: CGFloat = 40
        static let inputHeight: CGFloat = 48
        static let navigationBarHeight: CGFloat = 56
        static let tabBarHeight: CGFloat = 64
        
        // Card and layout sizes
        static let cardMinHeight: CGFloat = 120
        static let bookCoverWidth: CGFloat = 80
        static let bookCoverHeight: CGFloat = 120
        static let profileImageSize: CGFloat = 40
    }
    
    // MARK: - Color Aliases
    // This enum makes it easy and safe to use our custom colors from the Asset Catalog.
    // Example Usage: `Color.theme.primaryAction`
    // The actual color definitions are in `Color+Extensions.swift`.
    enum Color {
        static let PrimaryAction = SwiftUI.Color.theme.primaryAction
        static let Surface = SwiftUI.Color.theme.surface
        static let CardBackground = SwiftUI.Color.theme.cardBackground
        static let PrimaryText = SwiftUI.Color.theme.primaryText
        static let SecondaryText = SwiftUI.Color.theme.secondaryText
        static let AccentHighlight = SwiftUI.Color.theme.tertiary
        
        // Additional Material Design 3 colors
        static let Success = SwiftUI.Color.theme.success
        static let Warning = SwiftUI.Color.theme.warning
        static let Error = SwiftUI.Color.theme.error
        static let OnSurface = SwiftUI.Color.theme.onSurface
        static let Outline = SwiftUI.Color.theme.outline
        static let SurfaceVariant = SwiftUI.Color.theme.surfaceVariant
    }
}

// MARK: - Theme-Aware Helpers
// We'll keep the material component helpers but simplify typography

struct ThemeAwareCardModifier: ViewModifier {
    @Environment(\.appTheme) private var currentTheme
    let cornerRadius: CGFloat
    let elevation: (color: SwiftUI.Color, radius: CGFloat, x: CGFloat, y: CGFloat)
    
    func body(content: Content) -> some View {
        content
            .background(currentTheme.cardBackground)
            .cornerRadius(cornerRadius)
            .shadow(
                color: elevation.color,
                radius: elevation.radius,
                x: elevation.x,
                y: elevation.y
            )
    }
}

struct ThemeAwareChipModifier: ViewModifier {
    @Environment(\.appTheme) private var currentTheme
    let isSelected: Bool
    let backgroundColor: SwiftUI.Color?
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                backgroundColor ?? (isSelected ? currentTheme.secondaryContainer : currentTheme.surfaceVariant)
            )
            .foregroundColor(
                isSelected ? currentTheme.onSecondaryContainer : currentTheme.onSurfaceVariant
            )
            .cornerRadius(Theme.CornerRadius.chip)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.chip)
                    .stroke(currentTheme.outline.opacity(isSelected ? 0 : 0.5), lineWidth: 0.5)
            )
    }
}

struct ThemeAwareFABModifier: ViewModifier {
    @Environment(\.appTheme) private var currentTheme
    let size: FABSize
    let backgroundColor: SwiftUI.Color?
    
    func body(content: Content) -> some View {
        content
            .frame(width: size.width, height: size.height)
            .background(backgroundColor ?? currentTheme.primaryAction)
            .foregroundColor(currentTheme.onPrimary)
            .cornerRadius(Theme.CornerRadius.fab)
            .shadow(
                color: Theme.Elevation.fab.color,
                radius: Theme.Elevation.fab.radius,
                x: Theme.Elevation.fab.x,
                y: Theme.Elevation.fab.y
            )
    }
}

// MARK: - Typography View Modifiers
// Simple, direct approach using modifier pattern
struct TypographyModifier: ViewModifier {
    @Environment(\.appTheme) private var currentTheme
    let font: Font
    let color: (AppColorTheme) -> Color
    
    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundColor(color(currentTheme))
    }
}

extension View {
    // Display styles
    func displayLarge() -> some View {
        modifier(TypographyModifier(font: Theme.Typography.displayLarge, color: { $0.primaryText }))
    }
    
    func displayMedium() -> some View {
        modifier(TypographyModifier(font: Theme.Typography.displayMedium, color: { $0.primaryText }))
    }
    
    func displaySmall() -> some View {
        modifier(TypographyModifier(font: Theme.Typography.displaySmall, color: { $0.primaryText }))
    }
    
    // Headline styles
    func headlineLarge() -> some View {
        modifier(TypographyModifier(font: Theme.Typography.headlineLarge, color: { $0.primaryText }))
    }
    
    func headlineMedium() -> some View {
        modifier(TypographyModifier(font: Theme.Typography.headlineMedium, color: { $0.primaryText }))
    }
    
    func headlineSmall() -> some View {
        modifier(TypographyModifier(font: Theme.Typography.headlineSmall, color: { $0.primaryText }))
    }
    
    // Title styles
    func titleLarge() -> some View {
        modifier(TypographyModifier(font: Theme.Typography.titleLarge, color: { $0.primaryText }))
    }
    
    func titleMedium() -> some View {
        modifier(TypographyModifier(font: Theme.Typography.titleMedium, color: { $0.primaryText }))
    }
    
    func titleSmall() -> some View {
        modifier(TypographyModifier(font: Theme.Typography.titleSmall, color: { $0.primaryText }))
    }
    
    // Body styles
    func bodyLarge() -> some View {
        modifier(TypographyModifier(font: Theme.Typography.bodyLarge, color: { $0.primaryText }))
    }
    
    func bodyMedium() -> some View {
        modifier(TypographyModifier(font: Theme.Typography.bodyMedium, color: { $0.primaryText }))
    }
    
    func bodySmall() -> some View {
        modifier(TypographyModifier(font: Theme.Typography.bodySmall, color: { $0.secondaryText }))
    }
    
    // Label styles
    func labelLarge() -> some View {
        modifier(TypographyModifier(font: Theme.Typography.labelLarge, color: { $0.primaryText }))
    }
    
    func labelMedium() -> some View {
        modifier(TypographyModifier(font: Theme.Typography.labelMedium, color: { $0.secondaryText }))
    }
    
    func labelSmall() -> some View {
        modifier(TypographyModifier(font: Theme.Typography.labelSmall, color: { $0.secondaryText }))
    }
    
    // Reading-specific styles
    func bookTitle() -> some View {
        modifier(TypographyModifier(font: Theme.Typography.bookTitle, color: { $0.primaryText }))
    }
    
    func authorName() -> some View {
        modifier(TypographyModifier(font: Theme.Typography.authorName, color: { $0.secondaryText }))
    }
    
    func readingStats() -> some View {
        modifier(TypographyModifier(font: Theme.Typography.readingStats, color: { $0.primary }))
    }
    
    func culturalTag() -> some View {
        modifier(TypographyModifier(font: Theme.Typography.culturalTag, color: { $0.onSecondaryContainer }))
    }
}

// MARK: - Material Design 3 Component Styles
extension View {
    
    // Card styles with proper elevation
    func materialCard(
        cornerRadius: CGFloat = Theme.CornerRadius.card,
        elevation: (color: SwiftUI.Color, radius: CGFloat, x: CGFloat, y: CGFloat) = Theme.Elevation.card
    ) -> some View {
        self.modifier(ThemeAwareCardModifier(cornerRadius: cornerRadius, elevation: elevation))
    }
    
    // Enhanced button styles
    func materialButton(
        style: MaterialButtonStyle = .filled,
        size: MaterialButtonSize = .medium,
        isEnabled: Bool = true
    ) -> some View {
        self.modifier(MaterialButtonModifier(style: style, size: size, isEnabled: isEnabled))
    }
    
    // Chip style for tags and categories
    func materialChip(
        isSelected: Bool = false,
        backgroundColor: SwiftUI.Color? = nil
    ) -> some View {
        self.modifier(ThemeAwareChipModifier(isSelected: isSelected, backgroundColor: backgroundColor))
    }
    
    // Cultural diversity indicator
    func culturalIndicator(region: CulturalRegion, theme: AppColorTheme) -> some View {
        self
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(region.color(theme: theme).opacity(0.12))
            .foregroundColor(region.color(theme: theme))
            .cornerRadius(Theme.CornerRadius.small)
            .font(Theme.Typography.culturalTag)
    }
    
    // Reading status indicator
    func statusIndicator(status: ReadingStatus, theme: AppColorTheme) -> some View {
        self
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(status.containerColor(theme: theme))
            .foregroundColor(status.textColor(theme: theme))
            .cornerRadius(Theme.CornerRadius.small)
            .font(Theme.Typography.labelSmall)
    }
    
    // Floating Action Button
    func materialFAB(
        size: FABSize = .regular,
        backgroundColor: SwiftUI.Color? = nil
    ) -> some View {
        self.modifier(ThemeAwareFABModifier(size: size, backgroundColor: backgroundColor))
    }
    
    // Interactive state handling with enhanced Material Design 3 feedback
    func materialInteractive(
        pressedScale: CGFloat = 0.95,
        pressedOpacity: Double = 0.8
    ) -> some View {
        self.modifier(MaterialInteractiveModifier(
            pressedScale: pressedScale,
            pressedOpacity: pressedOpacity
        ))
    }
    
    // Helper for conditional modifiers
    @ViewBuilder
    func conditionalModifier<Content: View>(
        _ condition: Bool,
        transform: (Self) -> Content
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Enhanced Material Button System
enum MaterialButtonStyle {
    case filled        // High emphasis
    case tonal         // Medium emphasis  
    case outlined      // Medium emphasis
    case text          // Low emphasis
    case destructive   // Error actions
    case success       // Success actions
}

enum MaterialButtonSize {
    case small
    case medium
    case large
    
    var height: CGFloat {
        switch self {
        case .small: return 32
        case .medium: return 40
        case .large: return 56
        }
    }
    
    var padding: EdgeInsets {
        switch self {
        case .small: return EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        case .medium: return EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
        case .large: return EdgeInsets(top: 16, leading: 24, bottom: 16, trailing: 24)
        }
    }
    
    var iconSize: CGFloat {
        switch self {
        case .small: return 16
        case .medium: return 20
        case .large: return 24
        }
    }
}

enum FABSize {
    case small
    case regular
    case large
    
    var width: CGFloat {
        switch self {
        case .small: return 40
        case .regular: return 56
        case .large: return 96
        }
    }
    
    var height: CGFloat {
        switch self {
        case .small: return 40
        case .regular: return 56
        case .large: return 56
        }
    }
}

struct MaterialButtonModifier: ViewModifier {
    @Environment(\.appTheme) private var currentTheme
    let style: MaterialButtonStyle
    let size: MaterialButtonSize
    let isEnabled: Bool
    
    func body(content: Content) -> some View {
        content
            .padding(size.padding)
            .frame(minHeight: max(size.height, Theme.Size.minTouchTarget)) // Use Theme constant
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(Theme.CornerRadius.button)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.button)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .opacity(isEnabled ? 1.0 : 0.38)
            .disabled(!isEnabled)
            .animation(Theme.Animation.accessible, value: isEnabled) // Use accessibility-aware animation
            // Enhanced accessibility - Fixed syntax
            .accessibilityAddTraits(.isButton)
            .accessibilityRespondsToUserInteraction(isEnabled)
            .dynamicTypeSize(.large...DynamicTypeSize.accessibility3) // Support larger text
    }
    
    private var backgroundColor: SwiftUI.Color {
        guard isEnabled else { return currentTheme.disabled }
        
        switch style {
        case .filled:
            return currentTheme.primary
        case .tonal:
            return currentTheme.secondaryContainer
        case .outlined, .text:
            return SwiftUI.Color.clear
        case .destructive:
            return currentTheme.error
        case .success:
            return currentTheme.success
        }
    }
    
    private var foregroundColor: SwiftUI.Color {
        guard isEnabled else { return currentTheme.disabledText }
        
        switch style {
        case .filled:
            // Enhanced contrast: Always use white on filled buttons for better readability
            return SwiftUI.Color.white
        case .tonal:
            return currentTheme.onSecondaryContainer
        case .outlined, .text:
            return currentTheme.primary
        case .destructive:
            // Enhanced contrast: Always use white on destructive buttons
            return SwiftUI.Color.white
        case .success:
            // Enhanced contrast: Always use white on success buttons
            return SwiftUI.Color.white
        }
    }
    
    private var borderColor: SwiftUI.Color {
        guard isEnabled else { return currentTheme.outline.opacity(0.12) }
        
        switch style {
        case .outlined:
            return currentTheme.outline
        default:
            return SwiftUI.Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .outlined: return 1
        default: return 0
        }
    }
}

struct MaterialInteractiveModifier: ViewModifier {
    let pressedScale: CGFloat
    let pressedOpacity: Double
    
    @State private var isPressed = false
    @GestureState private var isGestureActive = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed || isGestureActive ? pressedScale : 1.0)
            .opacity(isPressed || isGestureActive ? pressedOpacity : 1.0)
            .animation(Theme.Animation.accessible, value: isPressed) // Use accessibility-aware animation
            .animation(Theme.Animation.accessible, value: isGestureActive) // Use accessibility-aware animation
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isGestureActive) { _, state, _ in
                        state = true
                    }
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
    }
}