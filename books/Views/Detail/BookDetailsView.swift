import SwiftUI
import SwiftData

struct BookDetailsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var currentTheme
    
    @Bindable var book: UserBook
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                BookHeaderSection(book: book)
                
                RatingSection(rating: $book.rating)
                
                // NEW: Reading Progress Section
                if book.readingStatus == .reading || book.readingStatus == .read || book.currentPage > 0 {
                    ReadingProgressSection(book: book)
                }
                
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
                Button("Edit") {
                    isEditing = true
                }
                .foregroundColor(currentTheme.primaryAction)
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
        .themeAware()
    }
    
    private func deleteBook() {
        modelContext.delete(book)
        dismiss()
    }
}

// MARK: - NEW: Tags Display Section
struct BookTagsDisplaySection: View {
    @Environment(\.appTheme) private var currentTheme
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
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(currentTheme.secondaryText)
                    
                    Spacer()
                    
                    Button("Add Tag") {
                        showingAddTag = true
                    }
                    .labelMedium()
                    .foregroundColor(currentTheme.primaryAction)
                }
                
                // Tags display
                if book.tags.isEmpty {
                    Text("No tags added")
                        .bodySmall()
                        .foregroundColor(currentTheme.secondaryText)
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
    @Environment(\.appTheme) private var currentTheme
    let tag: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Text(tag)
                .culturalTag()
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .labelSmall()
                    .foregroundColor(currentTheme.secondaryText)
            }
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(currentTheme.surfaceVariant)
        .cornerRadius(Theme.CornerRadius.small)
    }
}


// MARK: - Header Section
struct BookHeaderSection: View {
    @Environment(\.appTheme) private var currentTheme
    var book: UserBook
    
    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.lg) {
            BookCoverImage(
                imageURL: book.metadata?.imageURL?.absoluteString,
                width: 120,
                height: 180
            )
            .shadow(color: .black.opacity(0.2), radius: 8, x: 4, y: 4)
            
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text(book.metadata?.title ?? "Unknown Title")
                    .bookTitle()
                    .foregroundColor(currentTheme.primaryText)
                
                // Author name navigation using NavigationLink with AuthorSearchRequest
                if let authors = book.metadata?.authors, !authors.isEmpty {
                    NavigationLink(value: AuthorSearchRequest(authorName: authors.first!)) {
                        Text(authors.joined(separator: ", "))
                            .authorName()
                            .foregroundStyle(currentTheme.primaryAction)
                            .underline()
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("Unknown Author")
                        .authorName()
                        .foregroundStyle(currentTheme.secondaryText)
                }
                
                if let genre = book.metadata?.genre, !genre.isEmpty {
                    Text(genre.first!)
                        .culturalTag()
                        .fontWeight(.medium)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(currentTheme.primaryAction.opacity(0.2))
                        .foregroundColor(currentTheme.primaryAction)
                        .cornerRadius(Theme.CornerRadius.small)
                }
                
                // Status selector - prominent placement below genre
                BookStatusSelector(book: book)
                    .padding(.top, Theme.Spacing.xs)
                
                Spacer()
            }
            .frame(minHeight: 180)
        }
    }
}

// MARK: - Rating Section
struct RatingSection: View {
    @Environment(\.appTheme) private var currentTheme
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
                            .foregroundColor(currentTheme.accentHighlight)
                    }
                    .scaleEffect(star == rating ? 1.25 : 1.0)
                    .animation(Theme.Animation.bouncySpring, value: rating)
                }
                Spacer()
            }
        } label: {
            Text("Your Rating")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(currentTheme.secondaryText)
        }
    }
}

// MARK: - Description Section
struct DescriptionSection: View {
    @Environment(\.appTheme) private var currentTheme
    let description: String
    @State private var isExpanded = false
    
    private var isTruncated: Bool {
        description.count > 250
    }
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
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
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(currentTheme.secondaryText)
        }
    }
}

// MARK: - Notes Section
struct NotesSection: View {
    @Environment(\.appTheme) private var currentTheme
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
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(currentTheme.secondaryText)
        }
    }
}

// MARK: - Publication Details Section - ENHANCED
struct PublicationDetailsSection: View {
    @Environment(\.appTheme) private var currentTheme
    let book: UserBook
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 0) {
                // Basic Details
                BasicDetailsView(book: book)
                
                // Divider between sections
                if hasBasicInfo(book: book) && (hasCulturalInfo(book: book) || hasPublicationInfo(book: book)) {
                    Divider()
                        .padding(.vertical, Theme.Spacing.md)
                }
                
                // Cultural Details  
                CulturalDetailsView(book: book)
                
                // Divider between sections
                if hasCulturalInfo(book: book) && hasPublicationInfo(book: book) {
                    Divider()
                        .padding(.vertical, Theme.Spacing.md)
                }
                
                // Publication Info
                PublicationInfoView(book: book)
            }
        } label: {
            Text("Details")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(currentTheme.secondaryText)
        }
    }
    
    private func hasBasicInfo(book: UserBook) -> Bool {
        return book.metadata?.format != nil ||
               !(book.metadata?.genre.isEmpty ?? true) ||
               book.metadata?.pageCount != nil
    }
    
    private func hasCulturalInfo(book: UserBook) -> Bool {
        return !(book.metadata?.language?.isEmpty ?? true) ||
               !(book.metadata?.originalLanguage?.isEmpty ?? true) ||
               book.metadata?.authorNationality != nil
    }
    
    private func hasPublicationInfo(book: UserBook) -> Bool {
        return !(book.metadata?.publisher?.isEmpty ?? true) ||
               !(book.metadata?.publishedDate?.isEmpty ?? true) ||
               book.metadata?.isbn != nil
    }
}

