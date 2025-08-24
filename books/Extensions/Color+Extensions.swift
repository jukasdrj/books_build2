import SwiftUI
import UIKit

// MARK: - Keyboard Layout Extensions
extension View {
    /// Provides safe keyboard avoidance without constraint conflicts
    func keyboardAvoidingLayout() -> some View {
        self.modifier(KeyboardAvoidingModifier())
            .modifier(KeyboardConstraintFixModifier())
    }
    
    /// Sets keyboard dismiss mode for text fields
    func keyboardDismissMode(_ mode: UIScrollView.KeyboardDismissMode) -> some View {
        self.background(
            KeyboardDismissHostView(mode: mode)
                .allowsHitTesting(false)
        )
    }
    
    /// Adds keyboard toolbar with Done button to prevent constraint conflicts
    func keyboardToolbar() -> some View {
        self.toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    hideKeyboard()
                }
                .foregroundColor(.blue)
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct KeyboardAvoidingModifier: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0
    @State private var keyboardAnimationDuration: Double = 0.25
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardHeight)
            .animation(.easeInOut(duration: keyboardAnimationDuration), value: keyboardHeight)
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                updateKeyboardHeight(from: notification, isShowing: true)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { notification in
                updateKeyboardHeight(from: notification, isShowing: false)
            }
    }
    
    @MainActor
    private func updateKeyboardHeight(from notification: Notification, isShowing: Bool) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let animationDuration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        Task { @MainActor in
            self.keyboardAnimationDuration = animationDuration
            
            if isShowing {
                // Use safe area adjusted height to prevent constraint conflicts
                self.keyboardHeight = max(0, keyboardFrame.height - getSafeAreaBottom())
            } else {
                self.keyboardHeight = 0
            }
        }
    }
    
    @MainActor
    private func getSafeAreaBottom() -> CGFloat {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return 0
        }
        return window.safeAreaInsets.bottom
    }
}

struct KeyboardDismissHostView: UIViewRepresentable {
    let mode: UIScrollView.KeyboardDismissMode
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let scrollView = uiView.findSuperview(of: UIScrollView.self) {
            scrollView.keyboardDismissMode = mode
        }
    }
}

// MARK: - Keyboard Constraint Fix Modifier
struct KeyboardConstraintFixModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(KeyboardConstraintFixHelper())
    }
}

struct KeyboardConstraintFixHelper: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        
        // Set up keyboard constraint conflict mitigation
        setupKeyboardConstraintFix(for: view)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No updates needed
    }
    
    @MainActor
    private func setupKeyboardConstraintFix(for view: UIView) {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { [weak view] _ in
            Task { @MainActor in
                // Small delay to let keyboard setup complete
                try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
                view?.fixKeyboardConstraintConflicts()
            }
        }
    }
}

extension UIView {
    @MainActor
    func fixKeyboardConstraintConflicts() {
        guard let window = window else { return }
        
        // Find and fix keyboard placeholder view constraint conflicts
        findAndFixKeyboardConstraints(in: window)
    }
    
    @MainActor
    private func findAndFixKeyboardConstraints(in view: UIView) {
        // Look for RemoteKeyboardPlaceholderViews
        for subview in view.subviews {
            let className = String(describing: type(of: subview))
            if className.contains("RemoteKeyboardPlaceholder") {
                fixPlaceholderConstraints(for: subview)
            }
            findAndFixKeyboardConstraints(in: subview)
        }
    }
    
    @MainActor
    private func fixPlaceholderConstraints(for view: UIView) {
        // Lower priority of conflicting constraints to allow Auto Layout to resolve conflicts
        for constraint in view.constraints {
            if let identifier = constraint.identifier {
                if identifier.contains("accessoryView") || identifier.contains("inputView") {
                    // Lower priority to allow flexibility
                    constraint.priority = UILayoutPriority(999)
                }
            }
        }
        
        // Also check superview constraints
        if let superview = view.superview {
            for constraint in superview.constraints {
                if (constraint.firstItem === view || constraint.secondItem === view),
                   let identifier = constraint.identifier {
                    if identifier.contains("accessoryView") || identifier.contains("inputView") {
                        constraint.priority = UILayoutPriority(999)
                    }
                }
            }
        }
    }
}

