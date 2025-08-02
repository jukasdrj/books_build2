import SwiftUI
import SwiftData

struct EditBookView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var userBook: UserBook
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
    @State private var tags: String

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
        _tags = State(initialValue: userBook.tags.joined(separator: ", "))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Basic Information Section
                Section {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Book Title")
                            .labelMedium()
                            .foregroundColor(Color.theme.secondaryText)
                        Text(title)
                            .bodyMedium()
                            .textSelection(.enabled)
                            .foregroundColor(Color.theme.primaryText)
                            .padding(.vertical, Theme.Spacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityHint("Read-only book metadata")
                    }
                    
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Authors")
                            .labelMedium()
                            .foregroundColor(Color.theme.secondaryText)
                        Text(authors)
                            .bodyMedium()
                            .textSelection(.enabled)
                            .foregroundColor(Color.theme.primaryText)
                            .padding(.vertical, Theme.Spacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityHint("Read-only book metadata")
                    }
                } header: {
                    Text("Book Information")
                        .titleSmall()
                        .foregroundColor(Color.theme.primaryText)
                } footer: {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "lock.shield")
                            .foregroundColor(Color.theme.secondaryText)
                            .font(.caption)
                        Text("Title, authors, and other publication data are provided by Google Books and cannot be edited to maintain data consistency.")
                            .labelSmall()
                            .foregroundColor(Color.theme.secondaryText)
                    }
                }
                
                // Format & Publication Section
                Section {
                    // Book Format Picker
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Book Format")
                            .labelMedium()
                            .foregroundColor(Color.theme.secondaryText)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.sm) {
                            ForEach(BookFormat.allCases, id: \.self) { format in
                                Button(action: { selectedFormat = format == selectedFormat ? nil : format }) {
                                    VStack(spacing: Theme.Spacing.xs) {
                                        Image(systemName: format.icon)
                                            .font(.system(size: 20))
                                            .foregroundColor(selectedFormat == format ? Color.theme.onPrimary : Color.theme.primaryAction)
                                        Text(format.rawValue)
                                            .labelSmall()
                                            .foregroundColor(selectedFormat == format ? Color.theme.onPrimary : Color.theme.primaryText)
                                    }
                                    .frame(height: 60)
                                    .frame(maxWidth: .infinity)
                                    .background(selectedFormat == format ? Color.theme.primaryAction : Color.theme.cardBackground)
                                    .cornerRadius(Theme.CornerRadius.medium)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                            .stroke(selectedFormat == format ? Color.theme.primaryAction : Color.theme.outline, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Publisher")
                            .labelMedium()
                            .foregroundColor(Color.theme.secondaryText)
                        Text(publisher.isEmpty ? "Not available" : publisher)
                            .bodyMedium()
                            .textSelection(.enabled)
                            .foregroundColor(Color.theme.primaryText)
                            .padding(.vertical, Theme.Spacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityHint("Read-only book metadata")
                    }
                    
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Publication Date")
                            .labelMedium()
                            .foregroundColor(Color.theme.secondaryText)
                        Text(publishedDate.isEmpty ? "Not available" : publishedDate)
                            .bodyMedium()
                            .textSelection(.enabled)
                            .foregroundColor(Color.theme.primaryText)
                            .padding(.vertical, Theme.Spacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityHint("Read-only book metadata")
                    }
                    
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Page Count")
                            .labelMedium()
                            .foregroundColor(Color.theme.secondaryText)
                        Text(pageCount.isEmpty ? "Not available" : "\(pageCount) pages")
                            .bodyMedium()
                            .textSelection(.enabled)
                            .foregroundColor(Color.theme.primaryText)
                            .padding(.vertical, Theme.Spacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityHint("Read-only book metadata")
                    }
                    
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("ISBN")
                            .labelMedium()
                            .foregroundColor(Color.theme.secondaryText)
                        Text(isbn.isEmpty ? "Not available" : isbn)
                            .bodyMedium()
                            .textSelection(.enabled)
                            .foregroundColor(Color.theme.primaryText)
                            .padding(.vertical, Theme.Spacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityHint("Read-only book metadata")
                    }
                } header: {
                    Text("Format & Publication")
                        .titleSmall()
                        .foregroundColor(Color.theme.primaryText)
                } footer: {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "info.circle")
                            .foregroundColor(Color.theme.secondaryText)
                            .font(.caption)
                        Text("Only the book format can be customized. Other publication details are managed by Google Books.")
                            .labelSmall()
                            .foregroundColor(Color.theme.secondaryText)
                    }
                }
                
                // Cultural & Language Section
                Section {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Edition Language")
                            .labelMedium()
                            .foregroundColor(Color.theme.secondaryText)
                        Text(language.isEmpty ? "Not available" : language)
                            .bodyMedium()
                            .textSelection(.enabled)
                            .foregroundColor(Color.theme.primaryText)
                            .padding(.vertical, Theme.Spacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityHint("Read-only book metadata")
                    }
                    
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Original Language")
                            .labelMedium()
                            .foregroundColor(Color.theme.secondaryText)
                        TextField("Original publication language", text: $originalLanguage)
                            .bodyMedium()
                            .frame(minHeight: 44)
                    }
                    
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Author's Cultural Background")
                            .labelMedium()
                            .foregroundColor(Color.theme.secondaryText)
                        TextField("Author's nationality or cultural origin", text: $authorNationality)
                            .bodyMedium()
                            .frame(minHeight: 44)
                    }
                    
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Translator")
                            .labelMedium()
                            .foregroundColor(Color.theme.secondaryText)
                        TextField("Translator name (if applicable)", text: $translator)
                            .bodyMedium()
                            .frame(minHeight: 44)
                    }
                } header: {
                    Text("Cultural & Language Details")
                        .titleSmall()
                        .foregroundColor(Color.theme.primaryText)
                } footer: {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        HStack(spacing: Theme.Spacing.xs) {
                            Image(systemName: "info.circle")
                                .foregroundColor(Color.theme.secondaryText)
                                .font(.caption)
                            Text("Add your own cultural and translation details to help track the diversity of your reading.")
                                .labelSmall()
                                .foregroundColor(Color.theme.secondaryText)
                        }
                    }
                }
                
                // Tags Section
                Section {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Tags")
                            .labelMedium()
                            .foregroundColor(Color.theme.secondaryText)
                        TextField("Enter tags separated by commas", text: $tags)
                            .bodyMedium()
                            .frame(minHeight: 44)
                    }
                } header: {
                    Text("Organization")
                        .titleSmall()
                        .foregroundColor(Color.theme.primaryText)
                } footer: {
                    Text("Use tags to organize and categorize your books. Example: Fiction, Favorite, Philosophy, Must-Read")
                        .labelSmall()
                        .foregroundColor(Color.theme.secondaryText)
                }
                
                // Personal Notes Section
                Section {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Personal Reading Notes")
                            .labelMedium()
                            .foregroundColor(Color.theme.secondaryText)
                        TextField("Your thoughts, reflections, and notes...", text: $personalNotes, axis: .vertical)
                            .lineLimit(3...8)
                            .bodyMedium()
                            .frame(minHeight: 44)
                    }
                } header: {
                    Text("Personal Notes")
                        .titleSmall()
                        .foregroundColor(Color.theme.primaryText)
                }
            }
            .background(Color.theme.surface)
            .scrollContentBackground(.hidden)
            .navigationTitle("Edit Book Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .bodyMedium()
                        .foregroundColor(Color.theme.secondaryText)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAndDismiss()
                    }
                    .labelLarge()
                    .foregroundColor(Color.theme.primaryAction)
                }
            }
        }
    }
    
    private func saveAndDismiss() {
        guard let metadata = userBook.metadata else {
            dismiss()
            return
        }

        // The modifications are wrapped in a single block.
        // SwiftData automatically handles this as a single transaction.
        
        // Update user-editable metadata
        metadata.originalLanguage = originalLanguage.nilIfEmptyAfterTrimming
        metadata.authorNationality = authorNationality.nilIfEmptyAfterTrimming
        metadata.translator = translator.nilIfEmptyAfterTrimming
        metadata.format = selectedFormat
        
        // Update user-specific data
        userBook.notes = personalNotes.nilIfEmptyAfterTrimming
        
        let tagsList = tags.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        userBook.tags = tagsList
        
        // No need for explicit modelContext.save() if using @Bindable and SwiftData handles the environment
        
        onSave(userBook)
        dismiss()
    }
}

// MARK: - Helper Extension
fileprivate extension String {
    var nilIfEmptyAfterTrimming: String? {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}


// MARK: - Preview Wrapper
struct EditBookViewPreviewWrapper: View {
    @State private var sampleBook: UserBook
    private let container: ModelContainer

    init() {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: UserBook.self, configurations: config)
        
        let sampleMetadata = BookMetadata(
            googleBooksID: "preview-id",
            title: "Sample Book",
            authors: ["Sample Author"],
            format: .physical
        )
        
        let book = UserBook(
            readingStatus: .reading,
            tags: ["Fiction", "Philosophy"],
            metadata: sampleMetadata
        )
        
        container.mainContext.insert(book)
        
        _sampleBook = State(initialValue: book)
        self.container = container
    }

    var body: some View {
        EditBookView(userBook: sampleBook) { _ in
            // Preview save action
        }
        .modelContainer(container)
    }
}

// MARK: - Preview
#Preview {
    EditBookViewPreviewWrapper()
}