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
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.theme.surfaceVariant)
                    .frame(width: width * 0.6, height: height * 0.4)
                
                // Animated shimmer effect
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.theme.onSurface.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: width * 0.6, height: height * 0.4)
                    .offset(x: isAnimating ? width : -width)
                    .animation(
                        .linear(duration: 1.2)
                        .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            }
            .clipped()
            
            if height > 60 {
                Text("Loading...")
                    .labelSmall()
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
        VStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: width * 0.3, height: height * 0.3)
                .foregroundColor(Color.theme.warning)
            
            if showDetails {
                VStack(spacing: 2) {
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
        VStack(spacing: 4) {
            Image(systemName: "book.closed.fill")
                .resizable()
                .scaledToFit()
                .frame(width: width * 0.4, height: height * 0.4)
                .foregroundColor(Color.theme.secondaryText)
            
            if height > 60 {
                Text("No Cover")
                    .labelSmall()
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
        .accessibilityLabel("No book cover available")
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 16) {
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