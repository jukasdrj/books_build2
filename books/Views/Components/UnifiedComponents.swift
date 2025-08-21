import SwiftUI

// MARK: - Unified Hero Section
struct UnifiedHeroSection: View {
    @Environment(\.appTheme) private var currentTheme
    let config: HeroConfig
    
    struct HeroConfig {
        let icon: String
        let title: String
        let subtitle: String
        let style: HeroStyle
        let actions: [HeroAction]?
        
        enum HeroStyle {
            case discovery
            case stats
            case achievement
            case error
            
            var iconSize: CGFloat {
                switch self {
                case .discovery: return 48
                case .stats: return 40
                case .achievement: return 36
                case .error: return 40
                }
            }
            
            var circleSize: CGFloat {
                switch self {
                case .discovery: return 120
                case .stats: return 100
                case .achievement: return 80
                case .error: return 100
                }
            }
        }
        
        struct HeroAction {
            let title: String
            let icon: String
            let description: String
            let action: () -> Void
        }
        
        init(icon: String, title: String, subtitle: String, style: HeroStyle, actions: [HeroAction]? = nil) {
            self.icon = icon
            self.title = title
            self.subtitle = subtitle
            self.style = style
            self.actions = actions
        }
    }
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Hero icon and text section
            VStack(spacing: Theme.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(backgroundGradient)
                        .frame(width: config.style.circleSize, height: config.style.circleSize)
                    
                    Image(systemName: config.icon)
                        .font(.system(size: config.style.iconSize, weight: .light))
                        .foregroundStyle(iconGradient)
                }
                .shadow(color: currentTheme.primary.opacity(shadowOpacity), radius: shadowRadius, x: 0, y: shadowOffset)
                
