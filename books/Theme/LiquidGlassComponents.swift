import SwiftUI

// MARK: - Liquid Glass Interactive Components
// Enhanced button and input controls with standardized haptics
// Following iOS 26 Liquid Glass interaction patterns

// MARK: - Enhanced Liquid Glass Button
struct LiquidGlassButton: View {
    let title: String
    let style: LiquidGlassButtonStyleEnum
    let hapticStyle: HapticStyle
    let action: () -> Void
    
    @State private var isPressed = false
    @Environment(\.unifiedThemeStore) private var themeStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    enum HapticStyle {
        case light
        case medium
        case heavy
        case none
        
        @MainActor func trigger() {
            switch self {
            case .light:
                HapticFeedbackManager.shared.lightImpact()
            case .medium:
                HapticFeedbackManager.shared.mediumImpact()
            case .heavy:
                HapticFeedbackManager.shared.heavyImpact()
            case .none:
                break
            }
        }
    }
    
    init(
        _ title: String,
        style: LiquidGlassButtonStyleEnum = .primary,
        haptic: HapticStyle = .medium,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.hapticStyle = haptic
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            Task { @MainActor in
                hapticStyle.trigger()
                action()
            }
        }) {
            Text(title)
                .font(.system(size: adaptiveFontSize, weight: .semibold, design: .rounded))
                .foregroundColor(foregroundColor)
                .padding(.horizontal, adaptiveHorizontalPadding)
                .padding(.vertical, adaptiveVerticalPadding)
                .frame(minHeight: adaptiveMinHeight)
        }
        .buttonStyle(LiquidGlassButtonStyleModifier(
            style: style, 
            isPressed: $isPressed,
            reduceMotion: reduceMotion
        ))
        .optimizedLiquidGlassCard(
            material: backgroundMaterial,
            depth: buttonDepth,
            radius: .comfortable,
            vibrancy: buttonVibrancy
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(accessibilityHint)
    }
    
    // MARK: - iOS 26 Adaptive Button Properties
    private var adaptiveFontSize: CGFloat {
        let baseSize: CGFloat = {
            switch style {
            case .primary: return 17
            case .secondary: return 16
            case .tertiary, .glass: return 15
            case .floating: return 14
            case .adaptive: return 16
            }
        }()
        
        // Scale with Dynamic Type
        switch dynamicTypeSize {
        case ...DynamicTypeSize.large: return baseSize
        case .xLarge: return baseSize + 1
        case .xxLarge: return baseSize + 2
        default: return baseSize + 3
        }
    }
    
    private var adaptiveHorizontalPadding: CGFloat {
        let basePadding = horizontalPadding
        switch dynamicTypeSize {
        case ...DynamicTypeSize.large: return basePadding
        case .xLarge, .xxLarge: return basePadding + 2
        default: return basePadding + 4
        }
    }
    
    private var adaptiveVerticalPadding: CGFloat {
        let basePadding = verticalPadding
        switch dynamicTypeSize {
        case ...DynamicTypeSize.large: return basePadding
        case .xLarge, .xxLarge: return basePadding + 2
        default: return basePadding + 4
        }
    }
    
    private var adaptiveMinHeight: CGFloat {
        // iOS 26 minimum touch target - 44pt minimum
        switch dynamicTypeSize {
        case ...DynamicTypeSize.large: return 44
        case .xLarge: return 48
        case .xxLarge: return 52
        default: return 56
        }
    }
    
    private var buttonDepth: LiquidGlassTheme.GlassDepth {
        switch style {
        case .primary: return .elevated
        case .secondary: return .elevated
        case .tertiary: return .floating
        case .glass: return .floating
        case .floating: return .floating
        case .adaptive: return .elevated
        }
    }
    
    private var buttonVibrancy: LiquidGlassTheme.VibrancyLevel {
        switch style {
        case .primary: return .prominent
        case .secondary: return .medium
        case .tertiary, .glass: return .subtle
        case .floating: return .subtle
        case .adaptive: return .medium
        }
    }
    
    private var accessibilityHint: String {
        switch style {
        case .primary: return "Primary action button"
        case .secondary: return "Secondary action button"
        case .tertiary: return "Tertiary action button"
        case .glass: return "Glass style action button"
        case .floating: return "Floating action button"
        case .adaptive: return "Adaptive action button"
        }
    }
    
    private var backgroundMaterial: LiquidGlassTheme.GlassMaterial {
        switch style {
        case .primary: return .regular
        case .secondary: return .thin
        case .tertiary: return .ultraThin
        case .glass: return .regular
        case .floating: return .thin
        case .adaptive: return .regular
        }
    }
    
    private var foregroundColor: Color {
        if themeStore.currentTheme.isLiquidGlass,
           let liquidVariant = themeStore.currentTheme.liquidGlassVariant {
            switch style {
            case .primary: return liquidVariant.colorDefinition.primary.color
            case .secondary: return liquidVariant.colorDefinition.secondary.color
            case .tertiary: return liquidVariant.colorDefinition.primary.color.opacity(0.8)
            case .glass: return liquidVariant.colorDefinition.primary.color.opacity(0.9)
            case .floating: return liquidVariant.colorDefinition.primary.color
            case .adaptive: return liquidVariant.colorDefinition.primary.color.opacity(0.85)
            }
        } else {
            return themeStore.appTheme.primary
        }
    }
    
    private var horizontalPadding: CGFloat {
        switch style {
        case .primary, .secondary: return 24
        case .tertiary, .glass: return 20
        case .floating: return 16
        case .adaptive: return 20
        }
    }
    
    private var verticalPadding: CGFloat {
        switch style {
        case .primary: return 16
        case .secondary: return 14
        case .tertiary, .glass: return 12
        case .floating: return 10
        case .adaptive: return 12
        }
    }
}