// MARK: - Enhanced Detail Row View - iOS Settings Style
struct DetailRowView: View {
    @Environment(\.appTheme) private var currentTheme
    let label: String
    let value: String
    var icon: String? = nil
    var isPlaceholder: Bool = false
    
    var body: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.md) {
            // Label - iOS Settings style (left-aligned, lighter weight)
            Text(label)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(currentTheme.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Value - Right-aligned with more prominence
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isPlaceholder ? currentTheme.secondaryText.opacity(0.7) : currentTheme.secondaryText)
                .italic(isPlaceholder)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 12) // iOS Settings-like spacing
        .contentShape(Rectangle())
    }
}

// MARK: - Broken down detail views
struct BasicDetailsView: View {
    let book: UserBook
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let format = book.metadata?.format {
                DetailRowView(
                    label: "Format",
                    value: format.rawValue
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
        VStack(alignment: .leading, spacing: 0) {
            if let language = book.metadata?.language, !language.isEmpty {
                DetailRowView(
                    label: "Language",
                    value: language
                )
            }
            
            if let originalLanguage = book.metadata?.originalLanguage, !originalLanguage.isEmpty {
                DetailRowView(
                    label: "Original Language",
                    value: originalLanguage
                )
            }
            
            // Always show Author Nationality for cultural tracking
            DetailRowView(
                label: "Author Nationality",
                value: book.metadata?.authorNationality ?? "Not specified",
                isPlaceholder: book.metadata?.authorNationality == nil
            )
            
            // Always show Author Gender for cultural tracking
            DetailRowView(
                label: "Author Gender",
                value: book.metadata?.authorGender?.rawValue ?? "Not specified",
                isPlaceholder: book.metadata?.authorGender == nil
            )
            
        }
    }
}

struct PublicationInfoView: View {
    let book: UserBook
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let publisher = book.metadata?.publisher, !publisher.isEmpty {
                DetailRowView(
                    label: "Publisher",
                    value: publisher
                )
            }
            
            if let publishedDate = book.metadata?.publishedDate, !publishedDate.isEmpty {
                DetailRowView(
                    label: "Published",
                    value: publishedDate
                )
            }
            
            if let isbn = book.metadata?.isbn {
                DetailRowView(
                    label: "ISBN",
                    value: isbn
                )
            }
        }
    }
}

// MARK: - Action Buttons Section
struct ActionButtonsSection: View {
    @Environment(\.appTheme) private var currentTheme
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
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .materialButton(style: .tonal, size: .large)
            .shadow(color: currentTheme.primary.opacity(0.2), radius: 4, x: 0, y: 2)
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

// MARK: - NEW: Reading Progress Section (Enhanced Accessibility)
struct ReadingProgressSection: View {
    @Environment(\.appTheme) private var currentTheme
    @Bindable var book: UserBook
    @State private var showingPageInput = false
    @State private var showingReadingSessionInput = false
    
    private var totalPages: Int {
        book.metadata?.pageCount ?? 0
    }
    
    private var progressPercentage: Int {
        guard totalPages > 0 else { return 0 }
        return min(Int((Double(book.currentPage) / Double(totalPages)) * 100), 100)
    }
    
    private var accessibilityProgressDescription: String {
        if totalPages > 0 {
            return "Reading progress: \(book.currentPage) of \(totalPages) pages, \(progressPercentage) percent complete"
        } else {
            return "Reading progress: page \(book.currentPage)"
        }
    }
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                // Progress Header
                HStack {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Reading Progress")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(currentTheme.primaryText)
                        
                        if totalPages > 0 {
                            Text("\(book.currentPage) of \(totalPages) pages")
                                .bodyMedium()
                                .foregroundColor(currentTheme.secondaryText)
                        } else {
                            Text("Page \(book.currentPage)")
                                .bodyMedium()
                                .foregroundColor(currentTheme.secondaryText)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(accessibilityProgressDescription)
                    
                    Spacer()
                    
                    // Progress percentage
                    if totalPages > 0 {
                        Text("\(progressPercentage)%")
                            .titleSmall()
                            .fontWeight(.bold)
                            .foregroundColor(currentTheme.primaryAction)
                            .accessibilityLabel("\(progressPercentage) percent complete")
                    }
                }
                
                // Progress Bar
                if totalPages > 0 {
                    ProgressView(value: book.readingProgress)
                        .tint(currentTheme.primaryAction)
                        .scaleEffect(y: 1.5, anchor: .center)
                        .animation(Theme.Animation.accessible, value: book.readingProgress)
                        .accessibilityLabel("Reading progress")
                        .accessibilityValue("\(progressPercentage) percent complete")
                }
                
                // Action Buttons
                HStack(spacing: Theme.Spacing.sm) {
                    Button("Update Progress") {
                        showingPageInput = true
                    }
                    .materialButton(style: .tonal, size: .small)
                    .accessibilityHint("Opens page input to update your current reading progress")
                    
                    if book.readingStatus == .reading {
                        Button("Log Session") {
                            showingReadingSessionInput = true
                        }
                        .materialButton(style: .outlined, size: .small)
                        .accessibilityHint("Opens form to log a completed reading session")
                    }
                }
                
                // Estimated Finish Date
                if let estimatedFinish = book.estimatedFinishDate, book.readingStatus == .reading {
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "calendar")
                            .labelSmall()
                            .foregroundColor(currentTheme.secondaryText)
                        
                        Text("Estimated finish: \(estimatedFinish.formatted(date: .abbreviated, time: .omitted))")
                            .labelSmall()
                            .foregroundColor(currentTheme.secondaryText)
                    }
                    .padding(.top, Theme.Spacing.xs)
                }
                
