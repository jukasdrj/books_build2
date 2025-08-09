//
//  QuickRatingView.swift
//  books
//
//  Beautiful overlay rating picker with purple boho styling
//

import SwiftUI

struct QuickRatingView: View {
    @Environment(\.appTheme) private var currentTheme
    @Binding var rating: Int?
    @Binding var isVisible: Bool
    let onRatingComplete: (Int) -> Void
    let onMarkAsRead: () -> Void
    let onCancel: () -> Void
    
    @State private var selectedRating: Int = 0
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    
    var body: some View {
        if isVisible {
            ZStack {
                // Background overlay
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissRating()
                    }
                
                VStack(spacing: Theme.Spacing.lg) {
                    // Header
                    VStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(currentTheme.warning)
                            .shadow(color: currentTheme.warning.opacity(0.3), radius: 4, x: 0, y: 2)
                        
                        Text("Rate this Book")
                            .titleLarge()
                            .foregroundColor(currentTheme.primaryText)
                        
                        Text("Tap a star to rate")
                            .bodyMedium()
                            .foregroundColor(currentTheme.secondaryText)
                    }
                    
                    // Star Rating Picker with Purple Boho Styling
                    HStack(spacing: Theme.Spacing.md) {
                        ForEach(1...5, id: \.self) { star in
                            Button {
                                selectedRating = star
                                HapticFeedbackManager.shared.ratingChanged()
                            } label: {
                                Image(systemName: star <= selectedRating ? "star.fill" : "star")
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundColor(star <= selectedRating ? currentTheme.warning : currentTheme.outline)
                                    .shadow(
                                        color: star <= selectedRating ? currentTheme.warning.opacity(0.4) : Color.clear,
                                        radius: star <= selectedRating ? 3 : 0,
                                        x: 0,
                                        y: 1
                                    )
                                    .scaleEffect(star <= selectedRating ? 1.15 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedRating)
                            }
                            .materialInteractive()
                        }
                    }
                    .padding(.vertical, Theme.Spacing.md)
                    
                    // Action Buttons with Purple Boho Styling
                    VStack(spacing: Theme.Spacing.sm) {
                        // Primary action - Rate & Mark Read
                        Button {
                            completeRating()
                        } label: {
                            HStack(spacing: Theme.Spacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Rate & Mark as Read")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .materialButton(style: .filled, size: .large)
                        .disabled(selectedRating == 0)
                        
                        // Secondary actions row
                        HStack(spacing: Theme.Spacing.sm) {
                            Button {
                                justRate()
                            } label: {
                                Text("Just Rate")
                            }
                            .materialButton(style: .tonal, size: .medium)
                            .disabled(selectedRating == 0)
                            .frame(maxWidth: .infinity)
                            
                            Button {
                                dismissRating()
                            } label: {
                                Text("Cancel")
                            }
                            .materialButton(style: .outlined, size: .medium)
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(Theme.Spacing.xl)
                .background {
                    // Purple boho gradient background
                    LinearGradient(
                        gradient: Gradient(colors: [
                            currentTheme.surface,
                            currentTheme.surface.opacity(0.98)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
                .materialCard(cornerRadius: Theme.CornerRadius.large)
                .shadow(color: currentTheme.primary.opacity(0.1), radius: 20, x: 0, y: 10)
                .scaleEffect(scale)
                .opacity(opacity)
                .padding(Theme.Spacing.xl)
            }
            .onAppear {
                // Initialize with current rating if exists
                if let currentRating = rating {
                    selectedRating = currentRating
                }
                
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
        }
    }
    
    private func completeRating() {
        guard selectedRating > 0 else { return }
        
        HapticFeedbackManager.shared.ratingCompleted()
        onRatingComplete(selectedRating)
        onMarkAsRead()
        HapticFeedbackManager.shared.bookMarkedAsRead()
        dismissRating()
    }
    
    private func justRate() {
        guard selectedRating > 0 else { return }
        
        HapticFeedbackManager.shared.ratingCompleted()
        onRatingComplete(selectedRating)
        dismissRating()
    }
    
    private func dismissRating() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            scale = 0.9
            opacity = 0.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isVisible = false
            selectedRating = 0
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var rating: Int? = nil
        @State private var isVisible = true
        
        var body: some View {
            QuickRatingView(
                rating: $rating,
                isVisible: $isVisible,
                onRatingComplete: { newRating in
                    rating = newRating
                    print("Rating completed: \(newRating)")
                },
                onMarkAsRead: {
                    print("Book marked as read")
                },
                onCancel: {
                    print("Rating cancelled")
                }
            )
        }
    }
    
    return PreviewWrapper()
}