                VStack(spacing: Theme.Spacing.md) {
                    Text(config.title)
                        .font(titleFont)
                        .fontWeight(.bold)
                        .foregroundColor(currentTheme.primaryText)
                        .multilineTextAlignment(.center)
                    
                    Text(config.subtitle)
                        .font(.body)
                        .foregroundColor(currentTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.md)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(config.title). \(config.subtitle)")
            
            // Optional actions section
            if let actions = config.actions {
                VStack(spacing: 12) {
                    ForEach(Array(actions.enumerated()), id: \.offset) { index, action in
                        UnifiedFeatureRow(
                            icon: action.icon,
                            title: action.title,
                            description: action.description,
                            action: action.action
                        )
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, Theme.Spacing.xl)
    }
    
    // MARK: - Computed Properties
    
    private var backgroundGradient: LinearGradient {
        switch config.style {
        case .discovery:
            return LinearGradient(
                colors: [
                    currentTheme.primary.opacity(0.2),
                    currentTheme.secondary.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .stats:
            return LinearGradient(
                colors: [
                    currentTheme.primary.opacity(0.2),
                    currentTheme.secondary.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .achievement:
            return LinearGradient(
                colors: [
                    currentTheme.tertiary.opacity(0.2),
                    currentTheme.primary.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .error:
            return LinearGradient(
                colors: [
                    currentTheme.error.opacity(0.2),
                    currentTheme.outline.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var iconGradient: LinearGradient {
        switch config.style {
        case .discovery, .stats:
            return LinearGradient(
                colors: [currentTheme.primary, currentTheme.secondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .achievement:
            return LinearGradient(
                colors: [currentTheme.tertiary, currentTheme.primary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .error:
            return LinearGradient(
                colors: [currentTheme.error, currentTheme.error.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var titleFont: Font {
        switch config.style {
        case .discovery: return .title
        case .stats: return .title2
        case .achievement: return .title3
        case .error: return .title2
        }
    }
    
    private var shadowOpacity: Double {
        switch config.style {
        case .discovery: return 0.15
        case .stats: return 0.2
        case .achievement: return 0.1
        case .error: return 0.1
        }
    }
    
    private var shadowRadius: CGFloat {
        switch config.style {
        case .discovery: return 20
        case .stats: return 16
        case .achievement: return 12
        case .error: return 16
        }
    }
    
    private var shadowOffset: CGFloat {
        switch config.style {
        case .discovery: return 10
        case .stats: return 8
        case .achievement: return 6
        case .error: return 8
        }
    }
}

// MARK: - Unified Feature Row
struct UnifiedFeatureRow: View {
    @Environment(\.appTheme) private var currentTheme
    let icon: String
    let title: String
    let description: String
    let action: (() -> Void)?
    
    init(icon: String, title: String, description: String, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.description = description
        self.action = action
    }
    
    var body: some View {
        Button(action: action ?? {}) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(currentTheme.primary)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(currentTheme.primaryText)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(currentTheme.secondaryText)
                }
                
                Spacer()
                
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(currentTheme.outline)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(currentTheme.surfaceVariant.opacity(0.3))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

// MARK: - Unified Stat Card
struct UnifiedStatCard: View {
    @Environment(\.appTheme) private var currentTheme
    let config: StatConfig
    
    struct StatConfig {
        let title: String
        let value: String
        let icon: String
        let color: Color
        let subtitle: String
        let style: StatStyle
        
        enum StatStyle {
            case enhanced  // Enhanced with icon background
            case simple    // Simple text-based
            case metric    // Progress metric style
        }
        
        init(title: String, value: String, icon: String, color: Color, subtitle: String, style: StatStyle = .enhanced) {
            self.title = title
            self.value = value
            self.icon = icon
            self.color = color
            self.subtitle = subtitle
            self.style = style
        }
    }
    
    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            switch config.style {
            case .enhanced:
                enhancedContent
            case .simple:
                simpleContent
            case .metric:
                metricContent
            }
        }
        .frame(maxWidth: .infinity, minHeight: 140)
        .padding(Theme.Spacing.md)
        .background {
            // Liquid Glass card with theme-aware styling
            RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                        .fill(
                            LinearGradient(
                                colors: [
                                    config.color.opacity(0.08),
                                    config.color.opacity(0.03)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                        .strokeBorder(config.color.opacity(0.15), lineWidth: 1)
                }
                .shadow(color: config.color.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
    
    @ViewBuilder
    private var enhancedContent: some View {
        // Icon with glass background
        ZStack {
            Circle()
                .fill(.thinMaterial)
                .overlay {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    config.color.opacity(0.2),
                                    config.color.opacity(0.05)
                                ],
                                center: .center,
                                startRadius: 5,
                                endRadius: 25
                            )
                        )
                }
                .overlay {
                    Circle()
                        .strokeBorder(config.color.opacity(0.2), lineWidth: 1)
                }
                .shadow(color: config.color.opacity(0.15), radius: 6, x: 0, y: 3)
                .frame(width: 50, height: 50)
            
            Image(systemName: config.icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(config.color)
                .shadow(color: config.color.opacity(0.3), radius: 2, x: 0, y: 1)
        }
        
        VStack(spacing: Theme.Spacing.xs) {
            Text(config.value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(currentTheme.primaryText)
            
            Text(config.title)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(currentTheme.primaryText)
                .multilineTextAlignment(.center)
            
            Text(config.subtitle)
                .font(.caption)
                .foregroundColor(currentTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    private var simpleContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Image(systemName: config.icon)
                    .foregroundColor(config.color)
                    .frame(width: 16)
                
                Text(config.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(currentTheme.primaryText)
                
                Spacer()
            }
            
            Text(config.value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(currentTheme.primaryText)
            
            Text(config.subtitle)
                .font(.caption)
                .foregroundColor(currentTheme.secondaryText)
        }
    }
    
    @ViewBuilder
    private var metricContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text(config.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(currentTheme.primaryText)
                
                Spacer()
                
                Text(config.value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(config.color)
            }
            
            Text(config.subtitle)
                .font(.caption)
                .foregroundColor(currentTheme.secondaryText)
        }
    }
}

// MARK: - Unified Loading State
struct UnifiedLoadingState: View {
    @Environment(\.appTheme) private var currentTheme
    let config: LoadingConfig
    
    struct LoadingConfig {
        let message: String
        let subtitle: String?
        let style: LoadingStyle
        
        enum LoadingStyle {
            case spinner      // Traditional spinning indicator
            case progress     // Progress-based loading
            case pulsing      // Pulsing animation
        }
        
        init(message: String, subtitle: String? = nil, style: LoadingStyle = .spinner) {
            self.message = message
            self.subtitle = subtitle
            self.style = style
        }
    }
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            loadingIndicator
            
            VStack(spacing: Theme.Spacing.sm) {
                TimelineView(.periodic(from: .now, by: 0.6)) { context in
                    Text(animatedMessage(for: context.date))
                        .bodyMedium()
                        .foregroundColor(currentTheme.primaryText)
                        .multilineTextAlignment(.center)
                        .animation(.easeInOut(duration: 0.3), value: animatedMessage(for: context.date))
                }
                
                if let subtitle = config.subtitle {
                    Text(subtitle)
                        .labelSmall()
                        .foregroundColor(currentTheme.secondaryText)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            isAnimating = true
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(config.message)
        .accessibilityHint("Loading content, please wait")
    }
    
    @ViewBuilder
    private var loadingIndicator: some View {
        switch config.style {
        case .spinner:
            ZStack {
                Circle()
                    .stroke(currentTheme.outline.opacity(0.3), lineWidth: 3)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(
                        LinearGradient(
                            colors: [currentTheme.primaryAction, currentTheme.primaryAction.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(
                        UIAccessibility.isReduceMotionEnabled ?
                            .linear(duration: 0.1) :
                            .linear(duration: 1.2).repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            }
            
        case .progress:
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: currentTheme.primaryAction))
                .scaleEffect(1.5)
            
        case .pulsing:
            Circle()
                .fill(currentTheme.primaryAction.opacity(0.2))
                .frame(width: 60, height: 60)
                .scaleEffect(isAnimating ? 1.2 : 0.8)
                .opacity(isAnimating ? 0.3 : 0.8)
                .animation(
                    UIAccessibility.isReduceMotionEnabled ?
                        .linear(duration: 0.1) :
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                    value: isAnimating
                )
        }
    }
    
    private func animatedMessage(for date: Date) -> String {
        let dotCount = Int(date.timeIntervalSince1970 * 1.67) % 4  // Approximate 0.6 second intervals
        return config.message + String(repeating: ".", count: dotCount)
    }
}

// MARK: - Unified Error State
struct UnifiedErrorState: View {
    @Environment(\.appTheme) private var currentTheme
    let config: ErrorConfig
    
    struct ErrorConfig {
        let title: String
        let message: String
        let retryAction: (() -> Void)?
        let style: ErrorStyle
        
        enum ErrorStyle {
            case standard    // Standard error display
            case minimal     // Minimal error with just retry
            case detailed    // Detailed error with suggestions
        }
        
        init(title: String, message: String, retryAction: (() -> Void)? = nil, style: ErrorStyle = .standard) {
            self.title = title
            self.message = message
            self.retryAction = retryAction
            self.style = style
        }
    }
    
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .headlineSmall()
                    .foregroundColor(currentTheme.error)
                
                Text(config.title)
                    .titleMedium()
                    .foregroundColor(currentTheme.primaryText)
                
                Text(config.message)
                    .bodyMedium()
                    .foregroundColor(currentTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.lg)
            }
            
            if let retryAction = config.retryAction {
                Button(action: {
                    HapticFeedbackManager.shared.mediumImpact()
                    retryAction()
                }) {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                }
                .materialButton(style: .filled, size: .large)
                .frame(minHeight: 44)
                .accessibilityLabel("Retry action")
                .accessibilityHint("Attempts to perform the action again")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Theme.Spacing.lg)
    }
}

// MARK: - Preview Support
#Preview("Hero Section - Discovery") {
    UnifiedHeroSection(config: .init(
        icon: "magnifyingglass.circle.fill",
        title: "Discover Your Next Great Read",
        subtitle: "Search millions of books with smart sorting and find exactly what you're looking for",
        style: .discovery,
        actions: [
            .init(title: "Smart Relevance", icon: "target", description: "Find the most relevant results for your search") {},
            .init(title: "Sort by Popularity", icon: "star.fill", description: "Discover trending and highly-rated books") {},
            .init(title: "All Languages", icon: "globe", description: "Include translated works from around the world") {}
        ]
    ))
    .preferredColorScheme(.dark)
}

#Preview("Stat Card - Enhanced") {
    UnifiedStatCard(config: .init(
        title: "Total Books",
        value: "42",
        icon: "books.vertical.fill",
        color: .purple,
        subtitle: "in your library",
        style: .enhanced
    ))
    .preferredColorScheme(.dark)
}

#Preview("Loading State") {
    UnifiedLoadingState(config: .init(
        message: "Searching millions of books",
        subtitle: "Using smart relevance sorting",
        style: .spinner
    ))
    .preferredColorScheme(.dark)
}