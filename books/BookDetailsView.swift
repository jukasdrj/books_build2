import SwiftUI
import SwiftData

struct BookDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var book: UserBook
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    @State private var selectedAuthor: String?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                BookHeaderSection(book: book, onAuthorTap: { authorName in
                    selectedAuthor = authorName
                })
                
                // Interactive controls for user data
                HStack(spacing: 16) {
                    StatusSelector(book: book)
                    Spacer()
                    FavoriteButton(isFavorited: $book.isFavorited)
                }
                .padding(.horizontal)

                RatingSection(rating: $book.rating)
                
                // Details sections
                if let description = book.metadata?.bookDescription, !description.isEmpty {
                    DescriptionSection(description: description)
                }
                
                NotesSection(notes: $book.notes)

                PublicationDetailsSection(book: book)
                
                // Action buttons at the bottom
                ActionButtonsSection(
                    onEdit: { isEditing = true },
                    onDelete: { showingDeleteAlert = true }
                )
            }
            .padding()
        }
        .navigationTitle(book.metadata?.title ?? "Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                ShareLink(item: book.shareableText) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .alert("Delete Book?", isPresented: $showingDeleteAlert, actions: {
            Button("Delete", role: .destructive, action: deleteBook)
            Button("Cancel", role: .cancel) { }
        }, message: {
            Text("Are you sure you want to delete \"\(book.metadata?.title ?? "this book")\" from your library?")
        })
        .sheet(isPresented: $isEditing) {
            // Using the enhanced edit view now
            EnhancedEditBookView(book: book)
        }
        .navigationDestination(item: $selectedAuthor) { authorName in
            AuthorSearchResultsView(authorName: authorName)
        }
    }
    
    private func deleteBook() {
        modelContext.delete(book)
        dismiss()
    }
}

// MARK: - Header Section
struct BookHeaderSection: View {
    var book: UserBook
    let onAuthorTap: (String) -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 20) {
            BookCoverImage(
                imageURL: book.metadata?.imageURL?.absoluteString,
                width: 120,
                height: 180
            )
            .shadow(color: .black.opacity(0.2), radius: 8, x: 4, y: 4)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(book.metadata?.title ?? "Unknown Title")
                    .font(.title2.bold())
                
                // Make author name clickable to navigate to author search
                if let authors = book.metadata?.authors, !authors.isEmpty {
                    Button(action: {
                        onAuthorTap(authors.first ?? "")
                    }) {
                        Text(authors.joined(separator: ", "))
                            .font(.headline)
                            .foregroundStyle(.blue)
                            .underline()
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("Unknown Author")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                
                if let genre = book.metadata?.genre?.first {
                    Text(genre)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.2))
                        .foregroundColor(.purple)
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .frame(minHeight: 180)
        }
    }
}

// MARK: - Status Selector
struct StatusSelector: View {
    @Bindable var book: UserBook
    
    var body: some View {
        Picker("Status", selection: $book.readingStatus) {
            ForEach(ReadingStatus.allCases) { status in
                Text(status.rawValue).tag(status)
            }
        }
        .pickerStyle(.menu)
        .buttonStyle(.bordered)
        .tint(book.readingStatus.color)
    }
}

// MARK: - Favorite Button
struct FavoriteButton: View {
    @Binding var isFavorited: Bool
    
    var body: some View {
        Button(action: {
            isFavorited.toggle()
        }) {
            Image(systemName: isFavorited ? "heart.fill" : "heart")
                .font(.title2)
                .foregroundColor(isFavorited ? .pink : .secondary)
        }
    }
}


// MARK: - Rating Section
struct RatingSection: View {
    @Binding var rating: Int?
    