// MARK: - Enhanced Button Style Implementation
struct LiquidGlassButtonStyleModifier: ButtonStyle {
    let style: LiquidGlassButtonStyleEnum
    @Binding var isPressed: Bool
    let reduceMotion: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(
                reduceMotion ? 
                    .none : 
                    .spring(response: 0.3, dampingFraction: 0.8), 
                value: configuration.isPressed
            )
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}

// MARK: - Liquid Glass Input Controls
struct LiquidGlassTextField: View {
    @Binding var text: String
    let placeholder: String
    let style: InputStyle
    @FocusState private var isFocused: Bool
    
    enum InputStyle {
        case standard
        case floating
        case inline
        case search
        
        var material: LiquidGlassTheme.GlassMaterial {
            switch self {
            case .standard: return .thin
            case .floating: return .regular
            case .inline: return .ultraThin
            case .search: return .regular
            }
        }
        
        var radius: LiquidGlassTheme.GlassRadius {
            switch self {
            case .standard, .floating: return .comfortable
            case .inline: return .compact
            case .search: return .continuous
            }
        }
    }
    
    init(
        text: Binding<String>,
        placeholder: String,
        style: InputStyle = .standard
    ) {
        self._text = text
        self.placeholder = placeholder
        self.style = style
    }
    
    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: style.radius.value)
                    .fill(style.material.material)
                    .opacity(isFocused ? 0.9 : 0.7)
            )
            .overlay(
                RoundedRectangle(cornerRadius: style.radius.value)
                    .stroke(
                        focusBorderColor,
                        lineWidth: isFocused ? 2 : 0
                    )
            )
            .focused($isFocused)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
            .onChange(of: isFocused) { _, newValue in
                if newValue {
                    Task { @MainActor in
                        HapticFeedbackManager.shared.lightImpact()
                    }
                }
            }
    }
    
    @Environment(\.unifiedThemeStore) private var themeStore
    
    private var focusBorderColor: Color {
        if themeStore.currentTheme.isLiquidGlass,
           let liquidVariant = themeStore.currentTheme.liquidGlassVariant {
            return liquidVariant.colorDefinition.primary.color
        } else {
            return themeStore.appTheme.primary
        }
    }
}

// MARK: - Liquid Glass Toggle Control
struct LiquidGlassToggle: View {
    @Binding var isOn: Bool
    let label: String
    @Environment(\.unifiedThemeStore) private var themeStore
    
    var body: some View {
        Toggle(isOn: $isOn.animation(.spring(response: 0.4, dampingFraction: 0.8))) {
            Text(label)
                .font(.system(size: 16, weight: .medium, design: .rounded))
        }
        .tint(toggleColor)
        .onChange(of: isOn) { _, _ in
            Task { @MainActor in
                HapticFeedbackManager.shared.mediumImpact()
            }
        }
    }
    
    private var toggleColor: Color {
        if themeStore.currentTheme.isLiquidGlass,
           let liquidVariant = themeStore.currentTheme.liquidGlassVariant {
            return liquidVariant.colorDefinition.primary.color
        } else {
            return themeStore.appTheme.primary
        }
    }
}