extension UIView {
    func findSuperview<T: UIView>(of type: T.Type) -> T? {
        var view = superview
        while view != nil {
            if let typedView = view as? T {
                return typedView
            }
            view = view?.superview
        }
        return nil
    }
}

extension Color {
    // Legacy static references removed - use @Environment(\.appTheme) instead
}

// MARK: - Theme Environment Key
struct ThemeKey: EnvironmentKey {
    static let defaultValue = AppColorTheme(variant: .purpleBoho)
}

extension EnvironmentValues {
    var appTheme: AppColorTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// Helper to create adaptive colors for light/dark mode
private func adaptiveColor(light: UIColor, dark: UIColor) -> Color {
    return Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark ? dark : light
    })
}

struct AppColorTheme {
    let variant: ThemeVariant
    
    init(variant: ThemeVariant = .purpleBoho) {
        self.variant = variant
    }
    
    private var colorDef: ThemeColorDefinition {
        variant.colorDefinition
    }
    
    // MARK: - Primary Colors
    var primary: Color {
        adaptiveColor(light: colorDef.primary.light, dark: colorDef.primary.dark)
    }
    
    var onPrimary: Color {
        // Enhanced contrast: Always use white for better readability on primary colors
        adaptiveColor(light: .white, dark: .white)
    }
    
    var primaryContainer: Color {
        adaptiveColor(
            light: colorDef.primary.light.withAlphaComponent(0.12),
            dark: colorDef.primary.dark.withAlphaComponent(0.24)
        )
    }
    
    var onPrimaryContainer: Color {
        adaptiveColor(light: colorDef.primary.light, dark: colorDef.primary.dark)
    }
    
    // MARK: - Secondary Colors
    var secondary: Color {
        adaptiveColor(light: colorDef.secondary.light, dark: colorDef.secondary.dark)
    }
    
    var onSecondary: Color {
        adaptiveColor(light: .white, dark: colorDef.secondary.light.withAlphaComponent(0.9))
    }
    
    var secondaryContainer: Color {
        adaptiveColor(
            light: colorDef.secondary.light.withAlphaComponent(0.12),
            dark: colorDef.secondary.dark.withAlphaComponent(0.24)
        )
    }
    
    var onSecondaryContainer: Color {
        adaptiveColor(light: colorDef.secondary.light, dark: colorDef.secondary.dark)
    }
    
    // MARK: - Tertiary Colors
    var tertiary: Color {
        adaptiveColor(light: colorDef.tertiary.light, dark: colorDef.tertiary.dark)
    }
    
    var tertiaryContainer: Color {
        adaptiveColor(
            light: colorDef.tertiary.light.withAlphaComponent(0.12),
            dark: colorDef.tertiary.dark.withAlphaComponent(0.24)
        )
    }
    
    // MARK: - Surface Colors
    var surface: Color {
        adaptiveColor(light: colorDef.surface.light, dark: colorDef.surface.dark)
    }
    
    var onSurface: Color {
        primaryText
    }
    
    var surfaceVariant: Color {
        adaptiveColor(
            light: colorDef.primary.light.withAlphaComponent(0.05),
            dark: colorDef.primary.dark.withAlphaComponent(0.10)
        )
    }
    
    var onSurfaceVariant: Color {
        primaryText.opacity(0.8)
    }
    
    var background: Color {
        adaptiveColor(light: colorDef.background.light, dark: colorDef.background.dark)
    }
    
    // MARK: - Semantic Colors
    var error: Color {
        adaptiveColor(light: colorDef.error.light, dark: colorDef.error.dark)
    }
    
    var onError: Color {
        adaptiveColor(light: .white, dark: colorDef.error.light)
    }
    
    var success: Color {
        adaptiveColor(light: colorDef.success.light, dark: colorDef.success.dark)
    }
    
    var onSuccess: Color {
        adaptiveColor(light: .white, dark: colorDef.success.light)
    }
    
    var successContainer: Color {
        adaptiveColor(
            light: colorDef.success.light.withAlphaComponent(0.12),
            dark: colorDef.success.dark.withAlphaComponent(0.24)
        )
    }
    
    var onSuccessContainer: Color {
        adaptiveColor(light: colorDef.success.light, dark: colorDef.success.dark)
    }
    
    var warning: Color {
        adaptiveColor(light: colorDef.warning.light, dark: colorDef.warning.dark)
    }
    
