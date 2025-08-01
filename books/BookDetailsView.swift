import SwiftUI
import SwiftData

struct BookDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var book: UserBook
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                BookHeaderSection(book: book)
                
                // Interactive controls for user data
                HStack(spacing: 16) {
                    BookStatusSelector(book: book)
                    Spacer()
                    FavoriteButton(isFavorited: $book.isFavorited)
                }
                .padding(.horizontal)

                RatingSection(rating: $book.rating)
                
                // NEW: Tags Section
                BookTagsDisplaySection(book: book)
                
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
            EditBookView(userBook: book, onSave: { updatedBook in
                // This closure is called when the edit view saves.
                // Because `userBook` is a reference type, the changes
                // will already be reflected. We just need to handle dismissal.
                isEditing = false
            })
        }
    }
    
    private func deleteBook() {
        modelContext.delete(book)
        dismiss()
    }
}

// MARK: - NEW: Tags Display Section
struct BookTagsDisplaySection: View {
    @Bindable var book: UserBook
    @State private var showingTagsManager = false
    @State private var newTag = ""
    @State private var showingAddTag = false
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                // Header with manage button
                HStack {
                    Text("Tags")
                        .titleSmall()
                        .foregroundColor(Color.theme.primaryText)
                    
                    Spacer()
                    
                    Button("Add Tag") {
                        showingAddTag = true
                    }
                    .labelMedium()
                    .foregroundColor(Color.theme.primaryAction)
                }
                
                // Tags display
                if book.tags.isEmpty {
                    Text("No tags added")
                        .bodySmall()
                        .foregroundColor(Color.theme.secondaryText)
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, Theme.Spacing.sm)
                } else {
                    FlowLayout(spacing: Theme.Spacing.xs) {
                        ForEach(book.tags, id: \.self) { tag in
                            TagChip(
                                tag: tag,
                                onRemove: { removeTag(tag) }
                            )
                        }
                    }
                }
            }
        }
        .alert("Add Tag", isPresented: $showingAddTag) {
            TextField("Tag name", text: $newTag)
            Button("Add", action: addTag)
            Button("Cancel", role: .cancel) { 
                newTag = ""
            }
        } message: {
            Text("Enter a tag to organize this book")
        }
    }
    
    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty && !book.tags.contains(trimmed) else {
            newTag = ""
            return
        }
        
        withAnimation(.easeInOut(duration: 0.25)) {
            book.tags.append(trimmed)
        }
        newTag = ""
    }
    
    private func removeTag(_ tag: String) {
        withAnimation(.easeInOut(duration: 0.25)) {
            book.tags = book.tags.filter { $0 != tag }
        }
    }
}

// MARK: - Tag Components
struct TagChip: View {
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .labelSmall()
                .foregroundColor(Color.theme.primaryText)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundColor(Color.theme.secondaryText)
            }
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, 4)
        .background(Color.theme.surfaceVariant)
        .cornerRadius(Theme.CornerRadius.small)
    }
}

// MARK: - Flow Layout for Tags
struct FlowLayout: Layout {
    let spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let containerWidth = proposal.width ?? 0
        var height: CGFloat = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            if rowWidth + subviewSize.width + spacing > containerWidth && rowWidth > 0 {
                height += rowHeight + spacing
                rowWidth = subviewSize.width
                rowHeight = subviewSize.height
            } else {
                rowWidth += subviewSize.width + (rowWidth > 0 ? spacing : 0)
                rowHeight = max(rowHeight, subviewSize.height)
            }
        }
        
        height += rowHeight
        return CGSize(width: containerWidth, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var y: CGFloat = bounds.minY
        
        for subview in subviews {
            let subviewSize = subview.sizeThatFits(.unspecified)
            
            if rowWidth + subviewSize.width + spacing > bounds.width && rowWidth > 0 {
                y += rowHeight + spacing
                rowWidth = 0
                rowHeight = 0
            }
            
            subview.place(
                at: CGPoint(x: bounds.minX + rowWidth, y: y),
                proposal: ProposedViewSize(subviewSize)
            )
            
            rowWidth += subviewSize.width + spacing
            rowHeight = max(rowHeight, subviewSize.height)
        }
    }
}

// MARK: - Header Section
struct BookHeaderSection: View {
    var book: UserBook
    
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
                    .headlineMedium()
                    .foregroundColor(Color.theme.primaryText)
                
                // Author name navigation using NavigationLink with value
                if let authors = book.metadata?.authors, !authors.isEmpty {
                    NavigationLink(value: authors.first!) {
                        Text(authors.joined(separator: ", "))
                            .titleMedium()
                            .foregroundStyle(Color.theme.primaryAction)
                            .underline()
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("Unknown Author")
                        .titleMedium()
                        .foregroundStyle(Color.theme.secondaryText)
                }
                
                if let genre = book.metadata?.genre, !genre.isEmpty {
                    Text(genre.first!)
                        .labelSmall()
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.theme.primaryAction.opacity(0.2))
                        .foregroundColor(Color.theme.primaryAction)
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .frame(minHeight: 180)
        }
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
                .foregroundColor(isFavorited ? Color.theme.accentHighlight : Color.theme.secondaryText)
        }
    }
}

// MARK: - Rating Section
struct RatingSection: View {
    @Binding var rating: Int?
    
