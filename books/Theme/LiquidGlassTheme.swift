import SwiftUI

// MARK: - iOS 26 Liquid Glass Design System
// Modern translucent design with depth, vibrancy, and fluid animations
// Following Apple's latest Liquid Glass aesthetic principles

struct LiquidGlassTheme {
    
    // MARK: - Material System (Apple's Liquid Glass Aligned)
    enum GlassMaterial: CaseIterable {
        case ultraThin      // Most transparent, subtle depth
        case thin           // Light transparency with slight blur
        case regular        // Standard adaptive glass (Apple's "Regular" variant)
        case thick          // Enhanced blur with stronger depth
        case chrome         // Metallic reflection with high vibrancy
        case clear          // Apple's "Clear" variant - more transparent, content-rich
        
        var material: Material {
            switch self {
            case .ultraThin:
                return .ultraThinMaterial
            case .thin:
                return .thinMaterial
            case .regular:
                return .regularMaterial  // Apple's adaptive "Regular" variant
            case .thick:
                return .thickMaterial
            case .chrome:
                return .regularMaterial // Enhanced with chrome reflection overlay
            case .clear:
                return .ultraThinMaterial  // Apple's "Clear" variant - more transparent
            }
        }
        
        // Content adaptability factor (Apple's key principle)
        var adaptivityFactor: Double {
            switch self {
            case .ultraThin: return 0.3
            case .thin: return 0.5
            case .regular: return 0.8  // High adaptivity - Apple's recommendation
            case .thick: return 0.6
            case .chrome: return 0.9
            case .clear: return 0.2    // Low adaptivity to show content richness
            }
        }
        