// MARK: - Liquid Glass Picker Control
struct LiquidGlassPicker<SelectionValue: Hashable>: View {
    @Binding var selection: SelectionValue
    let options: [SelectionValue]
    let displayName: (SelectionValue) -> String
    
    @Environment(\.unifiedThemeStore) private var themeStore
    @State private var showingPicker = false
    
    init(
        selection: Binding<SelectionValue>,
        options: [SelectionValue],
        displayName: @escaping (SelectionValue) -> String
    ) {
        self._selection = selection
        self.options = options
        self.displayName = displayName
    }
    
    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    selection = option
                    Task { @MainActor in
                        HapticFeedbackManager.shared.mediumImpact()
                    }
                }) {
                    HStack {
                        Text(displayName(option))
                        if option == selection {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                Text(displayName(selection))
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .optimizedLiquidGlassCard(
            material: .thin,
            depth: .elevated,
            radius: .comfortable,
            vibrancy: .medium
        )
    }
}

// MARK: - Liquid Glass Segmented Control
struct LiquidGlassSegmentedControl<SelectionValue: Hashable>: View {
    @Binding var selection: SelectionValue
    let options: [SelectionValue]
    let displayName: (SelectionValue) -> String
    
    @Environment(\.unifiedThemeStore) private var themeStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Namespace private var selectionAnimation
    
    init(
        selection: Binding<SelectionValue>,
        options: [SelectionValue],
        displayName: @escaping (SelectionValue) -> String
    ) {
        self._selection = selection
        self.options = options
        self.displayName = displayName
    }
    
    var body: some View {
        HStack(spacing: adaptiveSpacing) {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    selection = option
                    Task { @MainActor in
                        HapticFeedbackManager.shared.mediumImpact()
                    }
                }) {
                    Text(displayName(option))
                        .font(.system(size: adaptiveFontSize, weight: .semibold, design: .rounded))
                        .foregroundColor(option == selection ? selectedTextColor : unselectedTextColor)
                        .padding(.horizontal, adaptiveHorizontalPadding)
                        .padding(.vertical, adaptiveVerticalPadding)
                        .background(
                            Group {
                                if option == selection {
                                    RoundedRectangle(cornerRadius: adaptiveCornerRadius)
                                        .fill(selectionBackgroundColor)
                                        .matchedGeometryEffect(id: "selection", in: selectionAnimation)
                                }
                            }
                        )
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(displayName(option))
                        .accessibilityAddTraits(option == selection ? [.isButton, .isSelected] : .isButton)
                        .accessibilityHint(option == selection ? "Currently selected" : "Tap to select")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(adaptivePadding)
        .optimizedLiquidGlassCard(
            material: .thin,
            depth: .floating,
            radius: .comfortable,
            vibrancy: .medium
        )
        .animation(reduceMotion ? .none : .spring(response: 0.4, dampingFraction: 0.8), value: selection)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Appearance preference selector")
        .accessibilityHint("Choose between light, dark, or system appearance")
    }
    
    // MARK: - iOS 26 Adaptive Layout Properties
    private var adaptiveSpacing: CGFloat {
        switch dynamicTypeSize {
        case ...DynamicTypeSize.large: return 4
        case .xLarge, .xxLarge: return 6
        default: return 8
        }
    }
    
    private var adaptiveFontSize: CGFloat {
        switch dynamicTypeSize {
        case ...DynamicTypeSize.large: return 14
        case .xLarge: return 16
        case .xxLarge: return 18
        default: return 20
        }
    }
    
    private var adaptiveHorizontalPadding: CGFloat {
        switch dynamicTypeSize {
        case ...DynamicTypeSize.large: return 16
        case .xLarge, .xxLarge: return 18
        default: return 20
        }
    }
    
    private var adaptiveVerticalPadding: CGFloat {
        switch dynamicTypeSize {
        case ...DynamicTypeSize.large: return 8
        case .xLarge, .xxLarge: return 10
        default: return 12
        }
    }
    
    private var adaptiveCornerRadius: CGFloat {
        switch dynamicTypeSize {
        case ...DynamicTypeSize.large: return 8
        case .xLarge, .xxLarge: return 10
        default: return 12
        }
    }
    
    private var adaptivePadding: CGFloat {
        switch dynamicTypeSize {
        case ...DynamicTypeSize.large: return 4
        case .xLarge, .xxLarge: return 6
        default: return 8
        }
    }
    
    private var selectedTextColor: Color {
        if themeStore.currentTheme.isLiquidGlass,
           let liquidVariant = themeStore.currentTheme.liquidGlassVariant {
            return liquidVariant.colorDefinition.primary.color
        } else {
            return themeStore.appTheme.primary
        }
    }
    
    private var unselectedTextColor: Color {
        if themeStore.currentTheme.isLiquidGlass,
           let liquidVariant = themeStore.currentTheme.liquidGlassVariant {
            return liquidVariant.colorDefinition.secondary.color
        } else {
            return themeStore.appTheme.secondary
        }
    }
    
    private var selectionBackgroundColor: Color {
        if themeStore.currentTheme.isLiquidGlass,
           let liquidVariant = themeStore.currentTheme.liquidGlassVariant {
            return liquidVariant.colorDefinition.primary.color.opacity(0.2)
        } else {
            return themeStore.appTheme.primary.opacity(0.2)
        }
    }
}

// MARK: - Button Style Enum
enum LiquidGlassButtonStyleEnum {
    case primary
    case secondary  
    case tertiary
    case glass      // Apple's official .glass button style equivalent
    case floating   // Enhanced floating glass button
    case adaptive   // Content-adaptive button (Apple principle)
}

// MARK: - Enhanced Appearance Control (iOS 26 Liquid Glass)
struct EnhancedAppearanceControl: View {
    @Binding var selection: AppearancePreference
    @Environment(\.unifiedThemeStore) private var themeStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Namespace private var selectionAnimation
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(AppearancePreference.allCases, id: \.self) { option in
                appearanceButton(for: option)
            }
        }
        .padding(6)
        .optimizedLiquidGlassCard(
            material: .regular,
            depth: .floating,
            radius: .comfortable,
            vibrancy: .medium
        )
        .animation(animationValue, value: selection)
    }
    
    @ViewBuilder
    private func appearanceButton(for option: AppearancePreference) -> some View {
        Button(action: {
            selection = option
            Task { @MainActor in
                HapticFeedbackManager.shared.mediumImpact()
            }
        }) {
            buttonContent(for: option)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(option.displayName) appearance")
        .accessibilityHint("Sets the app to \(option.displayName.lowercased()) mode")
        .accessibilityAddTraits(option == selection ? .isSelected : [])
    }
    
    @ViewBuilder
    private func buttonContent(for option: AppearancePreference) -> some View {
        VStack(spacing: 4) {
            iconView(for: option)
            textView(for: option)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(backgroundView(for: option))
    }
    
    @ViewBuilder
    private func iconView(for option: AppearancePreference) -> some View {
        Image(systemName: option.icon)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(option == selection ? selectedTextColor : unselectedTextColor)
    }
    
    @ViewBuilder
    private func textView(for option: AppearancePreference) -> some View {
        Text(option.displayName)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundColor(option == selection ? selectedTextColor : unselectedTextColor)
    }
    
    @ViewBuilder
    private func backgroundView(for option: AppearancePreference) -> some View {
        Group {
            if option == selection {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(selectionBackgroundColor)
                    .matchedGeometryEffect(id: "selection", in: selectionAnimation)
            }
        }
    }
    
    private var animationValue: Animation {
        reduceMotion ? .linear(duration: 0.1) : 
        .spring(response: 0.4, dampingFraction: 0.8)
    }
    
    private var selectedTextColor: Color {
        if themeStore.currentTheme.isLiquidGlass,
           let liquidVariant = themeStore.currentTheme.liquidGlassVariant {
            return liquidVariant.colorDefinition.primary.color
        } else {
            return themeStore.appTheme.primary
        }
    }
    
    private var unselectedTextColor: Color {
        if themeStore.currentTheme.isLiquidGlass,
           let liquidVariant = themeStore.currentTheme.liquidGlassVariant {
            return liquidVariant.colorDefinition.secondary.color
        } else {
            return themeStore.appTheme.secondaryText
        }
    }
    
    private var selectionBackgroundColor: Color {
        if themeStore.currentTheme.isLiquidGlass,
           let liquidVariant = themeStore.currentTheme.liquidGlassVariant {
            return liquidVariant.colorDefinition.primary.color.opacity(0.15)
        } else {
            return themeStore.appTheme.primary.opacity(0.15)
        }
    }
}

// MARK: - Namespace for Organization
enum LiquidGlassComponents {
    typealias LiquidGlassButtonStyle = LiquidGlassButtonStyleEnum
}