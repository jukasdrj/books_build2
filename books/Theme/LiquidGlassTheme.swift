import SwiftUI

// MARK: - iOS 26 Liquid Glass Design System
// Modern translucent design with depth, vibrancy, and fluid animations
// Following Apple's latest Liquid Glass aesthetic principles

struct LiquidGlassTheme {
    
    // MARK: - Material System
    enum GlassMaterial: CaseIterable {
        case ultraThin      // Most transparent, subtle depth
        case thin           // Light transparency with slight blur
        case regular        // Standard glass effect with moderate blur
        case thick          // Enhanced blur with stronger depth
        case chrome         // Metallic reflection with high vibrancy
        
        @available(iOS 26.0, *)
        var material: Material {
            switch self {
            case .ultraThin:
                return .ultraThinMaterial
            case .thin:
                return .thinMaterial
            case .regular:
                return .regularMaterial
            case .thick:
                return .thickMaterial
            case .chrome:
                return .regularMaterial // Fallback for now
            }
        }
        
        // Fallback for iOS < 26
        var fallbackMaterial: Material {
            switch self {
            case .ultraThin:
                return .ultraThinMaterial
            case .thin:
                return .thinMaterial
            case .regular:
                return .regularMaterial
            case .thick:
                return .thickMaterial
            case .chrome:
                return .regularMaterial // Fallback
            }
        }
    }
    
    // MARK: - Depth & Elevation System
    enum GlassDepth {
        case floating       // Subtle lift, minimal shadow
        case elevated       // Standard card depth
        case prominent      // Modal/sheet depth
        case immersive      // Full-screen depth
        
        var shadowRadius: CGFloat {
            switch self {
            case .floating: return 8
            case .elevated: return 16
            case .prominent: return 32
            case .immersive: return 64
            }
        }
        
        var shadowOpacity: Double {
            switch self {
            case .floating: return 0.1
            case .elevated: return 0.15
            case .prominent: return 0.25
            case .immersive: return 0.4
            }
        }
        
        var yOffset: CGFloat {
            switch self {
            case .floating: return 2
            case .elevated: return 4
            case .prominent: return 8
            case .immersive: return 16
            }
        }
    }
    
    // MARK: - Fluid Animation System
    enum FluidAnimation {
        case instant        // No animation, immediate
        case quick          // 0.15s - micro-interactions
        case smooth         // 0.3s - standard transitions
        case flowing        // 0.5s - page transitions
        case immersive      // 0.8s - full-screen changes
        
        var duration: TimeInterval {
            switch self {
            case .instant: return 0.0
            case .quick: return 0.15
            case .smooth: return 0.3
            case .flowing: return 0.5
            case .immersive: return 0.8
            }
        }
        
        var springAnimation: Animation {
            switch self {
            case .instant:
                return .linear(duration: 0)
            case .quick:
                return .spring(response: 0.4, dampingFraction: 0.9, blendDuration: 0.1)
            case .smooth:
                return .spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0.2)
            case .flowing:
                return .spring(response: 0.8, dampingFraction: 0.75, blendDuration: 0.3)
            case .immersive:
                return .spring(response: 1.0, dampingFraction: 0.7, blendDuration: 0.4)
            }
        }
    }
    
    // MARK: - Vibrancy & Color Enhancement
    enum VibrancyLevel {
        case subtle         // Light vibrancy for text/icons
        case medium         // Standard vibrancy for interactive elements  
        case prominent      // High vibrancy for primary actions
        case maximum        // Full vibrancy for hero elements
        
        var opacity: Double {
            switch self {
            case .subtle: return 0.6
            case .medium: return 0.8
            case .prominent: return 0.9
            case .maximum: return 1.0
            }
        }
    }
    
    // MARK: - Corner Radius System
    enum GlassRadius {
        case minimal        // 4pt - small elements
        case compact        // 8pt - buttons, chips
        case comfortable    // 12pt - cards, inputs
        case spacious       // 20pt - large cards
        case flowing        // 28pt - hero elements
        case continuous     // Full rounded (height/2)
        
        var value: CGFloat {
            switch self {
            case .minimal: return 4
            case .compact: return 8
            case .comfortable: return 12
            case .spacious: return 20
            case .flowing: return 28
            case .continuous: return 1000
            }
        }
    }
    
    // MARK: - Typography Enhancement
    static let typography = LiquidGlassTypography()
}

struct LiquidGlassTypography {
    // iOS 26 enhanced typography with improved readability
    let displayLarge = Font.system(size: 64, weight: .ultraLight, design: .rounded)
    let displayMedium = Font.system(size: 48, weight: .light, design: .rounded)
    let displaySmall = Font.system(size: 36, weight: .regular, design: .rounded)
    
    let headlineLarge = Font.system(size: 32, weight: .medium, design: .rounded)
    let headlineMedium = Font.system(size: 28, weight: .medium, design: .rounded)
    let headlineSmall = Font.system(size: 24, weight: .semibold, design: .rounded)
    
