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
        HStack(spacing: 12) {
            // Cover image
            BookCoverImage(
                imageURL: book.metadata?.imageURL?.absoluteString,
                width: 50,
                height: 70
            )
            
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(book.metadata?.title ?? "Unknown Title")
                    .titleMedium()
                    .lineLimit(2)
                    .foregroundColor(Color.theme.primaryText)
                
                // Author name - clickable only if callback provided
                if let authors = book.metadata?.authors, !authors.isEmpty, let firstAuthor = authors.first, let onAuthorTap = onAuthorTap {
                    Button(action: {
                        onAuthorTap(firstAuthor)
                    }) {
                        Text(authors.joined(separator: ", "))
                            .bodyMedium()
                            .foregroundColor(Color.theme.primaryAction)
                            .underline()
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(book.metadata?.authors.joined(separator: ", ") ?? "Unknown Author")
                        .bodyMedium()
                        .foregroundColor(Color.theme.secondaryText)
                }
                
                HStack {
                    StatusBadge(status: book.readingStatus, style: .capsule)
                    
                    Spacer()
                    
                    if let rating = book.rating, rating > 0 {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.caption)
                                    .foregroundColor(Color.theme.accentHighlight)
                            }
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Book View
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
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                        .bodyMedium()
                    TextField("Authors (comma separated)", text: $authors)
                        .bodyMedium()
                    TextField("ISBN (Optional)", text: $isbn)
                        .bodyMedium()
                } header: {
                    Text("Book Details")
                        .titleSmall()
                }
                
                Section {
                    TextField("Publisher (Optional)", text: $publisher)
                        .bodyMedium()
                    TextField("Published Date (Optional)", text: $publishedDate)
                        .bodyMedium()
                    TextField("Total Pages (Optional)", text: $pageCount)
                        .keyboardType(.numberPad)
                        .bodyMedium()
                    TextField("Language (Optional)", text: $language)
                        .bodyMedium()
                } header: {
                    Text("Publication Details")
                        .titleSmall()
                }
                
                Section {
                    TextField("Original Language (Optional)", text: $originalLanguage)
                        .bodyMedium()
                    TextField("Author Nationality (Optional)", text: $authorNationality)
                        .bodyMedium()
                    TextField("Translator (Optional)", text: $translator)
                        .bodyMedium()
                } header: {
                    Text("Cultural & Language Details")
                        .titleSmall()
                }
                
                Section {
                    Picker("Status", selection: $readingStatus) {
                        ForEach(ReadingStatus.allCases, id: \.self) { status in
                            Text(status.rawValue)
                                .bodyMedium()
                                .tag(status)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Toggle("Add to Wishlist", isOn: $addToWishlist)
                        .bodyMedium()
                } header: {
                    Text("Reading Status")
                        .titleSmall()
                }
                
                Section {
                    HStack {
                        Text("Rating:")
                            .bodyMedium()
                        Spacer()
                        HStack(spacing: 4) {
                            ForEach(1...5, id: \.self) { star in
                                Button(action: { personalRating = star }) {
                                    Image(systemName: star <= personalRating ? "star.fill" : "star")
                                        .foregroundColor(Color.theme.primaryAction)
                                }
                            }
                        }
                        Button("Clear") {
                            personalRating = 0
                        }
                        .labelSmall()
                    }
                } header: {
                    Text("Rating")
                        .titleSmall()
                }
                
                Section {
                    TextField("Your thoughts about this book...", text: $personalNotes, axis: .vertical)
                        .lineLimit(3...6)
                        .bodyMedium()
                    
                    Text("Personal notes are private and separate from the book's description.")
                        .labelSmall()
                        .foregroundColor(Color.theme.secondaryText)
                } header: {
                    Text("Personal Notes")
                        .titleSmall()
                }
            }
            .navigationTitle("Add Book")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .bodyMedium()
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveBook()
                        dismiss()
                    }
                    .disabled(title.isEmpty || authors.isEmpty)
                    .tint(Color.theme.primaryAction)
                    .labelLarge()
                }
            }
        }
    }
    
    private func saveBook() {
        guard !title.isEmpty else { return }
        
        // Parse authors from comma-separated string
        let authorsList = authors.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        guard !authorsList.isEmpty else { return }
        
        // Create BookMetadata with all fields including the new ones
        let metadata = BookMetadata(
            googleBooksID: UUID().uuidString, // Generate unique ID for manually added books
            title: title,
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