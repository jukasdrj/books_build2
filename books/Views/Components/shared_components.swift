import SwiftUI
import SwiftData

// MARK: - Book List Item (used in multiple views)
struct BookListItem: View {
    let book: UserBook
    let onAuthorTap: ((String) -> Void)?
    
    init(book: UserBook, onAuthorTap: ((String) -> Void)? = nil) {
        self.book = book
        self.onAuthorTap = onAuthorTap
    }
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Cover image
            BookCoverImage(
                imageURL: book.metadata?.imageURL?.absoluteString,
                width: 50,
                height: 70
            )
            
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                // Title
                Text(book.metadata?.title ?? "Unknown Title")
                    .bookTitle()
                    .lineLimit(2)
                
                // Author name - clickable only if callback provided
                if let authors = book.metadata?.authors, !authors.isEmpty, let firstAuthor = authors.first, let onAuthorTap = onAuthorTap {
                    Button(action: {
                        onAuthorTap(firstAuthor)
                    }) {
                        Text(authors.joined(separator: ", "))
                            .authorName()
                            .foregroundColor(Color.theme.primaryAction)
                            .underline(true)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(book.metadata?.authors.joined(separator: ", ") ?? "Unknown Author")
                        .authorName() // Use .authorName() even for plain display
                        .foregroundColor(Color.theme.secondaryText)
                }
                
                HStack(spacing: Theme.Spacing.sm) {
                    StatusBadge(status: book.readingStatus, style: .capsule)
                    
                    Spacer()
                    
                    if let rating = book.rating, rating > 0 {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .labelSmall()
                                    .foregroundColor(star <= rating ? Color.theme.accentHighlight : Color.theme.secondaryText.opacity(0.3))
                            }
                        }
                        .accessibilityLabel("\(rating) out of 5 stars")
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, Theme.Spacing.xs)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .accessibilityHint("Double tap to view book details")
    }
    
    private var accessibilityDescription: String {
        let title = book.metadata?.title ?? "Unknown Title"
        let author = book.metadata?.authors.joined(separator: ", ") ?? "Unknown Author"
        let status = book.readingStatus.rawValue
        let rating = book.rating != nil ? "\(book.rating!) star rating" : "No rating"
        
        return "\(title) by \(author). Status: \(status). \(rating)"
    }
}

