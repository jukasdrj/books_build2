import SwiftUI

// A central place for all our design system values
enum Theme {

    // MARK: - Colors
    // This enum makes it easy and safe to use our custom colors from the Asset Catalog.
    // Example Usage: `Theme.Color.PrimaryAction`
    enum Color {
        static let PrimaryAction = SwiftUI.Color("Theme/PrimaryAction")
        static let Surface = SwiftUI.Color("Theme/Surface")
        static let CardBackground = SwiftUI.Color("Theme/CardBackground")
        static let PrimaryText = SwiftUI.Color("Theme/PrimaryText")
        static let SecondaryText = SwiftUI.Color("Theme/SecondaryText")
        static let AccentHighlight = SwiftUI.Color("Theme/AccentHighlight")
        
        // Additional Material Design 3 colors
        static let Success = SwiftUI.Color.green
        static let Warning = SwiftUI.Color.orange
        static let Error = SwiftUI.Color.red
        static let OnSurface = PrimaryText
        static let Outline = SwiftUI.Color.gray.opacity(0.3)
        static let SurfaceVariant = CardBackground
    }
    
    // MARK: - Typography Scale (Material Design 3)
    enum Typography {
        // Display styles
        static let displayLarge = Font.system(size: 57, weight: .regular)
        static let displayMedium = Font.system(size: 45, weight: .regular)
        static let displaySmall = Font.system(size: 36, weight: .regular)
        
        // Headline styles
        static let headlineLarge = Font.system(size: 32, weight: .regular)
        static let headlineMedium = Font.system(size: 28, weight: .regular)
        static let headlineSmall = Font.system(size: 24, weight: .regular)
        
        // Title styles
        static let titleLarge = Font.system(size: 22, weight: .regular)
        static let titleMedium = Font.system(size: 16, weight: .medium)
        static let titleSmall = Font.system(size: 14, weight: .medium)
        
        // Body styles
        static let bodyLarge = Font.system(size: 16, weight: .regular)
        static let bodyMedium = Font.system(size: 14, weight: .regular)
        static let bodySmall = Font.system(size: 12, weight: .regular)
        
        // Label styles
        static let labelLarge = Font.system(size: 14, weight: .medium)
        static let labelMedium = Font.system(size: 12, weight: .medium)
        static let labelSmall = Font.system(size: 11, weight: .medium)
    }
    
    // MARK: - Spacing System
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 24
    }
    
    // MARK: - Animations
    enum Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let gentle = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.8)
        static let bouncy = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.6)
    }
    
    // MARK: - Shadows
    enum Shadow {
        static let small = (color: SwiftUI.Color.black.opacity(0.08), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
        static let medium = (color: SwiftUI.Color.black.opacity(0.12), radius: CGFloat(8), x: CGFloat(0), y: CGFloat(4))
        static let large = (color: SwiftUI.Color.black.opacity(0.16), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(8))
    }
}

// MARK: - Typography View Modifiers
extension View {
    // Display styles
    func displayLarge() -> some View {
        self.font(Theme.Typography.displayLarge)
    }
    
    func displayMedium() -> some View {
        self.font(Theme.Typography.displayMedium)
    }
    
    func displaySmall() -> some View {
        self.font(Theme.Typography.displaySmall)
    }
    
    // Headline styles
    func headlineLarge() -> some View {
        self.font(Theme.Typography.headlineLarge)
    }
    
    func headlineMedium() -> some View {
        self.font(Theme.Typography.headlineMedium)
    }
    
    func headlineSmall() -> some View {
        self.font(Theme.Typography.headlineSmall)
    }
    
    // Title styles
    func titleLarge() -> some View {
        self.font(Theme.Typography.titleLarge)
    }
    
    func titleMedium() -> some View {
        self.font(Theme.Typography.titleMedium)
    }
    
    func titleSmall() -> some View {
        self.font(Theme.Typography.titleSmall)
    }
    
    // Body styles
    func bodyLarge() -> some View {
        self.font(Theme.Typography.bodyLarge)
    }
    
    func bodyMedium() -> some View {
        self.font(Theme.Typography.bodyMedium)
    }
    
    func bodySmall() -> some View {
        self.font(Theme.Typography.bodySmall)
    }
    
    // Label styles
    func labelLarge() -> some View {
        self.font(Theme.Typography.labelLarge)
    }
    
    func labelMedium() -> some View {
        self.font(Theme.Typography.labelMedium)
    }
    
    func labelSmall() -> some View {
        self.font(Theme.Typography.labelSmall)
    }
}

// MARK: - Material Design 3 Component Styles
extension View {
    func materialCard(
        backgroundColor: Color = Theme.Color.CardBackground,
        cornerRadius: CGFloat = Theme.CornerRadius.medium,
        shadow: Bool = true
    ) -> some View {
        self
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .conditionalModifier(shadow) { view in
                view.shadow(
                    color: Theme.Shadow.medium.color,
                    radius: Theme.Shadow.medium.radius,
                    x: Theme.Shadow.medium.x,
                    y: Theme.Shadow.medium.y
                )
            }
    }
    
    func materialButton(
        style: MaterialButtonStyle = .filled,
        size: MaterialButtonSize = .medium
    ) -> some View {
        self.modifier(MaterialButtonModifier(style: style, size: size))
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

// MARK: - Material Button Styles
enum MaterialButtonStyle {
    case filled
    case tonal
    case outlined
    case text
}

enum MaterialButtonSize {
    case small
    case medium
    case large
    
    var height: CGFloat {
        switch self {
        case .small: return 32
        case .medium: return 40
        case .large: return 48
        }
    }
    
    var padding: EdgeInsets {
        switch self {
        case .small: return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        case .medium: return EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        case .large: return EdgeInsets(top: 12, leading: 24, bottom: 12, trailing: 24)
        }
    }
}

struct MaterialButtonModifier: ViewModifier {
    let style: MaterialButtonStyle
    let size: MaterialButtonSize
    
    func body(content: Content) -> some View {
        content
            .padding(size.padding)
            .frame(minHeight: size.height)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(Theme.CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
    }
    
    private var backgroundColor: Color {
        switch style {
        case .filled: return Theme.Color.PrimaryAction
        case .tonal: return Theme.Color.PrimaryAction.opacity(0.12)
        case .outlined, .text: return Color.clear
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .filled: return .white
        case .tonal: return Theme.Color.PrimaryAction
        case .outlined, .text: return Theme.Color.PrimaryAction
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .outlined: return Theme.Color.Outline
        default: return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .outlined: return 1
        default: return 0
        }
    }
}