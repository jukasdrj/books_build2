// books-buildout-main/books/shared_components.swift
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
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(.primaryText)
                
                // Author name - clickable only if callback provided
                if let firstAuthor = book.metadata?.authors.first, let onAuthorTap = onAuthorTap {
                    Button(action: {
                        onAuthorTap(firstAuthor)
                    }) {
                        Text(book.metadata?.authors.joined(separator: ", ") ?? "Unknown Author")
                            .font(.subheadline)
                            .foregroundColor(.primaryAction)
                            .underline()
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(book.metadata?.authors.joined(separator: ", ") ?? "Unknown Author")
                        .font(.subheadline)
                        .foregroundColor(.secondaryText)
                }
                
                HStack {
                    Text(book.readingStatus.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(statusColor(for: book.readingStatus))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    if let rating = book.rating, rating > 0 {
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .font(.caption)
                                    .foregroundColor(.primaryAction)
                            }
                        }
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private func statusColor(for status: ReadingStatus) -> Color {
        switch status {
        case .read: return .primaryAction.opacity(0.8)
        case .reading: return .accentHighlight
        case .toRead: return .primaryAction.opacity(0.4)
        }
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
                Section(header: Text("Book Details")) {
                    TextField("Title", text: $title)
                    TextField("Authors (comma separated)", text: $authors)
                    TextField("ISBN (Optional)", text: $isbn)
                }
                
                Section(header: Text("Publication Details")) {
                    TextField("Publisher (Optional)", text: $publisher)
                    TextField("Published Date (Optional)", text: $publishedDate)
                    TextField("Total Pages (Optional)", text: $pageCount)
                        .keyboardType(.numberPad)
                    TextField("Language (Optional)", text: $language)
                }
                
                Section(header: Text("Cultural & Language Details")) {
                    TextField("Original Language (Optional)", text: $originalLanguage)
                    TextField("Author Nationality (Optional)", text: $authorNationality)
                    TextField("Translator (Optional)", text: $translator)
                }
                
                Section(header: Text("Reading Status")) {
                    Picker("Status", selection: $readingStatus) {
                        ForEach(ReadingStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Toggle("Add to Wishlist", isOn: $addToWishlist)
                }
                
                Section(header: Text("Rating")) {
                    HStack {
                        Text("Rating:")
                        Spacer()
                        HStack(spacing: 4) {
                            ForEach(1...5, id: \.self) { star in
                                Button(action: { personalRating = star }) {
                                    Image(systemName: star <= personalRating ? "star.fill" : "star")
                                        .foregroundColor(.primaryAction)
                                }
                            }
                        }
                        Button("Clear") {
                            personalRating = 0
                        }
                        .font(.caption)
                    }
                }
                
                Section(header: Text("Personal Notes")) {
                    TextField("Your thoughts about this book...", text: $personalNotes, axis: .vertical)
                        .lineLimit(3...6)
                    
                    Text("Personal notes are private and separate from the book's description.")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
            }
            .navigationTitle("Add Book")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveBook()
                        dismiss()
                    }
                    .disabled(title.isEmpty || authors.isEmpty)
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
        
        // Create BookMetadata with all fields including the new ones - correct parameter order
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
            genre: nil,
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