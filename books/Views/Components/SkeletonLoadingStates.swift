//
//  SkeletonLoadingStates.swift
//  books
//
//  iOS 26 enhanced skeleton loading states and error handling components
//  Provides reusable skeleton states with progressive enhancement
//

import SwiftUI

// MARK: - Core Skeleton Components

struct SkeletonText: View {
    let width: CGFloat
    let height: CGFloat
    @Environment(\.appTheme) private var theme
    @State private var isAnimating = false
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(theme.surfaceVariant)
            .frame(width: width, height: height)
            .opacity(isAnimating ? 0.5 : 0.8)
            .animation(
                .easeInOut(duration: 1.0)
                .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

struct SkeletonProgressRing: View {
    let size: CGFloat
    let color: Color
    @Environment(\.appTheme) private var theme
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(theme.surfaceVariant, lineWidth: 8)
                .frame(width: size, height: size)
            
            // Animated progress ring
            Circle()
                .trim(from: 0, to: 0.3)
                .stroke(
                    LinearGradient(
                        colors: [
                            color.opacity(0.3),
                            color.opacity(0.6),
                            color.opacity(0.3)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(
                    .linear(duration: 2.0)
                    .repeatForever(autoreverses: false),
                    value: isAnimating
                )
            
            // Center skeleton content
            VStack(spacing: 2) {
                SkeletonText(width: size * 0.4, height: size * 0.15)
                SkeletonText(width: size * 0.3, height: size * 0.1)
            }
        }
        .onAppear {
            isAnimating = true
        }
        .accessibilityLabel("Loading progress data")
    }
}

struct ErrorProgressRing: View {
    let size: CGFloat
    let color: Color
    let onRetry: () -> Void
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            onRetry()
        }) {
            ZStack {
                // Error background circle
                Circle()
                    .stroke(theme.error.opacity(0.3), lineWidth: 8)
                    .frame(width: size, height: size)
                
                // Error icon
                VStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: size * 0.2))
                        .foregroundColor(theme.error)
                    
                    Text("Retry")
                        .font(.system(size: size * 0.08, weight: .medium))
                        .foregroundColor(theme.error)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Error loading progress data")
        .accessibilityHint("Double tap to retry")
    }
}

// MARK: - Shimmer Effect Components

struct ShimmerEffect: View {
    @State private var isAnimating = false
    
    var body: some View {
        LinearGradient(
            colors: [
                Color.clear,
                Color.white.opacity(0.3),
                Color.clear
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .offset(x: isAnimating ? 200 : -200)
        .animation(
            .linear(duration: 1.5)
            .repeatForever(autoreverses: false),
            value: isAnimating
        )
        .onAppear {
            isAnimating = true
        }
    }
}

struct ShimmerCard: View {
    let width: CGFloat
    let height: CGFloat
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .fill(theme.surfaceVariant)
                .frame(width: width, height: height)
            
            ShimmerEffect()
                .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.medium))
                .frame(width: width, height: height)
        }
        .accessibilityLabel("Loading content")
    }
}

// MARK: - Enhanced Book Cover Loading States

struct SkeletonBookCover: View {
    let width: CGFloat
    let height: CGFloat
    @Environment(\.appTheme) private var theme
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Base skeleton background
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.surfaceVariant)
                .frame(width: width, height: height)
            
            // Shimmer overlay
            ShimmerEffect()
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(width: width, height: height)
            
            // Book icon placeholder
            VStack {
                Image(systemName: "book.closed")
                    .font(.system(size: width * 0.3))
                    .foregroundColor(theme.primary.opacity(0.3))
                    .opacity(isAnimating ? 0.3 : 0.6)
                    .animation(
                        .easeInOut(duration: 1.2)
                        .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                if height > 80 {
                    SkeletonText(width: width * 0.6, height: 8)
                        .padding(.top, 4)
                }
            }
        }
        .onAppear {
            isAnimating = true
        }
        .accessibilityLabel("Loading book cover")
    }
}

// MARK: - Import Banner Skeleton States