        // Apple-optimized blur radius (≤25pt, recommended ≤3pt for 60fps)
        var blurRadius: CGFloat {
            switch self {
            case .ultraThin: return 0.5
            case .thin: return 1.0
            case .regular: return 1.5   // Apple optimized for 60fps performance
            case .thick: return 2.5     // Reduced for performance compliance
            case .chrome: return 1.0    // Minimal blur for chrome reflections
            case .clear: return 0.0     // No blur for content clarity
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
            case .floating: return 0.08   // Apple-refined subtle depth
            case .elevated: return 0.12   // Standard card elevation
            case .prominent: return 0.20  // Modal prominence
            case .immersive: return 0.35  // Full-screen depth
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
    
    // MARK: - Vibrancy & Color Enhancement (Apple's Performance-Optimized)
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
        
        // Apple-compliant blur (≤1.5pt for vibrancy effects)
        var blurRadius: CGFloat {
            switch self {
            case .subtle: return 0.1
            case .medium: return 0.3   // Apple-recommended light vibrancy
            case .prominent: return 0.6
            case .maximum: return 1.0  // Maximum within Apple guidelines
            }
        }
        
        // Content richness enhancement (Apple's key principle)
        var saturationBoost: Double {
            switch self {
            case .subtle: return 1.05
            case .medium: return 1.1
            case .prominent: return 1.15
            case .maximum: return 1.2
            }
        }
        
        var brightnessAdjustment: Double {
            switch self {
            case .subtle: return 0.02
            case .medium: return 0.05
            case .prominent: return 0.08
            case .maximum: return 0.1
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
    
    init(
        material: LiquidGlassTheme.GlassMaterial,
        depth: LiquidGlassTheme.GlassDepth,
        radius: LiquidGlassTheme.GlassRadius,
        vibrancy: LiquidGlassTheme.VibrancyLevel
    ) {
        self.material = material
        self.depth = depth
        self.radius = radius
        self.vibrancy = vibrancy
    }
    
    func body(content: Content) -> some View {
        // Always use standard SwiftUI effects (Metal acceleration disabled to prevent texture validation errors)
        content
            .background(
                RoundedRectangle(cornerRadius: radius.value)
                    .fill(
                        accessibleMaterial.material
                            .opacity(adaptiveOpacity)
                    )
                    .blur(radius: accessibleMaterial.blurRadius)
                    .shadow(
                        color: .black.opacity(depth.shadowOpacity),
                        radius: depth.shadowRadius,
                        x: 0,
                        y: depth.yOffset
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: radius.value))
    }
    
    // Apple's accessibility-aware material selection
    @MainActor private var accessibleMaterial: LiquidGlassTheme.GlassMaterial {
        LiquidGlassTheme.accessibleMaterial(material)
    }
    
    // Content-adaptive opacity combining material and vibrancy
    private var adaptiveOpacity: Double {
        material.adaptivityFactor * vibrancy.opacity
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
        case .glass:
            return .regularMaterial  // Apple's glass style - adaptive regular material
        case .floating:
            return .thinMaterial     // Lighter for floating effect
        case .adaptive:
            return .regularMaterial  // Content-adaptive material
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
        case .glass:
            return theme.primaryText.opacity(0.9)  // Apple's glass style
        case .floating:
            return theme.primaryText
        case .adaptive:
            return theme.primaryText.opacity(0.85) // Content-adaptive opacity
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
    case glass      // Apple's official .glass button style equivalent
    case floating   // Enhanced floating glass button
    case adaptive   // Content-adaptive button (Apple principle)
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
    
    // Standard SwiftUI flowing glass animation (Metal acceleration disabled)
    func liquidGlassFlowing(
        flowSpeed: Float = 1.0,
        waveAmplitude: Float = 0.02,
        enabled: Bool = true
    ) -> some View {
        // Always use standard SwiftUI effects
        return AnyView(self)
    }
    
    // Apple-aligned vibrancy effect (performance optimized)
    func liquidGlassVibrancy(_ level: LiquidGlassTheme.VibrancyLevel = .medium) -> some View {
        self
            .opacity(level.opacity)
            .blur(radius: level.blurRadius) // Performance-optimized blur
            .brightness(level.brightnessAdjustment)
            .saturation(level.saturationBoost) // Content richness enhancement
    }
    
    // Apple's glass effect equivalent
    func glassEffect(
        material: LiquidGlassTheme.GlassMaterial = .regular,
        vibrancy: LiquidGlassTheme.VibrancyLevel = .medium
    ) -> some View {
        self
            .background {
                if material == .chrome {
                        // Apple's chrome glass effect with enhanced reflection
                        Rectangle()
                            .fill(material.material)
                            .opacity(material.adaptivityFactor * vibrancy.opacity)
                            .overlay(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.15),
                                        Color.white.opacity(0.05),
                                        Color.clear,
                                        Color.black.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .blendMode(.overlay)
                            )
                } else {
                    Rectangle()
                        .fill(material.material)
                        .opacity(material.adaptivityFactor * vibrancy.opacity)
                }
            }
            .blur(radius: material.blurRadius)
            .brightness(vibrancy.brightnessAdjustment * 0.5)
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
            
            ReadingInsightsView()
                .tabItem {
                    Label("Insights", systemImage: "chart.line.uptrend.xyaxis")
                }
                .badge(completedBooksCount > 0 ? completedBooksCount : 0)
                .tag(2)
        }
        .tabViewStyle(.automatic) // Fallback to automatic style
        .tint(.primary)
    }
}

// MARK: - Accessibility Enhancements (Apple's Inclusive Design)

extension LiquidGlassTheme {
    @MainActor static func respectingAccessibility<T>(_ value: T, reducedMotion: T) -> T {
        #if os(iOS)
        return UIAccessibility.isReduceMotionEnabled ? reducedMotion : value
        #else
        return value
        #endif
    }
    
    // Accessibility-aware material selection
    @MainActor static func accessibleMaterial(_ material: GlassMaterial) -> GlassMaterial {
        #if os(iOS)
        if UIAccessibility.isReduceTransparencyEnabled {
            return .thick  // More opaque for better visibility
        }
        if UIAccessibility.isInvertColorsEnabled {
            return .regular  // More predictable for inverted colors
        }
        #endif
        return material
    }
    
    // High contrast vibrancy when needed
    @MainActor static func accessibleVibrancy(_ level: VibrancyLevel) -> VibrancyLevel {
        #if os(iOS)
        if UIAccessibility.isDarkerSystemColorsEnabled {
            return .maximum  // Boost vibrancy for better contrast
        }
        #endif
        return level
    }
    
    // Content-adaptive animation respecting user preferences
    @MainActor static func respectingUserPreferences(_ animation: FluidAnimation) -> FluidAnimation {
        #if os(iOS)
        if UIAccessibility.isReduceMotionEnabled {
            return .instant  // No animation for reduce motion
        }
        if UIAccessibility.isReduceTransparencyEnabled {
            return .quick    // Faster animations with reduced transparency
        }
        #endif
        return animation
    }
}