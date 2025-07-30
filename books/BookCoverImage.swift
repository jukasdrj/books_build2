//
//  BookCoverImage.swift
//  books
//
//  Updated with ImageCache integration
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
    
    var body: some View {
        Group {
            if isLoading {
                LoadingPlaceholder(width: width, height: height)
            } else if hasError {
                ErrorPlaceholder(
                    width: width, 
                    height: height, 
                    errorMessage: errorMessage,
                    showDetails: width > 80
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
                            .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
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
    }
    
    private func resetState() {
        image = nil
        isLoading = false
        hasError = false
        errorMessage = ""
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
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.hasError = true
                    self.errorMessage = self.formatError(error)
                }
            }
        }
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

// MARK: - Placeholder Views

struct LoadingPlaceholder: View {
    let width: CGFloat
    let height: CGFloat
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: width * 0.6, height: height * 0.4)
                
                // Animated shimmer effect
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.white.opacity(0.6),
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
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .frame(width: width, height: height)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .onAppear {
            isAnimating = true
        }
    }
}

struct ErrorPlaceholder: View {
    let width: CGFloat
    let height: CGFloat
    let errorMessage: String
    let showDetails: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: width * 0.3, height: height * 0.3)
                .foregroundColor(.orange)
            
            if showDetails {
                Text(errorMessage)
                    .font(.caption2)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(width: width, height: height)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
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
                .foregroundColor(.gray)
            
            if height > 60 {
                Text("No Cover")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .frame(width: width, height: height)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    VStack(spacing: 20) {
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
    .padding()
}