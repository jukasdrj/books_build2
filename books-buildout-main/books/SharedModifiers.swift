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
        VStack(alignment: .leading, spacing: 4) {
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
                    .font(.caption2)
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
        VStack(spacing: 20) {
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
                .font(.subheadline)
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
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again", action: retry)
                .buttonStyle(.borderedProminent)
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
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                VStack(spacing: 8) {
                    Text(title)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(message)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: 300)
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

// MARK: - Previews

#Preview("Progress Indicators") {
    VStack(spacing: 20) {
        ProgressIndicator(progress: 0.3, showPercentage: true)
        ProgressIndicator(progress: 0.7, color: .green)
        ProgressIndicator(progress: 0.95, color: .orange, showPercentage: true)
    }
    .padding()
}

#Preview("Loading and Error States") {
    VStack(spacing: 40) {
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