// MARK: - Add Book View (Enhanced)
struct AddBookView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var title = ""
    @State private var authors = ""
    @State private var isbn = ""
    @State private var publisher = ""
    @State private var publishedDate = ""
    @State private var readingStatus: ReadingStatus = .toRead
    @State private var personalRating: Int = 0
    @State private var personalNotes = ""
    @State private var pageCount = ""
    @State private var addToWishlist = false
    @State private var language = ""
    @State private var originalLanguage = ""
    @State private var authorNationality = ""
    @State private var translator = ""
    
    // Form validation
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !authors.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                bookDetailsSection
                publicationDetailsSection
                culturalDetailsSection
                readingStatusSection
                ratingSection
                personalNotesSection
            }
            .background(Color.theme.surface)
            .scrollContentBackground(.hidden)
            .navigationTitle("Add Book")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { 
                        dismiss() 
                    }
                    .bodyMedium()
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveBook()
                        dismiss()
                    }
                    .disabled(!isFormValid)
                    .labelLarge()
                    .foregroundColor(isFormValid ? Color.theme.primaryAction : Color.theme.disabledText)
                }
            }
        }
    }
    
    // MARK: - Form Sections
    @ViewBuilder
    private var bookDetailsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                FormField(
                    label: "Title",
                    icon: "textformat",
                    text: $title,
                    placeholder: "Enter book title",
                    isRequired: true
                )
                
                FormField(
                    label: "Authors",
                    icon: "person.2",
                    text: $authors,
                    placeholder: "Separate multiple authors with commas",
                    isRequired: true
                )
                
                FormField(
                    label: "ISBN",
                    icon: "barcode",
                    text: $isbn,
                    placeholder: "International Standard Book Number"
                )
            }
        } header: {
            Text("Book Details")
                .titleSmall()
        }
    }
    
    @ViewBuilder
    private var publicationDetailsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                FormField(
                    label: "Publisher",
                    icon: "building.2",
                    text: $publisher,
                    placeholder: "Publishing company"
                )
                
                FormField(
                    label: "Published Date",
                    icon: "calendar",
                    text: $publishedDate,
                    placeholder: "Year or full date"
                )
                
                FormField(
                    label: "Total Pages",
                    icon: "doc.text",
                    text: $pageCount,
                    placeholder: "Number of pages",
                    keyboardType: .numberPad
                )
                
                FormField(
                    label: "Language",
                    icon: "globe",
                    text: $language,
                    placeholder: "Language of this edition"
                )
            }
        } header: {
            Text("Publication Details")
                .titleSmall()
        }
    }
    
    @ViewBuilder
    private var culturalDetailsSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                FormField(
                    label: "Original Language",
                    icon: "globe.americas",
                    text: $originalLanguage,
                    placeholder: "Language originally published in"
                )
                
                FormField(
                    label: "Author Nationality",
                    icon: "flag",
                    text: $authorNationality,
                    placeholder: "Author's country or nationality"
                )
                
                FormField(
                    label: "Translator",
                    icon: "textbook",
                    text: $translator,
                    placeholder: "If this is a translated work"
                )
            }
        } header: {
            Text("Cultural & Language Details")
                .titleSmall()
        } footer: {
            Text("Help track the cultural diversity of your reading by adding author nationality and original language information.")
                .labelSmall()
                .foregroundColor(Color.theme.secondaryText)
        }
    }
    
    @ViewBuilder
    private var readingStatusSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Image(systemName: "book.closed")
                        .foregroundColor(Color.theme.primaryAction)
                        .frame(width: 20)
                    Text("Status")
                        .labelLarge()
                }
                
                Picker("Status", selection: $readingStatus) {
                    ForEach(ReadingStatus.allCases, id: \.self) { status in
                        Text(status.rawValue)
                            .bodyMedium()
                            .tag(status)
                    }
                }
                .pickerStyle(.segmented)
                
                Toggle("Add to Wishlist", isOn: $addToWishlist)
                    .bodyMedium()
            }
        } header: {
            Text("Reading Status")
                .titleSmall()
        }
    }
    
    @ViewBuilder
    private var ratingSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Image(systemName: "star")
                        .foregroundColor(Color.theme.primaryAction)
                        .frame(width: 20)
                    Text("Rating")
                        .labelLarge()
                }
                
                HStack(spacing: Theme.Spacing.sm) {
                    HStack(spacing: 4) {
                        ForEach(1...5, id: \.self) { star in
                            Button(action: { 
                                personalRating = personalRating == star ? 0 : star 
                            }) {
                                Image(systemName: star <= personalRating ? "star.fill" : "star")
                                    .foregroundColor(star <= personalRating ? Color.theme.accentHighlight : Color.theme.secondaryText)
                                    .font(.title3)
                            }
                            .buttonStyle(.plain)
                            .scaleEffect(star <= personalRating ? 1.1 : 1.0)
                            .animation(Theme.Animation.gentleSpring, value: personalRating)
                        }
                    }
                    
                    Spacer()
                    
                    if personalRating > 0 {
                        Button("Clear") {
                            personalRating = 0
                        }
                        .labelSmall()
                        .foregroundColor(Color.theme.secondaryText)
                    }
                }
                .accessibilityElement()
                .accessibilityLabel("Rating")
                .accessibilityValue(personalRating > 0 ? "\(personalRating) out of 5 stars" : "No rating")
            }
        } header: {
            Text("Rating")
                .titleSmall()
        }
    }
    
    @ViewBuilder
    private var personalNotesSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Image(systemName: "note.text")
                        .foregroundColor(Color.theme.primaryAction)
                        .frame(width: 20)
                    Text("Personal Notes")
                        .labelLarge()
                }
                
                TextField("Your thoughts about this book...", text: $personalNotes, axis: .vertical)
                    .lineLimit(3...6)
                    .bodyMedium()
            }
        } header: {
            Text("Personal Notes")
                .titleSmall()
        } footer: {
            Text("Personal notes are private and separate from the book's description.")
                .labelSmall()
                .foregroundColor(Color.theme.secondaryText)
        }
    }
    
    private func saveBook() {
        guard isFormValid else { return }
        
        // Parse authors from comma-separated string
        let authorsList = authors.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        guard !authorsList.isEmpty else { return }
        
        // Create BookMetadata with all fields including the new ones
        let metadata = BookMetadata(
            googleBooksID: UUID().uuidString, // Generate unique ID for manually added books
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            authors: authorsList,
            publishedDate: publishedDate.isEmpty ? nil : publishedDate,
            pageCount: pageCount.isEmpty ? nil : Int(pageCount),
            bookDescription: nil, // Description not collected in this form
            imageURL: nil,
            language: language.isEmpty ? nil : language,
            previewLink: nil,
            infoLink: nil,
            publisher: publisher.isEmpty ? nil : publisher,
            isbn: isbn.isEmpty ? nil : isbn,
            genre: [],
            originalLanguage: originalLanguage.isEmpty ? nil : originalLanguage,
            authorNationality: authorNationality.isEmpty ? nil : authorNationality,
            translator: translator.isEmpty ? nil : translator
        )
        
        // Create UserBook - auto-date logic is now handled by the model
        let userBook = UserBook(
            readingStatus: readingStatus,
            onWishlist: addToWishlist,
            rating: personalRating > 0 ? personalRating : nil,
            notes: personalNotes.isEmpty ? nil : personalNotes,
            metadata: metadata
        )
        
        // Insert both objects into the model context
        modelContext.insert(userBook)
        modelContext.insert(metadata)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving book: \(error)")
        }
    }
}

// MARK: - Form Field Component
struct FormField: View {
    let label: String
    let icon: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    var isRequired: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: icon)
                    .labelMedium()
                    .foregroundColor(Color.theme.primaryAction)
                    .frame(width: 20)
                
                Text(label)
                    .labelLarge()
                    .foregroundColor(Color.theme.primaryText)
                
                if isRequired {
                    Text("*")
                        .labelLarge()
                        .foregroundColor(Color.theme.error)
                }
            }
            
            TextField(placeholder, text: $text)
                .bodyMedium()
                .keyboardType(keyboardType)
                .padding(.leading, 24) // Align with label text
        }
    }
}

#Preview {
    AddBookView()
        .modelContainer(for: [UserBook.self, BookMetadata.self], inMemory: true)
        .preferredColorScheme(.dark)
}