                // Reading Stats
                if !book.readingSessions.isEmpty {
                    readingStatsView
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Reading Progress Section")
        .sheet(isPresented: $showingPageInput) {
            PageInputView(
                currentPage: Binding(
                    get: { book.currentPage },
                    set: { newValue in book.currentPage = newValue }
                ),
                totalPages: Binding(
                    get: { book.metadata?.pageCount ?? 0 },
                    set: { newValue in
                        book.metadata?.pageCount = newValue > 0 ? newValue : nil
                    }
                ),
                onSave: {
                    book.updateReadingProgress()
                }
            )
        }
        .sheet(isPresented: $showingReadingSessionInput) {
            ReadingSessionInputView(book: book)
        }
    }
    
    @ViewBuilder
    private var readingStatsView: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Divider()
                .padding(.vertical, Theme.Spacing.xs)
            
            Text("Reading Stats")
                .labelMedium()
                .fontWeight(.semibold)
                .foregroundColor(currentTheme.primaryText)
            
            HStack(spacing: Theme.Spacing.lg) {
                StatItemView(
                    icon: "clock",
                    value: "\(book.totalReadingTimeMinutes / 60)h \(book.totalReadingTimeMinutes % 60)m",
                    label: "Total Time"
                )
                
                if let pace = book.averageReadingPace() {
                    StatItemView(
                        icon: "speedometer",
                        value: String(format: "%.1f", pace),
                        label: "Pages/Hour"
                    )
                }
                
                StatItemView(
                    icon: "book.pages",
                    value: "\(book.readingSessions.count)",
                    label: "Sessions"
                )
            }
        }
    }
}

// MARK: - Reading Stats Item
struct StatItemView: View {
    @Environment(\.appTheme) private var currentTheme
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .labelMedium()
                .foregroundColor(currentTheme.primaryAction)
            
            Text(value)
                .labelMedium()
                .fontWeight(.bold)
                .foregroundColor(currentTheme.primaryText)
            
            Text(label)
                .labelSmall()
                .foregroundColor(currentTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Reading Session Input View
struct ReadingSessionInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var currentTheme
    @Bindable var book: UserBook
    
    @State private var durationText = ""
    @State private var pagesReadText = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Reading Session") {
                    HStack {
                        Text("Duration (minutes)")
                            .labelMedium()
                        Spacer()
                        TextField("0", text: $durationText)
                            .frame(width: 80)
                            .bodyMedium()
                            .keyboardType(.numberPad)
                    }
                    
                    HStack {
                        Text("Pages Read")
                            .labelMedium()
                        Spacer()
                        TextField("0", text: $pagesReadText)
                            .frame(width: 80)
                            .bodyMedium()
                            .keyboardType(.numberPad)
                    }
                }
                
                if let duration = Int(durationText), let pages = Int(pagesReadText), duration > 0, pages > 0 {
                    Section("Session Stats") {
                        HStack {
                            Text("Reading Pace")
                            Spacer()
                            Text(String(format: "%.1f pages/hour", Double(pages) / (Double(duration) / 60.0)))
                                .foregroundColor(currentTheme.primaryAction)
                        }
                        
                        HStack {
                            Text("New Current Page")
                            Spacer()
                            Text("\(book.currentPage + pages)")
                                .foregroundColor(currentTheme.primaryAction)
                        }
                    }
                }
            }
            .navigationTitle("Log Reading Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSession()
                        dismiss()
                    }
                    .disabled(!isValidInput)
                }
            }
        }
    }
    
    private var isValidInput: Bool {
        guard let duration = Int(durationText),
              let pages = Int(pagesReadText) else {
            return false
        }
        return duration > 0 && pages > 0 && pages <= 1000 // reasonable limits
    }
    
    private func saveSession() {
        guard let duration = Int(durationText),
              let pages = Int(pagesReadText) else { return }
        
        book.addReadingSession(minutes: duration, pagesRead: pages)
    }
}