struct SkeletonImportBanner: View {
    @Environment(\.appTheme) private var theme
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Skeleton progress indicator
            Circle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 20, height: 20)
                .opacity(isAnimating ? 0.5 : 0.8)
                .animation(
                    .easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: true),
                    value: isAnimating
                )
            
            // Skeleton text content
            VStack(alignment: .leading, spacing: 2) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 100, height: 14)
                
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 80, height: 12)
            }
            
            Spacer()
            
            // Skeleton percentage
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white.opacity(0.4))
                .frame(width: 40, height: 16)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            LinearGradient(
                colors: [theme.primary.opacity(0.7), theme.primary.opacity(0.5)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .onAppear {
            isAnimating = true
        }
        .accessibilityLabel("Connecting to import service")
    }
}

struct ErrorImportBanner: View {
    @Environment(\.appTheme) private var theme
    let onRetry: () -> Void
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Connection Error")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Unable to connect to import service")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
            
            Button("Retry") {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                onRetry()
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.2))
            .cornerRadius(4)
            .accessibilityLabel("Retry connection to import service")
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(
            LinearGradient(
                colors: [theme.warning, theme.warning.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}

// MARK: - Empty States with Helpful Guidance

struct SkeletonEmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    let actionTitle: String?
    let action: (() -> Void)?
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Icon with subtle animation
            Image(systemName: systemImage)
                .font(.system(size: 60, weight: .light))
                .foregroundColor(theme.primary.opacity(0.6))
                .symbolEffect(.pulse, options: .repeat(.continuous))
            
            // Text content
            VStack(spacing: Theme.Spacing.sm) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.primaryText)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            
            // Optional action button
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle) {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    action()
                }
                .materialButton(style: .filled)
                .progressiveGlassEffect(material: .regular, level: .optimized)
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }
}

// MARK: - Contextual Progress Indicators

struct ContextualProgressIndicator: View {
    let progress: Double
    let title: String
    let subtitle: String?
    let isIndeterminate: Bool
    @Environment(\.appTheme) private var theme
    
    init(progress: Double = 0.0, title: String, subtitle: String? = nil, isIndeterminate: Bool = false) {
        self.progress = progress
        self.title = title
        self.subtitle = subtitle
        self.isIndeterminate = isIndeterminate
    }
    
    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Progress indicator
            if isIndeterminate {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: theme.primary))
                    .scaleEffect(0.8)
                    .progressiveGlassEffect(material: .regular, level: .minimal)
            } else {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: theme.primary))
                    .frame(height: 6)
                    .progressiveGlassEffect(material: .regular, level: .minimal)
            }
            
            // Text content
            VStack(spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(theme.primaryText)
                    .multilineTextAlignment(.center)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(theme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                
                if !isIndeterminate {
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundColor(theme.primary)
                        .fontWeight(.semibold)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .materialCard()
        .progressiveGlassEffect(material: .regular, level: .optimized)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isIndeterminate ? "\(title) in progress" : "\(title): \(Int(progress * 100))% complete")
    }
}

// MARK: - Preview

#Preview("Skeleton Loading States") {
    ScrollView {
        VStack(spacing: 20) {
            Group {
                Text("Skeleton Text")
                    .font(.caption)
                    .foregroundColor(.secondary)
                SkeletonText(width: 150, height: 16)
                
                Text("Skeleton Progress Ring")
                    .font(.caption)
                    .foregroundColor(.secondary)
                SkeletonProgressRing(size: 100, color: .blue)
                
                Text("Error Progress Ring")
                    .font(.caption)
                    .foregroundColor(.secondary)
                ErrorProgressRing(size: 100, color: .blue, onRetry: {})
                
                Text("Shimmer Card")
                    .font(.caption)
                    .foregroundColor(.secondary)
                ShimmerCard(width: 200, height: 100)
                
                Text("Skeleton Book Cover")
                    .font(.caption)
                    .foregroundColor(.secondary)
                SkeletonBookCover(width: 100, height: 150)
            }
            
            Group {
                Text("Empty State")
                    .font(.caption)
                    .foregroundColor(.secondary)
                SkeletonEmptyStateView(
                    title: "No Books Found",
                    message: "Your library is empty. Start by adding some books to track your reading progress.",
                    systemImage: "books.vertical",
                    actionTitle: "Add Books",
                    action: {}
                )
                
                Text("Contextual Progress")
                    .font(.caption)
                    .foregroundColor(.secondary)
                ContextualProgressIndicator(
                    progress: 0.7,
                    title: "Enhancing Library",
                    subtitle: "Adding covers and descriptions"
                )
            }
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
    .environment(\.appTheme, AppColorTheme(variant: .purpleBoho))
    .preferredColorScheme(.dark)
}