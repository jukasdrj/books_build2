import SwiftUI

struct EditBookView: View {
    @Environment(\.dismiss) private var dismiss
    
    let userBook: UserBook
    let onSave: (UserBook) -> Void
    
    // State properties remain non-optional Strings for the UI
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

    init(userBook: UserBook, onSave: @escaping (UserBook) -> Void) {
        self.userBook = userBook
        self.onSave = onSave
        
        // Initialize state from the model, providing empty strings for nil values
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
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Book Information")) {
                    TextField("Title", text: $title)
                    TextField("Authors (comma separated)", text: $authors)
                }
                
                Section(header: Text("Publication Details")) {
                    TextField("Publisher", text: $publisher)
                    TextField("Published Date", text: $publishedDate)
                    TextField("Total Pages", text: $pageCount).keyboardType(.numberPad)
                    TextField("ISBN", text: $isbn)
                }
                
                Section(header: Text("Cultural & Language Details")) {
                    TextField("Language of this Edition", text: $language)
                    TextField("Original Language", text: $originalLanguage)
                    TextField("Author Nationality", text: $authorNationality)
                    TextField("Translator", text: $translator)
                }
                
                Section(header: Text("Personal Notes")) {
                    TextField("Your thoughts about this book...", text: $personalNotes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Book")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveBook()
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    private func saveBook() {
        guard let metadata = userBook.metadata else { return }

        // --- THE IMPROVEMENT ---
        // Use the new extension for clean, safe optional assignment.
        metadata.title = title.trimmingCharacters(in: .whitespacesAndNewlines) // Title is not optional
        metadata.authors = authors.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        metadata.publisher = publisher.nilIfEmptyAfterTrimming
        metadata.publishedDate = publishedDate.nilIfEmptyAfterTrimming
        metadata.language = language.nilIfEmptyAfterTrimming
        metadata.isbn = isbn.nilIfEmptyAfterTrimming
        metadata.originalLanguage = originalLanguage.nilIfEmptyAfterTrimming
        metadata.authorNationality = authorNationality.nilIfEmptyAfterTrimming
        metadata.translator = translator.nilIfEmptyAfterTrimming
        
        // Handle conversion from String to Int for pageCount
        if let pages = Int(pageCount.trimmingCharacters(in: .whitespacesAndNewlines)) {
            metadata.pageCount = pages
        } else {
            metadata.pageCount = nil
        }

        // Assign to the UserBook's optional notes property
        userBook.notes = personalNotes.nilIfEmptyAfterTrimming
        
        // onSave will trigger the actual save in the parent view's context
        onSave(userBook)
    }
}

// You can place this helper extension in its own file or right here.
fileprivate extension String {
    /// Returns the string with leading/trailing whitespace removed. If the result is empty, returns nil.
    var nilIfEmptyAfterTrimming: String? {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
