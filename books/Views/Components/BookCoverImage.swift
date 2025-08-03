//
//  BookCoverImage.swift
//  books
//
//  Updated with ImageCache integration and enhanced dark mode support
//

import SwiftUI
import UIKit

struct BookCoverImage: View {
    let imageURL: String?
    let width: CGFloat
    let height: CGFloat
    
    @State private var image: Image? = nil
    @State private var isLoading = false
    @State private var hasError = false
    @State private var errorMessage: String = ""
    @State private var retryCount = 0
    
    private let maxRetries = 2
    
    var body: some View {
        Group {
            if isLoading {
                LoadingPlaceholder(width: width, height: height)
            } else if hasError && retryCount >= maxRetries {
                ErrorPlaceholder(
                    width: width, 
                    height: height, 
                    errorMessage: errorMessage,
                    showDetails: width > 80,
                    onRetry: retryLoad
                )
            } else if let image = image {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .cornerRadius(8)
                    .clipped()
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.theme.outline.opacity(0.2), lineWidth: 0.5)
                    )
                    .shadow(
                        color: Color.black.opacity(0.1),
                        radius: 2,
                        x: 0,
                        y: 1
                    )
            } else {
                PlaceholderBookCover(width: width, height: height)
            }
        }
        .onAppear {
            loadImage()
        }
        .onChange(of: imageURL) { oldValue, newValue in
            if oldValue != newValue {
                resetState()
                loadImage()
            }
        }
        .accessibilityLabel("Book cover")
        .accessibilityHidden(image == nil)
    }
    
    private func resetState() {
        image = nil
        isLoading = false
        hasError = false
        errorMessage = ""
        retryCount = 0
    }
    
    private func loadImage() {
        guard let urlString = imageURL?.trimmingCharacters(in: .whitespacesAndNewlines),
              !urlString.isEmpty else {
            // No error for missing URL, just show placeholder
            return
        }
        
        // Check cache first (synchronous)
        if let cachedImage = ImageCache.shared.image(for: urlString) {
            self.image = Image(uiImage: cachedImage)
            return
        }
        
        // Load from network
        isLoading = true
        hasError = false
        
        Task {
            do {
                let uiImage = try await ImageCache.shared.loadImage(from: urlString)
                
                await MainActor.run {
                    self.image = Image(uiImage: uiImage)
                    self.isLoading = false
                    self.retryCount = 0 // Reset on success
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.hasError = true
                    self.errorMessage = self.formatError(error)
                    self.retryCount += 1
                    
                    // Auto-retry for certain errors
                    if self.shouldAutoRetry(error) && self.retryCount < self.maxRetries {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.loadImage()
                        }
                    }
                }
            }
        }
    }
    
    private func retryLoad() {
        retryCount = 0
        loadImage()
    }
    
    private func shouldAutoRetry(_ error: Error) -> Bool {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .networkConnectionLost, .notConnectedToInternet:
                return true
            default:
                return false
            }
        }
        return false
    }
    
    private func formatError(_ error: Error) -> String {
        if let cacheError = error as? ImageCacheError {
            switch cacheError {
            case .invalidURL:
                return "Invalid URL"
            case .httpError(let code):
                return "HTTP \(code)"
            case .invalidImageData:
                return "Invalid Image"
            case .networkError:
                return "Network Error"
            }
        } else if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut:
                return "Timeout"
            case .notConnectedToInternet:
                return "No Internet"
            case .cannotFindHost:
                return "Host Not Found"
            default:
                return "Network Error"
            }
        }
        return "Load Failed"
    }
}

// MARK: - Enhanced Placeholder Views

