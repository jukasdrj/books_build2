//
//  SmartPromptCard.swift
//  books
//
//  Smart prompt card for displaying data quality suggestions
//  Using iOS 26 Liquid Glass design system
//

import SwiftUI
import SwiftData

struct SmartPromptCard: View {
    let prompt: UserInputPrompt
    let book: UserBook
    let priority: SmartPromptPriority
    let onAction: () -> Void
    let onDismiss: () -> Void
    let onRemindLater: () -> Void
    
    @Environment(\.appTheme) private var theme
    @State private var isPressed = false
    @State private var isDismissed = false
    
    var body: some View {
        if !isDismissed {
            HStack(spacing: Theme.Spacing.md) {
                // Icon
                ZStack {
                    Circle()
                        .fill(priorityColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: prompt.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(priorityColor)
                }
                
                // Content
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(prompt.displayText)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(theme.primaryText)
                        .lineLimit(1)
                    
                    Text(contextualMessage)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(theme.secondaryText)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: Theme.Spacing.sm) {
                    // Primary action button
                    Button(action: {
                        HapticFeedbackManager.shared.lightImpact()
                        onAction()
                    }) {
                        Text(actionButtonText)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(priorityColor)
                                    .liquidGlassVibrancy()
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                    
                    // Dismiss menu
                    Menu {
                        Button("Remind me later", systemImage: "clock") {
                            HapticFeedbackManager.shared.lightImpact()
                            withAnimation(.spring()) {
                                isDismissed = true
                            }
                            onRemindLater()
                        }
                        
                        Button("Don't show again", systemImage: "xmark.circle", role: .destructive) {
                            HapticFeedbackManager.shared.mediumImpact()
                            withAnimation(.spring()) {
                                isDismissed = true
                            }
                            onDismiss()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(theme.secondaryText)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(Theme.Spacing.md)
            .liquidGlassCard(material: .thin)
            .overlay(
                // Priority indicator stripe
                RoundedRectangle(cornerRadius: 16)
                    .stroke(priorityColor.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(isDismissed ? 0.8 : 1.0)
            .opacity(isDismissed ? 0 : 1)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isDismissed)
            .animation(.spring(response: 0.2, dampingFraction: 0.9), value: isPressed)
            .onTapGesture {
                isPressed = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var priorityColor: Color {
        switch priority {
        case .high:
            return Color.red
        case .medium:
            return Color.orange
        case .low:
            return theme.primary
        }
    }
    
    private var contextualMessage: String {
        switch prompt {
        case .addPersonalRating:
            return "Rate this book to track your preferences"
        case .addPersonalNotes:
            return "Add your thoughts and impressions"
        case .reviewCulturalData:
            return "Help improve cultural diversity tracking"
        case .validateImportedData:
            return "Verify details from your import"
        case .addTags:
            return "Tag this book for better organization"
        case .updateReadingProgress:
            return "Update how much you've read"
        case .confirmBookDetails:
            return "Confirm the book information is correct"
        }
    }
    
    private var actionButtonText: String {
        switch prompt {
        case .addPersonalRating:
            return "Rate"
        case .addPersonalNotes:
            return "Add Notes"
        case .reviewCulturalData:
            return "Review"
        case .validateImportedData:
            return "Verify"
        case .addTags:
            return "Tag"
        case .updateReadingProgress:
            return "Update"
        case .confirmBookDetails:
            return "Confirm"
        }
    }
}

// MARK: - Supporting Types

enum SmartPromptPriority: CaseIterable {
    case high, medium, low
    
    static func priority(for prompt: UserInputPrompt, book: UserBook) -> SmartPromptPriority {
        switch prompt {
        case .validateImportedData:
            return .high
        case .addPersonalRating:
            return book.readingStatus == .read ? .high : .medium
        case .reviewCulturalData:
            return .medium
        case .addPersonalNotes:
            return .medium
        case .updateReadingProgress:
            return book.readingStatus == .reading ? .high : .low
        case .addTags:
            return .low
        case .confirmBookDetails:
            return .medium
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        ForEach([UserInputPrompt.addPersonalRating, .reviewCulturalData, .addPersonalNotes], id: \.self) { prompt in
            let mockBook = createMockBook()
            let priority = SmartPromptPriority.priority(for: prompt, book: mockBook)
            
            SmartPromptCard(
                prompt: prompt,
                book: mockBook,
                priority: priority,
                onAction: { print("Action: \(prompt.displayText)") },
                onDismiss: { print("Dismiss: \(prompt.displayText)") },
                onRemindLater: { print("Remind later: \(prompt.displayText)") }
            )
        }
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

private func createMockBook() -> UserBook {
    let mockBook = UserBook()
    mockBook.metadata = BookMetadata(
        googleBooksID: "test_book_123",
        title: "Test Book",
        authors: ["Test Author"],
        dataSource: .userInput,
        dataQualityScore: 0.8
    )
    return mockBook
}