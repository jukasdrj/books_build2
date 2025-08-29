import SwiftUI

// MARK: - Complete Liquid Glass Modifiers Library
// Comprehensive set of view modifiers for iOS 26 Liquid Glass design system
// Following Apple's latest design language and performance best practices

// MARK: - Navigation Modifiers
extension View {
    /// Liquid Glass navigation bar styling
    func liquidGlassNavigation(
        material: LiquidGlassTheme.GlassMaterial = .thin,
        vibrancy: LiquidGlassTheme.VibrancyLevel = .medium
    ) -> some View {
        self.toolbarBackground(
            material.material.opacity(material.adaptivityFactor * vibrancy.opacity),
            for: .navigationBar
        )
        .toolbarBackground(.visible, for: .navigationBar)
    }
    
    /// Liquid Glass tab bar styling
    func liquidGlassTabBar(
        material: LiquidGlassTheme.GlassMaterial = .regular,
        vibrancy: LiquidGlassTheme.VibrancyLevel = .medium
    ) -> some View {
        self.toolbarBackground(
            material.material.opacity(material.adaptivityFactor * vibrancy.opacity),
            for: .tabBar
        )
        .toolbarBackground(.visible, for: .tabBar)
    }
}

// MARK: - Background Modifiers
extension View {
    /// Liquid Glass background with adaptive complexity
    func liquidGlassBackground(
        material: LiquidGlassTheme.GlassMaterial = .ultraThin,
        vibrancy: LiquidGlassTheme.VibrancyLevel = .subtle
    ) -> some View {
        let renderer = AdaptiveGlassRenderer.shared
        return self.background(
            renderer.adaptiveMaterial(material).material
                .opacity(material.adaptivityFactor * renderer.adaptiveVibrancy(vibrancy).opacity),
            ignoresSafeAreaEdges: .all
        )
    }
    
    /// Full-screen liquid glass overlay
    func liquidGlassOverlay(
        material: LiquidGlassTheme.GlassMaterial = .thin,
        depth: LiquidGlassTheme.GlassDepth = .prominent,
        vibrancy: LiquidGlassTheme.VibrancyLevel = .medium
    ) -> some View {
        self.overlay(
            Rectangle()
                .fill(material.material.opacity(material.adaptivityFactor * vibrancy.opacity))
                .blur(radius: AdaptiveGlassRenderer.shared.adaptiveBlurRadius(material.blurRadius))
                .ignoresSafeArea(.all)
        )
    }
}

// MARK: - Interactive Modifiers
extension View {
    /// Liquid Glass button interaction with haptics
    func liquidGlassInteraction(
        style: LiquidGlassComponents.LiquidGlassButtonStyle = .adaptive,
        haptic: LiquidGlassButton.HapticStyle = .medium
    ) -> some View {
        self.modifier(LiquidGlassInteractionModifier(style: style, haptic: haptic))
    }
    
    /// Liquid Glass hover effect (for iPad with cursor support)
    func liquidGlassHover(
        scaleEffect: CGFloat = 1.02,
        animation: LiquidGlassTheme.FluidAnimation = .quick
    ) -> some View {
        self.modifier(LiquidGlassHoverModifier(scaleEffect: scaleEffect, animation: animation))
    }
}

// MARK: - Layout Modifiers
extension View {
    /// Liquid Glass container with consistent spacing
    func liquidGlassContainer(
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        spacing: CGFloat = 16
    ) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    /// Liquid Glass section with header
    func liquidGlassSection<Header: View>(
        @ViewBuilder header: () -> Header
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            header()
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            self
        }
        .liquidGlassContainer()
        .optimizedLiquidGlassCard(
            material: .thin,
            depth: .elevated,
            radius: .comfortable,
            vibrancy: .medium
        )
    }
}

// MARK: - Typography Modifiers
extension View {
    /// Liquid Glass enhanced typography
    func liquidGlassTypography(
        style: LiquidGlassTypographyStyle,
        vibrancy: LiquidGlassTheme.VibrancyLevel = .medium
    ) -> some View {
        self
            .font(style.font)
            .liquidGlassVibrancy(vibrancy)
    }
    
    /// Liquid Glass text with adaptive sizing
    func liquidGlassText(
        size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default
    ) -> some View {
        self.font(.system(size: size, weight: weight, design: design))
            .foregroundStyle(
                .primary.opacity(0.9)
            )
    }
}

enum LiquidGlassTypographyStyle {
    case displayLarge, displayMedium, displaySmall
    case headlineLarge, headlineMedium, headlineSmall
    case titleLarge, titleMedium, titleSmall
    case bodyLarge, bodyMedium, bodySmall
    case labelLarge, labelMedium, labelSmall
    