struct LoadingPlaceholder: View {
    let width: CGFloat
    let height: CGFloat
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ZStack {
                // Base gradient background
                LinearGradient(
                    colors: [
                        Color.theme.surfaceVariant,
                        Color.theme.cardBackground
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: width * 0.7, height: height * 0.5)
                .cornerRadius(4)
                
                // Enhanced shimmer effect with boho colors
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.theme.primary.opacity(0.1),
                                Color.theme.tertiary.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: width * 0.7, height: height * 0.5)
                    .offset(x: isAnimating ? width : -width)
                    .animation(
                        .linear(duration: 1.5)
                        .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            }
            .clipped()
            
            if height > 60 {
                Text("Loading...")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color.theme.secondaryText)
            }
        }
        .frame(width: width, height: height)
        .background(Color.theme.cardBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.theme.outline.opacity(0.2), lineWidth: 0.5)
        )
        .onAppear {
            isAnimating = true
        }
        .accessibilityLabel("Loading book cover")
    }
}

struct ErrorPlaceholder: View {
    let width: CGFloat
    let height: CGFloat
    let errorMessage: String
    let showDetails: Bool
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: width * 0.3, height: height * 0.3)
                .foregroundColor(Color.theme.warning)
            
            if showDetails {
                VStack(spacing: Theme.Spacing.xs) {
                    Text(errorMessage)
                        .labelSmall()
                        .foregroundColor(Color.theme.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Button("Retry") {
                        onRetry()
                    }
                    .labelSmall()
                    .foregroundColor(Color.theme.primaryAction)
                }
            }
        }
        .frame(width: width, height: height)
        .background(Color.theme.cardBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.theme.outline.opacity(0.2), lineWidth: 0.5)
        )
        .accessibilityLabel("Failed to load book cover")
        .accessibilityHint("Double tap to retry loading")
    }
}

struct PlaceholderBookCover: View {
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            // Beautiful boho-inspired book icon with gradient
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color.theme.gradientStart,
                        Color.theme.gradientEnd
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 4))
                
                // Decorative book icon
                Image(systemName: "book.closed.fill")
                    .font(.system(size: width * 0.25, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.theme.primary,
                                Color.theme.tertiary
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                // Subtle decorative elements for boho feel
                VStack {
                    HStack {
                        Circle()
                            .fill(Color.theme.primary.opacity(0.2))
                            .frame(width: 3, height: 3)
                        Spacer()
                        Circle()
                            .fill(Color.theme.tertiary.opacity(0.3))
                            .frame(width: 2, height: 2)
                    }
                    Spacer()
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color.theme.secondary.opacity(0.2))
                            .frame(width: 2, height: 2)
                    }
                }
                .padding(Theme.Spacing.xs)
            }
            .frame(width: width * 0.7, height: height * 0.6)
            
            if height > 60 {
                Text("No Cover")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Color.theme.secondaryText)
            }
        }
        .frame(width: width, height: height)
        .background(
            LinearGradient(
                colors: [
                    Color.theme.cardBackground,
                    Color.theme.surfaceVariant
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.theme.outline.opacity(0.3),
                            Color.theme.outline.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .accessibilityLabel("No book cover available")
    }
}

#Preview {
    VStack(spacing: 20) {
        VStack(spacing: Theme.Spacing.lg) {
            HStack(spacing: Theme.Spacing.md) {
                // Test with valid URL
                BookCoverImage(
                    imageURL: "https://books.google.com/books/content?id=M30_sYfUfgAC&printsec=frontcover&img=1&zoom=1&edge=curl&source=gbs_api",
                    width: 100,
                    height: 150
                )
                
                // Test with invalid URL
                BookCoverImage(
                    imageURL: "https://invalid-url.com/image.jpg",
                    width: 100,
                    height: 150
                )
                
                // Test with nil URL
                BookCoverImage(
                    imageURL: nil,
                    width: 100,
                    height: 150
                )
            }
        }
        
        HStack {
            Text("Valid URL")
            Spacer()
            Text("Invalid URL")
            Spacer()
            Text("No URL")
        }
        .labelSmall()
        .foregroundColor(Color.theme.secondaryText)
    }
    .padding()
    .background(Color.theme.surface)
    .preferredColorScheme(.dark)
}