    let titleLarge = Font.system(size: 22, weight: .semibold, design: .rounded)
    let titleMedium = Font.system(size: 18, weight: .semibold, design: .rounded)
    let titleSmall = Font.system(size: 16, weight: .bold, design: .rounded)
    
    let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
    let bodyMedium = Font.system(size: 15, weight: .regular, design: .default)
    let bodySmall = Font.system(size: 13, weight: .regular, design: .default)
    
    let labelLarge = Font.system(size: 15, weight: .medium, design: .default)
    let labelMedium = Font.system(size: 13, weight: .medium, design: .default)
    let labelSmall = Font.system(size: 11, weight: .semibold, design: .default)
}

// MARK: - Liquid Glass View Modifiers

struct LiquidGlassCardModifier: ViewModifier {
    let material: LiquidGlassTheme.GlassMaterial
    let depth: LiquidGlassTheme.GlassDepth
    let radius: LiquidGlassTheme.GlassRadius
    let vibrancy: LiquidGlassTheme.VibrancyLevel
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius.value)
                    .fill(.regularMaterial.opacity(vibrancy.opacity))
                    .shadow(
                        color: .black.opacity(depth.shadowOpacity),
                        radius: depth.shadowRadius,
                        x: 0,
                        y: depth.yOffset
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: radius.value))
    }
}

struct LiquidGlassButtonModifier: ViewModifier {
    @Environment(\.appTheme) private var theme
    let style: LiquidGlassButtonStyle
    let isPressed: Bool
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundMaterial)
                    .shadow(
                        color: shadowColor,
                        radius: isPressed ? 4 : 8,
                        x: 0,
                        y: isPressed ? 2 : 4
                    )
            )
            .foregroundColor(foregroundColor)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPressed)
    }
    
    private var backgroundMaterial: Material {
        switch style {
        case .primary:
            return .regularMaterial
        case .secondary:
            return .thinMaterial
        case .tertiary:
            return .ultraThinMaterial
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .primary:
            return theme.primaryText
        case .secondary:
            return theme.secondaryText
        case .tertiary:
            return theme.primaryText.opacity(0.8)
        }
    }
    
    private var shadowColor: Color {
        theme.primary.opacity(0.2)
    }
}

enum LiquidGlassButtonStyle {
    case primary
    case secondary
    case tertiary
}

// MARK: - View Extensions for Liquid Glass

extension View {
    func liquidGlassCard(
        material: LiquidGlassTheme.GlassMaterial = .regular,
        depth: LiquidGlassTheme.GlassDepth = .elevated,
        radius: LiquidGlassTheme.GlassRadius = .comfortable,
        vibrancy: LiquidGlassTheme.VibrancyLevel = .medium
    ) -> some View {
        self.modifier(LiquidGlassCardModifier(
            material: material,
            depth: depth,
            radius: radius,
            vibrancy: vibrancy
        ))
    }
    
    func liquidGlassButton(
        style: LiquidGlassButtonStyle = .primary,
        isPressed: Bool = false
    ) -> some View {
        self.modifier(LiquidGlassButtonModifier(
            style: style,
            isPressed: isPressed
        ))
    }
    
    func liquidGlassAnimation(_ animation: LiquidGlassTheme.FluidAnimation) -> some View {
        self.animation(animation.springAnimation, value: UUID())
    }
    
    // Enhanced vibrancy effect
    func liquidGlassVibrancy(_ level: LiquidGlassTheme.VibrancyLevel = .medium) -> some View {
        self
            .opacity(level.opacity)
            .blur(radius: 0.5)
            .brightness(0.1)
    }
}

// MARK: - iOS 26 Native TabView Integration

@available(iOS 26.0, *)
struct LiquidGlassTabView: View {
    @Binding var selectedTab: Int
    let libraryCount: Int
    let completedBooksCount: Int
    
    var body: some View {
        TabView(selection: $selectedTab) {
            LibraryView()
                .tabItem {
                    Label("Library", systemImage: "books.vertical")
                }
                .badge(libraryCount > 0 ? libraryCount : 0)
                .tag(0)
            
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(1)
            
            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }
                .badge(completedBooksCount > 0 ? completedBooksCount : 0)
                .tag(2)
            
            CulturalDiversityView()
                .tabItem {
                    Label("Culture", systemImage: "globe.americas")
                }
                .tag(3)
        }
        .tabViewStyle(.automatic) // Fallback to automatic style
        .tint(.primary)
    }
}

// MARK: - Accessibility Enhancements

extension LiquidGlassTheme {
    @MainActor static func respectingAccessibility<T>(_ value: T, reducedMotion: T) -> T {
        #if os(iOS)
        return UIAccessibility.isReduceMotionEnabled ? reducedMotion : value
        #else
        return value
        #endif
    }
}