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
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Basic Information Section
                Section {
                    TextField("Title", text: $title)
                        .bodyMedium()
                    TextField("Authors (comma separated)", text: $authors)
                        .bodyMedium()
                } header: {
                    Text("Book Information")
                        .titleSmall()
                        .foregroundColor(Theme.Color.PrimaryText)
                }
                
                // Format & Publication Section
                Section {
                    // NEW: Book Format Picker
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Format")
                            .bodyMedium()
                            .foregroundColor(Theme.Color.PrimaryText)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: Theme.Spacing.sm) {
                            ForEach(BookFormat.allCases) { format in
                                Button(action: {
                                    selectedFormat = selectedFormat == format ? nil : format
                                }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: format.icon)
                                            .font(.system(size: 20))
                                            .foregroundColor(selectedFormat == format ? .white : Theme.Color.PrimaryAction)
                                        
                                        Text(format.rawValue)
                                            .labelSmall()
                                            .foregroundColor(selectedFormat == format ? .white : Theme.Color.PrimaryText)
                                    }
                                    .frame(height: 60)
                                    .frame(maxWidth: .infinity)
                                    .background(selectedFormat == format ? Theme.Color.PrimaryAction : Theme.Color.CardBackground)
                                    .cornerRadius(Theme.CornerRadius.medium)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                            .stroke(selectedFormat == format ? Theme.Color.PrimaryAction : Theme.Color.Outline, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    TextField("Publisher", text: $publisher)
                        .bodyMedium()
                    TextField("Published Date", text: $publishedDate)
                        .bodyMedium()
                    TextField("Total Pages", text: $pageCount)
                        .keyboardType(.numberPad)
                        .bodyMedium()
                    TextField("ISBN", text: $isbn)
                        .bodyMedium()
                } header: {
                    Text("Format & Publication")
                        .titleSmall()
                        .foregroundColor(Theme.Color.PrimaryText)
                }
                
                // Cultural & Language Section
                Section {
                    TextField("Language of this Edition", text: $language)
                        .bodyMedium()
                    TextField("Original Language", text: $originalLanguage)
                        .bodyMedium()
                    TextField("Author Nationality", text: $authorNationality)
                        .bodyMedium()
                    TextField("Translator", text: $translator)
                        .bodyMedium()
                } header: {
                    Text("Cultural & Language Details")
                        .titleSmall()
                        .foregroundColor(Theme.Color.PrimaryText)
                } footer: {
                    Text("Help track the cultural diversity of your reading by adding author nationality and original language information.")
                        .labelSmall()
                        .foregroundColor(Theme.Color.SecondaryText)
                }
                
                // Personal Notes Section
                Section {
                    TextField("Your thoughts about this book...", text: $personalNotes, axis: .vertical)
                        .lineLimit(3...8)
                        .bodyMedium()
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
        metadata.format = selectedFormat // NEW: Save book format
        
        // Handle page count conversion
        if let pages = Int(pageCount.trimmingCharacters(in: .whitespacesAndNewlines)) {
            metadata.pageCount = pages
        } else {
            metadata.pageCount = nil
        }

        // Update user book notes
        userBook.notes = personalNotes.nilIfEmptyAfterTrimming
        
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
        metadata: sampleMetadata
    )
    
    return EditBookView(userBook: sampleBook) { _ in 
        // Preview save action
    }
}