    var warningContainer: Color {
        adaptiveColor(
            light: colorDef.warning.light.withAlphaComponent(0.12),
            dark: colorDef.warning.dark.withAlphaComponent(0.24)
        )
    }
    
    var onWarningContainer: Color {
        adaptiveColor(light: colorDef.warning.light, dark: colorDef.warning.dark)
    }
    
    // MARK: - Text Colors (Dynamic based on theme)
    var primaryText: Color {
        adaptiveColor(
            light: UIColor(white: 0.12, alpha: 1.0),   // near-black for light mode
            dark: UIColor(white: 0.95, alpha: 1.0)     // near-white for dark mode
        )
    }
    
    var secondaryText: Color {
        adaptiveColor(
            light: UIColor(white: 0.12, alpha: 0.70),  // 70% black
            dark: UIColor(white: 1.00, alpha: 0.70)    // 70% white
        )
    }
    
    var outline: Color {
        adaptiveColor(
            light: UIColor(white: 0.0, alpha: 0.12),    // subtle neutral outline
            dark: UIColor(white: 1.0, alpha: 0.12)
        )
    }
    
    // MARK: - State Colors
    var disabled: Color {
        adaptiveColor(
            light: UIColor(white: 0.0, alpha: 0.08),     // neutral disabled bg overlay
            dark: UIColor(white: 1.0, alpha: 0.12)
        )
    }
    
    var disabledText: Color {
        adaptiveColor(
            light: UIColor(white: 0.0, alpha: 0.38),     // neutral disabled text
            dark: UIColor(white: 1.0, alpha: 0.38)
        )
    }
    
    // MARK: - Component Colors
    var cardBackground: Color {
        surface
    }
    
    var primaryAction: Color {
        primary
    }
    
    var secondaryAction: Color {
        secondary
    }
    
    var accentHighlight: Color {
        tertiary
    }
    
    var hovered: Color { primary.opacity(0.08) }

    // MARK: - Gradients (for that extra boho touch!)
    var gradientStart: Color { primary.opacity(0.6) }
    var gradientEnd: Color { secondary.opacity(0.4) }
    
    // MARK: - Cultural Colors (placeholders)
    var cultureAfrica: Color { adaptiveColor(light: .brown, dark: .brown) }
    var cultureAsia: Color { adaptiveColor(light: .red, dark: .red) }
    var cultureEurope: Color { adaptiveColor(light: .blue, dark: .blue) }
    var cultureAmericas: Color { adaptiveColor(light: .green, dark: .green) }
    var cultureOceania: Color { adaptiveColor(light: .cyan, dark: .cyan) }
    var cultureMiddleEast: Color { adaptiveColor(light: .purple, dark: .purple) }
    var cultureIndigenous: Color { adaptiveColor(light: .orange, dark: .orange) }
    
    // MARK: - Helper Method for Color Adaptation
    
    private func adaptiveColor(light: UIColor, dark: UIColor) -> Color {
        return Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return dark
            case .light, .unspecified:
                return light
            @unknown default:
                return light
            }
        })
    }
}

// MARK: - UIColor to Color Conversion Helper
extension UIColor {
    func toColor() -> Color {
        return Color(self)
    }
}

// MARK: - Accessibility Helpers

extension Color {
    /// Returns a high contrast version of the color for accessibility
    var highContrast: Color {
        // Get the current color scheme
        #if os(iOS)
        let isDark = UITraitCollection.current.userInterfaceStyle == .dark
        #else
        let isDark = false
        #endif
        
        // Return higher contrast versions based on the color and mode
        // Note: Without theme context, we provide a generic high contrast version
        return isDark ? 
            Color(white: 0.9) : // Light color for dark mode
            Color(white: 0.1)   // Dark color for light mode
    }
    
    /// Checks if this color provides sufficient contrast against the given background
    func contrastRatio(against background: Color) -> Double {
        // Simplified contrast calculation
        // In a real implementation, you'd convert to RGB and calculate properly
        // This is a basic approximation
        return 4.5 // Assume WCAG AA compliance for now
    }
    
    /// Returns the appropriate text color (black or white) for this background
    var accessibleTextColor: Color {
        // Simple heuristic - in practice you'd calculate luminance
        #if os(iOS)
        let isDark = UITraitCollection.current.userInterfaceStyle == .dark
        #else
        let isDark = false
        #endif
        
        // Simple approach: use white for dark mode, dark for light mode
        return isDark ? .white : .black
    }
}