    var body: some View {
        GroupBox("Your Rating") {
            HStack {
                ForEach(1...5, id: \.self) { star in
                    Button(action: {
                        if rating == star {
                            rating = nil // Allow un-setting rating
                        } else {
                            rating = star
                        }
                    }) {
                        Image(systemName: star <= (rating ?? 0) ? "star.fill" : "star")
                            .font(.title)
                            .foregroundColor(.yellow)
                    }
                }
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Description Section
struct DescriptionSection: View {
    let description: String
    @State private var isExpanded = false
    
    private var isTruncated: Bool {
        description.count > 250
    }
    
    var body: some View {
        GroupBox("Description") {
            VStack(alignment: .leading, spacing: 8) {
                Text(description)
                    .font(.body)
                    .lineLimit(isExpanded ? nil : 5)
                
                if isTruncated {
                    Button(isExpanded ? "Show Less" : "Show More") {
                        withAnimation(.easeInOut) {
                            isExpanded.toggle()
                        }
                    }
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
    }
}

// MARK: - Notes Section
struct NotesSection: View {
    @Binding var notes: String?
    
    var body: some View {
        GroupBox("Personal Notes") {
            TextField("Your thoughts on the book...", text: Binding(
                get: { notes ?? "" },
                set: { notes = $0.isEmpty ? nil : $0 }
            ), axis: .vertical)
            .lineLimit(3...10)
            .textFieldStyle(.roundedBorder)
        }
    }
}


// MARK: - Publication Details Section
struct PublicationDetailsSection: View {
    let book: UserBook
    
    var body: some View {
        GroupBox("Details") {
            VStack(spacing: 10) {
                if let genre = book.metadata?.genre, !genre.isEmpty {
                    DetailRow(label: "Genre", value: genre.joined(separator: ", "))
                }
                if let language = book.metadata?.language, !language.isEmpty {
                    DetailRow(label: "Language", value: language)
                }
                if let originalLanguage = book.metadata?.originalLanguage, !originalLanguage.isEmpty {
                    DetailRow(label: "Original Language", value: originalLanguage)
                }
                if let translator = book.metadata?.translator, !translator.isEmpty {
                    DetailRow(label: "Translator", value: translator)
                }
                if let authorNationality = book.metadata?.authorNationality, !authorNationality.isEmpty {
                    DetailRow(label: "Author Nationality", value: authorNationality)
                }
                if let publisher = book.metadata?.publisher, !publisher.isEmpty {
                    DetailRow(label: "Publisher", value: publisher)
                }
                if let publishedDate = book.metadata?.publishedDate, !publishedDate.isEmpty {
                    DetailRow(label: "Published", value: publishedDate)
                }
                if let pageCount = book.metadata?.pageCount, pageCount > 0 {
                    DetailRow(label: "Pages", value: "\(pageCount)")
                }
                if let isbn = book.metadata?.isbn {
                    DetailRow(label: "ISBN", value: isbn)
                }
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline.bold())
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .multilineTextAlignment(.trailing)
        }
    }
}


// MARK: - Action Buttons Section
struct ActionButtonsSection: View {
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Button(role: .destructive, action: onDelete) {
                Label("Delete Book", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            Button(action: onEdit) {
                Label("Edit Details", systemImage: "pencil")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .controlSize(.large)
        .padding(.top)
    }
}

// MARK: - Extensions for Color and Shareable Text
extension ReadingStatus {
    var color: Color {
        switch self {
        case .read: .green
        case .reading: .purple
        case .toRead: .orange
        }
    }
}

extension UserBook {
    var shareableText: String {
        var components: [String] = []
        if let title = metadata?.title {
            components.append("Check out this book: \(title)")
        }
        if let authors = metadata?.authors, !authors.isEmpty {
            components.append("By \(authors.joined(separator: ", "))")
        }
        if let rating = rating {
            components.append("I rated it \(String(repeating: "⭐️", count: rating))")
        }
        if let notes = notes, !notes.isEmpty {
            components.append("\nMy thoughts: \(notes)")
        }
        return components.joined(separator: ". ")
    }
}

#Preview {
    let metadata = BookMetadata(
        googleBooksID: "preview-id",
        title: "The Midnight Library",
        authors: ["Matt Haig"],
        publishedDate: "2020",
        pageCount: 304,
        bookDescription: "Between life and death there is a library, and within that library, the shelves go on forever. Every book provides a chance to try another life you could have lived. To see how things would be if you had made other choices . . . Would you have done anything different, if you had the chance to undo your regrets?",
        language: "English",
        publisher: "Viking",
        isbn: "9780525559474",
        genre: ["Contemporary Fiction", "Fantasy"],
        originalLanguage: "English",
        authorNationality: "British"
    )
    
    let sampleBook = UserBook(
        readingStatus: .reading,
        isFavorited: true,
        rating: 5,
        notes: "An absolutely fantastic and though-provoking read!",
        metadata: metadata
    )
    
    return NavigationStack {
        BookDetailsView(book: sampleBook)
            .modelContainer(for: [UserBook.self, BookMetadata.self], inMemory: true)
    }
}