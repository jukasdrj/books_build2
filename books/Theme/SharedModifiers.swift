//
//  SharedModifiers.swift
//  books
//
//  Reusable view modifiers and components
//

import SwiftUI

// MARK: - Card Modifier

struct CardModifier: ViewModifier {
    var backgroundColor: Color = Color(UIColor.systemBackground)
    var shadowRadius: CGFloat = 8
    var shadowOpacity: Double = 0.05
    
    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .cornerRadius(12)
            .shadow(
                color: Color.black.opacity(shadowOpacity),
                radius: shadowRadius,
                x: 0,
                y: 2
            )
    }
}

extension View {
    func cardStyle(
        backgroundColor: Color = Color(UIColor.systemBackground),
        shadowRadius: CGFloat = 8,
        shadowOpacity: Double = 0.05
    ) -> some View {
        modifier(CardModifier(
            backgroundColor: backgroundColor,
            shadowRadius: shadowRadius,
            shadowOpacity: shadowOpacity
        ))
    }
}

// MARK: - Progress Indicator

struct ProgressIndicator: View {
    let progress: Double
    var height: CGFloat = 6
    var color: Color = .blue
    var showPercentage: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(Color.gray.opacity(0.2))
                    
                    // Progress
                    RoundedRectangle(cornerRadius: height / 2)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
                    
                    // Glowing end point
                    if progress > 0 && progress < 1 {
                        let circleSize = height + 2
                        let offsetX = max(0, (geometry.size.width * progress) - (circleSize / 2))
                        
                        Circle()
                            .fill(color)
                            .frame(width: circleSize, height: circleSize)
                            .overlay(
                                Circle()
                                    .fill(color.opacity(0.3))
                                    .blur(radius: 4)
                            )
                            .offset(x: offsetX)
                    }
                }
            }
            .frame(height: height)
            
            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .labelSmall()
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    let message: String
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.3)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(
                        .linear(duration: 1)
                        .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            }
            
            Text(message)
                .bodyMedium()
                .foregroundColor(.secondary)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Error View

struct ErrorView: View {
    let error: Error
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .labelLarge()
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .titleMedium()
            
            Text(error.localizedDescription)
                .bodyMedium()
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again", action: retry)
                .materialButton(style: .outlined)
        }
        .padding()
        .cardStyle()
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            // Enhanced visual hierarchy for App Store appeal
            VStack(spacing: Theme.Spacing.lg) {
                // Beautiful gradient background circle for the icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.theme.primary.opacity(0.1),
                                    Color.theme.secondary.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: icon)
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.theme.primary, Color.theme.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .shadow(color: Color.theme.primary.opacity(0.1), radius: 20, x: 0, y: 10)
                
                VStack(spacing: Theme.Spacing.md) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.theme.primaryText)
                        .multilineTextAlignment(.center)
                    
                    Text(message)
                        .font(.body)
                        .foregroundColor(Color.theme.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(.horizontal, Theme.Spacing.lg)
                }
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .materialButton(style: .filled, size: .large)
                    .shadow(color: Color.theme.primary.opacity(0.3), radius: 8, x: 0, y: 4)
            }
        }
        .frame(maxWidth: 350)
        .padding(Theme.Spacing.xl)
    }
}

// MARK: - Refresh Control

struct RefreshableScrollView<Content: View>: View {
    let content: Content
    let onRefresh: () async -> Void
    
    init(@ViewBuilder content: () -> Content, onRefresh: @escaping () async -> Void) {
        self.content = content()
        self.onRefresh = onRefresh
    }
    
    var body: some View {
        ScrollView {
            content
        }
        .refreshable {
            await onRefresh()
        }
    }
}

// MARK: - App Store Hero Section Component
struct AppStoreHeroSection: View {
    let title: String
    let subtitle: String
    let icon: String
    
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Hero icon with beautiful gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.theme.primary,
                                Color.theme.secondary,
                                Color.theme.tertiary
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.theme.primary.opacity(0.4), radius: 16, x: 0, y: 8)
                
                Image(systemName: icon)
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: Theme.Spacing.sm) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.theme.primaryText)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.title3)
                    .foregroundColor(Color.theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.md)
            }
        }
        .padding(Theme.Spacing.xl)
    }
}

// MARK: - Feature Highlight Card
struct FeatureHighlightCard: View {
    let icon: String
    let title: String
    let description: String
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Icon container
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(accentColor)
            }
            
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color.theme.primaryText)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(Color.theme.secondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(Theme.Spacing.md)
        .materialCard()
    }
}

// MARK: - Previews

#Preview("Progress Indicators") {
    VStack(spacing: Theme.Spacing.lg) {
        ProgressIndicator(progress: 0.3, showPercentage: true)
        ProgressIndicator(progress: 0.7, color: .green)
        ProgressIndicator(progress: 0.95, color: .orange, showPercentage: true)
    }
    .padding()
}

#Preview("Loading and Error States") {
    VStack(spacing: Theme.Spacing.xxxl) {
        LoadingView(message: "Loading books...")
        
        ErrorView(error: NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error message"])) {
            print("Retry tapped")
        }
        
        EmptyStateView(
            icon: "books.vertical",
            title: "No Books Yet",
            message: "Start building your library by adding your first book",
            actionTitle: "Add Book"
        ) {
            print("Add book tapped")
        }
    }
    .padding()
}