    var font: Font {
        let typography = LiquidGlassTheme.typography
        switch self {
        case .displayLarge: return typography.displayLarge
        case .displayMedium: return typography.displayMedium
        case .displaySmall: return typography.displaySmall
        case .headlineLarge: return typography.headlineLarge
        case .headlineMedium: return typography.headlineMedium
        case .headlineSmall: return typography.headlineSmall
        case .titleLarge: return typography.titleLarge
        case .titleMedium: return typography.titleMedium
        case .titleSmall: return typography.titleSmall
        case .bodyLarge: return typography.bodyLarge
        case .bodyMedium: return typography.bodyMedium
        case .bodySmall: return typography.bodySmall
        case .labelLarge: return typography.labelLarge
        case .labelMedium: return typography.labelMedium
        case .labelSmall: return typography.labelSmall
        }
    }
}

// MARK: - Animation Modifiers
extension View {
    /// Performance-aware liquid glass transition
    func liquidGlassTransition<V: Equatable>(
        value: V,
        animation: LiquidGlassTheme.FluidAnimation = .smooth
    ) -> some View {
        let adaptiveAnimation = LiquidGlassTheme.respectingUserPreferences(animation)
        return self.animation(adaptiveAnimation.springAnimation, value: value)
    }
    
    /// Entrance animation for liquid glass elements
    func liquidGlassEntrance(
        delay: TimeInterval = 0,
        animation: LiquidGlassTheme.FluidAnimation = .flowing
    ) -> some View {
        self.modifier(LiquidGlassEntranceModifier(delay: delay, animation: animation))
    }
}

// MARK: - Modal and Sheet Modifiers
extension View {
    /// Liquid Glass modal presentation
    func liquidGlassModal<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            content()
                .liquidGlassBackground(material: .regular, vibrancy: .medium)
                .presentationBackground(.clear)
                .presentationCornerRadius(24)
        }
    }
    
    /// Liquid Glass alert styling
    func liquidGlassAlert<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.overlay(
            Group {
                if isPresented.wrappedValue {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                isPresented.wrappedValue = false
                            }
                        
                        content()
                            .optimizedLiquidGlassCard(
                                material: .thick,
                                depth: .prominent,
                                radius: .spacious,
                                vibrancy: .prominent
                            )
                            .padding(32)
                    }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 0.9).combined(with: .opacity)
                    ))
                }
            }
        )
    }
}

// MARK: - Supporting View Modifier Implementations

struct LiquidGlassInteractionModifier: ViewModifier {
    let style: LiquidGlassComponents.LiquidGlassButtonStyle
    let haptic: LiquidGlassButton.HapticStyle
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .opacity(isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPressed)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { pressing in
                isPressed = pressing
                if pressing {
                    haptic.trigger()
                }
            } perform: {}
    }
}

struct LiquidGlassHoverModifier: ViewModifier {
    let scaleEffect: CGFloat
    let animation: LiquidGlassTheme.FluidAnimation
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? scaleEffect : 1.0)
            .animation(animation.springAnimation, value: isHovered)
            .onHover { hovering in
                isHovered = hovering
                if hovering {
                    HapticFeedbackManager.shared.lightImpact()
                }
            }
    }
}

struct LiquidGlassEntranceModifier: ViewModifier {
    let delay: TimeInterval
    let animation: LiquidGlassTheme.FluidAnimation
    @State private var hasAppeared = false
    
    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .scaleEffect(hasAppeared ? 1 : 0.8)
            .blur(radius: hasAppeared ? 0 : 3)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(animation.springAnimation) {
                        hasAppeared = true
                    }
                }
            }
    }
}

// MARK: - Accessibility Modifiers
extension View {
    /// Liquid Glass accessibility enhancement
    func liquidGlassAccessibility(
        label: String? = nil,
        hint: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        self
            .accessibilityLabel(label ?? "")
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
            .accessibilityRespondsToUserInteraction()
    }
    
    /// VoiceOver optimized liquid glass element
    func liquidGlassVoiceOver(
        description: String,
        value: String? = nil
    ) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(description)
            .accessibilityValue(value ?? "")
    }
}

// MARK: - Debug and Development Modifiers
extension View {
    /// Debug overlay for liquid glass components
    func liquidGlassDebug(enabled: Bool = false) -> some View {
        self.overlay(
            Group {
                if enabled {
                    VStack {
                        HStack {
                            Text("Glass Debug")
                                .font(.caption2)
                                .foregroundColor(.red)
                                .padding(4)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(4)
                            Spacer()
                        }
                        Spacer()
                        HStack {
                            Spacer()
                            Text("Performance: \(LiquidGlassPerformanceMonitor.shared.isPerformanceAcceptable ? "✅" : "❌")")
                                .font(.caption2)
                                .foregroundColor(.red)
                                .padding(4)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(4)
                        }
                    }
                }
            }
        )
    }
}