import SwiftUI

struct EditBookView: View {
    @Environment(\.dismiss) private var dismiss
    
    let userBook: UserBook
    let onSave: (UserBook) -> Void
    
    // State properties for UI
    @State private var title: String
    @State private var authors: String
    @State private var isbn: String
    @State private var personalNotes: String
    @State private var pageCount: String
    @State private var publisher: String
    @State private var language: String
    @State private var publishedDate: String
    @State private var originalLanguage: String
    @State private var authorNationality: String
    @State private var translator: String
    @State private var selectedFormat: BookFormat?
    @State private var tags: String // NEW: Tags field

    init(userBook: UserBook, onSave: @escaping (UserBook) -> Void) {
        self.userBook = userBook
        self.onSave = onSave
        
        // Initialize state from the model
        _title = State(initialValue: userBook.metadata?.title ?? "")
        _authors = State(initialValue: userBook.metadata?.authors.joined(separator: ", ") ?? "")
        _isbn = State(initialValue: userBook.metadata?.isbn ?? "")
        _personalNotes = State(initialValue: userBook.notes ?? "")
        _pageCount = State(initialValue: userBook.metadata?.pageCount != nil ? "\(userBook.metadata!.pageCount!)" : "")
        _publisher = State(initialValue: userBook.metadata?.publisher ?? "")
        _language = State(initialValue: userBook.metadata?.language ?? "")
        _publishedDate = State(initialValue: userBook.metadata?.publishedDate ?? "")
        _originalLanguage = State(initialValue: userBook.metadata?.originalLanguage ?? "")
        _authorNationality = State(initialValue: userBook.metadata?.authorNationality ?? "")
        _translator = State(initialValue: userBook.metadata?.translator ?? "")
        _selectedFormat = State(initialValue: userBook.metadata?.format)
        _tags = State(initialValue: userBook.tags.joined(separator: ", ")) // NEW: Initialize tags
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Basic Information Section
                Section {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Book Title")
                            .labelMedium()
                            .foregroundColor(Theme.Color.SecondaryText)
                        TextField("Enter the book title", text: $title)
                            .bodyMedium()
                            .disabled(true)
                            .foregroundColor(Theme.Color.SecondaryText)
                            .background(Theme.Color.Surface.opacity(0.5))
                    }
                    
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Authors")
                            .labelMedium()
                            .foregroundColor(Theme.Color.SecondaryText)
                        TextField("Enter author names (comma separated)", text: $authors)
                            .bodyMedium()
                            .disabled(true)
                            .foregroundColor(Theme.Color.SecondaryText)
                            .background(Theme.Color.Surface.opacity(0.5))
                    }
                } header: {
                    Text("Book Information")
                        .titleSmall()
                        .foregroundColor(Theme.Color.PrimaryText)
                } footer: {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .foregroundColor(Theme.Color.SecondaryText)
                            .font(.caption)
                        Text("Title and authors are provided by Google Books and cannot be edited.")
                            .labelSmall()
                            .foregroundColor(Theme.Color.SecondaryText)
                    }
                }
                
                // Format & Publication Section
                Section {
                    // Book Format Picker
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Book Format")
                            .labelMedium()
                            .foregroundColor(Theme.Color.SecondaryText)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: Theme.Spacing.sm) {
                            // Print Format (combining hardcover/paperback)
                            Button(action: {
                                if selectedFormat == .hardcover || selectedFormat == .paperback {
                                    selectedFormat = nil
                                } else {
                                    selectedFormat = .hardcover // Default to hardcover for print
                                }
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "book.closed")
                                        .font(.system(size: 20))
                                        .foregroundColor((selectedFormat == .hardcover || selectedFormat == .paperback) ? .white : Theme.Color.PrimaryAction)
                                    
                                    Text("Print")
                                        .labelSmall()
                                        .foregroundColor((selectedFormat == .hardcover || selectedFormat == .paperback) ? .white : Theme.Color.PrimaryText)
                                }
                                .frame(height: 60)
                                .frame(maxWidth: .infinity)
                                .background((selectedFormat == .hardcover || selectedFormat == .paperback) ? Theme.Color.PrimaryAction : Theme.Color.CardBackground)
                                .cornerRadius(Theme.CornerRadius.medium)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                        .stroke((selectedFormat == .hardcover || selectedFormat == .paperback) ? Theme.Color.PrimaryAction : Theme.Color.Outline, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            
                            // E-book Format
                            Button(action: {
                                selectedFormat = selectedFormat == .ebook ? nil : .ebook
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "tablet")
                                        .font(.system(size: 20))
                                        .foregroundColor(selectedFormat == .ebook ? .white : Theme.Color.PrimaryAction)
                                    
                                    Text("E-book")
                                        .labelSmall()
                                        .foregroundColor(selectedFormat == .ebook ? .white : Theme.Color.PrimaryText)
                                }
                                .frame(height: 60)
                                .frame(maxWidth: .infinity)
                                .background(selectedFormat == .ebook ? Theme.Color.PrimaryAction : Theme.Color.CardBackground)
                                .cornerRadius(Theme.CornerRadius.medium)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                        .stroke(selectedFormat == .ebook ? Theme.Color.PrimaryAction : Theme.Color.Outline, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                            
                            // Audiobook Format
                            Button(action: {
                                selectedFormat = selectedFormat == .audiobook ? nil : .audiobook
                            }) {
                                VStack(spacing: 4) {
                                    Image(systemName: "headphones")
                                        .font(.system(size: 20))
                                        .foregroundColor(selectedFormat == .audiobook ? .white : Theme.Color.PrimaryAction)
                                    
                                    Text("Audiobook")
                                        .labelSmall()
                                        .foregroundColor(selectedFormat == .audiobook ? .white : Theme.Color.PrimaryText)
                                }
                                .frame(height: 60)
                                .frame(maxWidth: .infinity)
                                .background(selectedFormat == .audiobook ? Theme.Color.PrimaryAction : Theme.Color.CardBackground)
                                .cornerRadius(Theme.CornerRadius.medium)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                        .stroke(selectedFormat == .audiobook ? Theme.Color.PrimaryAction : Theme.Color.Outline, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Publisher")
                            .labelMedium()
                            .foregroundColor(Theme.Color.SecondaryText)
                        TextField("Enter publisher name", text: $publisher)
                            .bodyMedium()
                            .disabled(true)
                            .foregroundColor(Theme.Color.SecondaryText)
                            .background(Theme.Color.Surface.opacity(0.5))
                    }
                    
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Publication Date")
                            .labelMedium()
                            .foregroundColor(Theme.Color.SecondaryText)
                        TextField("Enter publication date", text: $publishedDate)
                            .bodyMedium()
                            .disabled(true)
                            .foregroundColor(Theme.Color.SecondaryText)
                            .background(Theme.Color.Surface.opacity(0.5))
                    }
                    
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Page Count")
                            .labelMedium()
                            .foregroundColor(Theme.Color.SecondaryText)
                        TextField("Enter number of pages", text: $pageCount)
                            .keyboardType(.numberPad)
                            .bodyMedium()
                            .disabled(true)
                            .foregroundColor(Theme.Color.SecondaryText)
                            .background(Theme.Color.Surface.opacity(0.5))
                    }
                    
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("ISBN")
                            .labelMedium()
                            .foregroundColor(Theme.Color.SecondaryText)
                        TextField("Enter ISBN number", text: $isbn)
                            .bodyMedium()
                            .disabled(true)
                            .foregroundColor(Theme.Color.SecondaryText)
                            .background(Theme.Color.Surface.opacity(0.5))
                    }
                } header: {
                    Text("Format & Publication")
                        .titleSmall()
                        .foregroundColor(Theme.Color.PrimaryText)
                } footer: {
                    HStack(spacing: 4) {
                        Image(systemName: "globe")
                            .foregroundColor(Theme.Color.SecondaryText)
                            .font(.caption)
                        Text("Publication details are provided by Google Books. Only format can be customized.")
                            .labelSmall()
                            .foregroundColor(Theme.Color.SecondaryText)
                    }
                }
                
                // Cultural & Language Section
                Section {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Edition Language")
                            .labelMedium()
                            .foregroundColor(Theme.Color.SecondaryText)
                        TextField("Language of this edition", text: $language)
                            .bodyMedium()
                            .disabled(true)
                            .foregroundColor(Theme.Color.SecondaryText)
                            .background(Theme.Color.Surface.opacity(0.5))
                    }
                    
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Original Language")
                            .labelMedium()
                            .foregroundColor(Theme.Color.SecondaryText)
                        TextField("Original publication language", text: $originalLanguage)
                            .bodyMedium()
                    }
                    
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Author's Cultural Background")
                            .labelMedium()
                            .foregroundColor(Theme.Color.SecondaryText)
                        TextField("Author's nationality or cultural origin", text: $authorNationality)
                            .bodyMedium()
                    }
                    
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Translator")
                            .labelMedium()
                            .foregroundColor(Theme.Color.SecondaryText)
                        TextField("Translator name (if applicable)", text: $translator)
                            .bodyMedium()
                    }
                } header: {
                    Text("Cultural & Language Details")
                        .titleSmall()
                        .foregroundColor(Theme.Color.PrimaryText)
                } footer: {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        HStack(spacing: 4) {
                            Image(systemName: "info.circle")
                                .foregroundColor(Theme.Color.SecondaryText)
                                .font(.caption)
                            Text("Edition language is from Google Books. Add your own cultural and translation details.")
                                .labelSmall()
                                .foregroundColor(Theme.Color.SecondaryText)
                        }
                        Text("Help track the cultural diversity of your reading by adding author nationality and original language information.")
                            .labelSmall()
                            .foregroundColor(Theme.Color.SecondaryText)
                            .padding(.top, Theme.Spacing.xs)
                    }
                }
                
                // NEW: Tags Section
                Section {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Tags")
                            .labelMedium()
                            .foregroundColor(Theme.Color.SecondaryText)
                        TextField("Enter tags separated by commas", text: $tags)
                            .bodyMedium()
                            .onSubmit {
                                // Optional: Add tag validation or suggestions here
                            }
                    }
                } header: {
                    HStack {
                        Image(systemName: "tag")
                            .foregroundColor(Theme.Color.PrimaryAction)
                        Text("Organization")
                            .titleSmall()
                            .foregroundColor(Theme.Color.PrimaryText)
                    }
                } footer: {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Use tags to organize and categorize your books. Separate multiple tags with commas.")
                            .labelSmall()
                            .foregroundColor(Theme.Color.SecondaryText)
                        Text("Examples: Fiction, Favorite, Philosophy, Must-Read, Book Club")
                            .labelSmall()
                            .foregroundColor(Theme.Color.SecondaryText.opacity(0.8))
                            .italic()
                    }
                }
                
                // Personal Notes Section
                Section {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Personal Reading Notes")
                            .labelMedium()
                            .foregroundColor(Theme.Color.SecondaryText)
                        TextField("Your thoughts, reflections, and notes about this book...", text: $personalNotes, axis: .vertical)
                            .lineLimit(3...8)
                            .bodyMedium()
                    }
                } header: {
                    Text("Personal Notes")
                        .titleSmall()
                        .foregroundColor(Theme.Color.PrimaryText)
                } footer: {
                    Text("Your personal notes are private and separate from the book's description.")
                        .labelSmall()
                        .foregroundColor(Theme.Color.SecondaryText)
                }
            }
            .background(Theme.Color.Surface)
            .scrollContentBackground(.hidden)
            .navigationTitle("Edit Book Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { 
                        dismiss() 
                    }
                    .bodyMedium()
                    .foregroundColor(Theme.Color.SecondaryText)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveBook()
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .labelLarge()
                    .foregroundColor(Theme.Color.PrimaryAction)
                }
            }
        }
    }
    
    private func saveBook() {
        guard let metadata = userBook.metadata else { return }

        // Update metadata with form values
        metadata.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        metadata.authors = authors.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        metadata.publisher = publisher.nilIfEmptyAfterTrimming
        metadata.publishedDate = publishedDate.nilIfEmptyAfterTrimming
        metadata.language = language.nilIfEmptyAfterTrimming
        metadata.isbn = isbn.nilIfEmptyAfterTrimming
        metadata.originalLanguage = originalLanguage.nilIfEmptyAfterTrimming
        metadata.authorNationality = authorNationality.nilIfEmptyAfterTrimming
        metadata.translator = translator.nilIfEmptyAfterTrimming
        metadata.format = selectedFormat
        
        // Handle page count conversion
        if let pages = Int(pageCount.trimmingCharacters(in: .whitespacesAndNewlines)) {
            metadata.pageCount = pages
        } else {
            metadata.pageCount = nil
        }

        // Update user book notes
        userBook.notes = personalNotes.nilIfEmptyAfterTrimming
        
        // NEW: Update tags
        let tagsList = tags.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        userBook.tags = tagsList
        
        // Trigger save callback
        onSave(userBook)
    }
}

// MARK: - Helper Extension
fileprivate extension String {
    var nilIfEmptyAfterTrimming: String? {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

// MARK: - Preview
#Preview {
    let sampleMetadata = BookMetadata(
        googleBooksID: "preview-id",
        title: "Sample Book",
        authors: ["Sample Author"],
        format: .hardcover
    )
    
    let sampleBook = UserBook(
        readingStatus: .reading,
        tags: ["Fiction", "Philosophy"],
        metadata: sampleMetadata
    )
    
    return EditBookView(userBook: sampleBook) { _ in 
        // Preview save action
    }
}
