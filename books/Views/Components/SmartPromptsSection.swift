//
//  SmartPromptsSection.swift
//  books
//
//  Smart prompts section for BookDetailsView - shows data quality suggestions
//  Using iOS 26 Liquid Glass design system
//

import SwiftUI
import SwiftData

struct SmartPromptsSection: View {
    let book: UserBook
    let modelContext: ModelContext
    
    @State private var dismissedPrompts: Set<UserInputPrompt> = []
    
    var body: some View {
        let prompts = DataCompletenessService.generateUserPrompts(book)
            .filter { !dismissedPrompts.contains($0) }
        
        if !prompts.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Suggestions")
                        .font(Theme.Typography.titleMedium)
                        .foregroundColor(Color.primary)
                    
                    Spacer()
                }
                .padding(.horizontal, Theme.Spacing.md)
                
                LazyVStack(spacing: Theme.Spacing.sm) {
                    ForEach(prompts, id: \.self) { prompt in
                        let priority = SmartPromptPriority.priority(for: prompt, book: book)
                        
                        SmartPromptCard(
                            prompt: prompt,
                            book: book,
                            priority: priority,
                            onAction: {
                                handlePromptAction(prompt)
                            },
                            onDismiss: {
                                dismissedPrompts.insert(prompt)
                            },
                            onRemindLater: {
                                dismissedPrompts.insert(prompt)
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func handlePromptAction(_ prompt: UserInputPrompt) {
        switch prompt {
        case .addPersonalRating:
            // Scroll to rating section or open rating picker
            break
        case .addPersonalNotes:
            // Scroll to notes section or open notes editor
            break
        case .reviewCulturalData:
            // Navigate to edit view with cultural section focused
            break
        case .validateImportedData:
            // Navigate to edit view with validation mode
            break
        case .addTags:
            // Navigate to tags section or open tag picker
            break
        case .updateReadingProgress:
            // Navigate to progress section or open progress editor
            break
        case .confirmBookDetails:
            // Navigate to edit view with details section focused
            break
        }
    }
}

// MARK: - Preview

#Preview {
    let mockBook = UserBook()
    mockBook.metadata = BookMetadata(
        googleBooksID: "test_book_123",
        title: "Test Book",
        authors: ["Test Author"],
        dataSource: .csvImport,
        dataQualityScore: 0.6
    )
    
    let container = try! ModelContainer(for: UserBook.self, BookMetadata.self)
    
    return SmartPromptsSection(
        book: mockBook,
        modelContext: container.mainContext
    )
    .modelContainer(container)
    .padding()
    .background(Color(.systemGroupedBackground))
}