    var body: some View {
        GroupBox {
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
                            .foregroundColor(Color.theme.accentHighlight)
                    }
                    .scaleEffect(star == rating ? 1.25 : 1.0)
                    .animation(Theme.Animation.bouncySpring, value: rating)
                }
                Spacer()
            }
        } label: {
            Text("Your Rating")
                .labelLarge()
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
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                Text(description)
                    .bodyMedium()
                    .lineLimit(isExpanded ? nil : 5)
                
                if isTruncated {
                    Button(isExpanded ? "Show Less" : "Show More") {
                        withAnimation(.easeInOut) {
                            isExpanded.toggle()
                        }
                    }
                    .labelMedium()
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        } label: {
            Text("Description")
                .labelLarge()
        }
    }
}

// MARK: - Notes Section
struct NotesSection: View {
    @Binding var notes: String?
    
    var body: some View {
        GroupBox {
            TextField("Your thoughts on the book...", text: Binding(
                get: { notes ?? "" },
                set: { notes = $0.isEmpty ? nil : $0 }
            ), axis: .vertical)
            .lineLimit(3...10)
            .textFieldStyle(.roundedBorder)
            .bodyMedium()
        } label: {
            Text("Personal Notes")
                .labelLarge()
        }
    }
}

// MARK: - Publication Details Section - SIMPLIFIED
struct PublicationDetailsSection: View {
    let book: UserBook
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                // Basic Details
                BasicDetailsView(book: book)
                
                // Cultural Details  
                CulturalDetailsView(book: book)
                
                // Publication Info
                PublicationInfoView(book: book)
            }
        } label: {
            Text("Details")
                .labelLarge()
        }
    }
}

// MARK: - Broken down detail views
struct BasicDetailsView: View {
    let book: UserBook
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            if let format = book.metadata?.format {
                DetailRowView(
                    label: "Format",
                    value: format.rawValue,
                    icon: format.icon
                )
            }
            
            if let genre = book.metadata?.genre, !genre.isEmpty {
                DetailRowView(
                    label: "Genre",
                    value: genre.joined(separator: ", ")
                )
            }
            
            if let pageCount = book.metadata?.pageCount, pageCount > 0 {
                DetailRowView(
                    label: "Pages",
                    value: "\(pageCount)"
                )
            }
        }
    }
}

struct CulturalDetailsView: View {
    let book: UserBook
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            if let language = book.metadata?.language, !language.isEmpty {
                DetailRowView(
                    label: "Language",
                    value: language,
                    icon: "globe"
                )
            }
            
            if let originalLanguage = book.metadata?.originalLanguage, !originalLanguage.isEmpty {
                DetailRowView(
                    label: "Original Language",
                    value: originalLanguage,
                    icon: "globe.americas"
                )
            }
            
            // Always show Author Nationality for cultural tracking
            DetailRowView(
                label: "Author Nationality",
                value: book.metadata?.authorNationality ?? "Not specified",
                icon: "flag",
                isPlaceholder: book.metadata?.authorNationality == nil
            )
            
            if let translator = book.metadata?.translator, !translator.isEmpty {
                DetailRowView(
                    label: "Translator",
                    value: translator,
                    icon: "textbook"
                )
            }
        }
    }
}

struct PublicationInfoView: View {
    let book: UserBook
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            if let publisher = book.metadata?.publisher, !publisher.isEmpty {
                DetailRowView(
                    label: "Publisher",
                    value: publisher,
                    icon: "building.2"
                )
            }
            
            if let publishedDate = book.metadata?.publishedDate, !publishedDate.isEmpty {
                DetailRowView(
                    label: "Published",
                    value: publishedDate,
                    icon: "calendar"
                )
            }
            
            if let isbn = book.metadata?.isbn {
                DetailRowView(
                    label: "ISBN",
                    value: isbn,
                    icon: "barcode"
                )
            }
        }
    }
}

// MARK: - Simple Detail Row View
struct DetailRowView: View {
    let label: String
    let value: String
    var icon: String? = nil
    var isPlaceholder: Bool = false
    
    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            // Icon
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(Color.theme.primaryAction)
                    .frame(width: 16)
            }
            
            // Label
            Text(label)
                .labelLarge()
                .foregroundColor(Color.theme.secondaryText)
                .frame(width: 120, alignment: .leading)
            
            // Value
            Text(value)
                .bodyMedium()
                .foregroundColor(isPlaceholder ? Color.theme.secondaryText.opacity(0.7) : Color.theme.primaryText)
                .italic(isPlaceholder)
            
            Spacer()
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
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "trash")
                    Text("Delete Book")
                        .labelLarge()
                }
                .frame(maxWidth: .infinity)
            }
            .materialButton(style: .outlined, size: .large)
            
            Button(action: onEdit) {
                HStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "pencil")
                    Text("Edit Details")
                        .labelLarge()
                }
                .frame(maxWidth: .infinity)
            }
            .materialButton(style: .filled, size: .large)
        }
        .padding(.top)
    }
}

// MARK: - Extensions for Shareable Text
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
        if !tags.isEmpty {
            components.append("Tags: \(tags.joined(separator: ", "))")
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
        tags: ["Fiction", "Philosophy", "Favorite"],
        metadata: metadata
    )
    
    return NavigationStack {
        BookDetailsView(book: sampleBook)
            .modelContainer(for: [UserBook.self, BookMetadata.self], inMemory: true)
    }
}