//
//  RatingGestureModifier.swift
//  books
//
//  Reusable gesture modifier for swipe-to-rate and long-press rating
//

import SwiftUI

struct RatingGestureModifier: ViewModifier {
    @Environment(\.appTheme) private var currentTheme
    let book: UserBook
    let onQuickRate: () -> Void
    let onLongPressRate: () -> Void
    
    @State private var dragAmount = CGSize.zero
    @State private var isLongPressing = false
    @State private var hasTriggeredSwipe = false
    
    // Gesture thresholds
    private let swipeThreshold: CGFloat = 80
    private let longPressDuration: TimeInterval = 0.5
    
    func body(content: Content) -> some View {
        content
            .offset(x: dragAmount.width * 0.2) // Subtle movement feedback
            .scaleEffect(isLongPressing ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: dragAmount)
            .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isLongPressing)
            .gesture(
                SimultaneousGesture(
                    // Swipe Right to Rate Gesture
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            dragAmount = value.translation
                            
                            // Trigger haptic feedback at swipe threshold
                            if value.translation.width > swipeThreshold && !hasTriggeredSwipe {
                                hasTriggeredSwipe = true
                                HapticFeedbackManager.shared.swipeToRate()
                            }
                            
                            // Reset if swiping back
                            if value.translation.width <= swipeThreshold && hasTriggeredSwipe {
                                hasTriggeredSwipe = false
                            }
                        }
                        .onEnded { value in
                            // Complete swipe action if threshold met
                            if value.translation.width > swipeThreshold {
                                onQuickRate()
                                HapticFeedbackManager.shared.bookMarkedAsRead()
                            }
                            
                            // Reset state
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                dragAmount = .zero
                            }
                            hasTriggeredSwipe = false
                        },
                    
                    // Long Press for Rating Menu Gesture
                    LongPressGesture(minimumDuration: longPressDuration)
                        .onChanged { isPressed in
                            isLongPressing = isPressed
                            if isPressed {
                                HapticFeedbackManager.shared.longPressStarted()
                            }
                        }
                        .onEnded { _ in
                            isLongPressing = false
                            onLongPressRate()
                        }
                )
            )
            .overlay {
                // Visual feedback for swipe gesture
                if dragAmount.width > 20 {
                    HStack {
                        Spacer()
                        VStack(spacing: Theme.Spacing.xs) {
                            Image(systemName: hasTriggeredSwipe ? "star.fill" : "arrow.right")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(hasTriggeredSwipe ? currentTheme.warning : currentTheme.primary)
                                .scaleEffect(hasTriggeredSwipe ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3), value: hasTriggeredSwipe)
                            
                            if hasTriggeredSwipe {
                                Text("5 ★")
                                    .labelSmall()
                                    .foregroundColor(currentTheme.warning)
                                    .transition(.scale.combined(with: .opacity))
                            } else {
                                Text("Swipe")
                                    .labelSmall()
                                    .foregroundColor(currentTheme.primary)
                            }
                        }
                        .padding(.trailing, Theme.Spacing.md)
                        .opacity(min(dragAmount.width / swipeThreshold, 1.0))
                    }
                }
            }
            .overlay {
                // Visual feedback for long press
                if isLongPressing {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "hand.tap")
                                .font(.system(size: 18))
                                .foregroundColor(currentTheme.primary)
                                .padding(Theme.Spacing.sm)
                                .background(currentTheme.primaryContainer)
                                .clipShape(Circle())
                                .shadow(radius: 2)
                                .transition(.scale.combined(with: .opacity))
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(.top, Theme.Spacing.sm)
                }
            }
    }
}

// MARK: - View Extension

extension View {
    /// Add rating gestures to any view
    func ratingGestures(
        for book: UserBook,
        onQuickRate: @escaping () -> Void,
        onLongPressRate: @escaping () -> Void
    ) -> some View {
        modifier(RatingGestureModifier(
            book: book,
            onQuickRate: onQuickRate,
            onLongPressRate: onLongPressRate
        ))
    }
}

// MARK: - Preview

struct RatingGestureModifierPreview: View {
    @Environment(\.appTheme) private var currentTheme
    @State private var userBook = UserBook()
    
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Text("Swipe right or long press to test gestures")
                .bodyMedium()
                .multilineTextAlignment(.center)
            
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .fill(currentTheme.primaryContainer)
                .frame(width: 200, height: 100)
                .overlay {
                    Text("Book Card\nGesture Test")
                        .titleMedium()
                        .multilineTextAlignment(.center)
                        .foregroundColor(currentTheme.onPrimaryContainer)
                }
                .ratingGestures(
                    for: userBook,
                    onQuickRate: {
// print("Quick 5-star rating applied!")
                    },
                    onLongPressRate: {
// print("Long press - show rating picker")
                    }
                )
            
            Text("↑ Try swiping right or holding")
                .labelSmall()
                .foregroundColor(currentTheme.secondaryText)
        }
        .padding(Theme.Spacing.xl)
    }
}

#Preview {
    RatingGestureModifierPreview()
        .environment(\.appTheme, AppColorTheme(variant: .purpleBoho))
        .preferredColorScheme(.light)
}
