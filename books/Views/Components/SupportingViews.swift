import SwiftUI
import SwiftData

// MARK: - Status Badge
// A reusable view to display the reading status of a book, with different styles.
struct StatusBadge: View {
    @Environment(\.appTheme) private var currentTheme
    let status: ReadingStatus
    let style: Style
    
    enum Style {
        // Shows text and a colored dot (e.g., "Reading ●")
        case full
        // Shows only a colored dot, for compact spaces
        case compact
        // Shows text in a colored capsule
        case capsule
    }
    
    var body: some View {
        switch style {
        case .full:
            HStack(spacing: Theme.Spacing.xs) {
                Text(status.rawValue)
                    .labelMedium()
                    .foregroundColor(currentTheme.primaryText)
                Circle()
                    .fill(status.textColor(theme: currentTheme))
                    .frame(width: 8, height: 8)
            }
        case .compact:
            Circle()
                .fill(status.textColor(theme: currentTheme))
                .frame(width: 10, height: 10)
                .shadow(radius: 1)
        case .capsule:
            Text(status.rawValue)
                .labelSmall()
                .fontWeight(.medium)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xs)
                .background(status.textColor(theme: currentTheme).opacity(0.2))
                .foregroundColor(status.textColor(theme: currentTheme))
                .cornerRadius(Theme.CornerRadius.small)
        }
    }
}

// MARK: - Enhanced Edit Book View - UPDATED with Stylized Field Labels
struct EnhancedEditBookView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var currentTheme
    
    @Bindable var book: UserBook
    
    // State properties for UI
    @State private var title: String = ""
    @State private var authors: String = ""
    @State private var isbn: String = ""
    @State private var personalNotes: String = ""
    @State private var pageCount: String = ""
    @State private var publisher: String = ""
    @State private var language: String = ""
    @State private var publishedDate: String = ""
    @State private var originalLanguage: String = ""
    @State private var authorNationality: String = ""
    @State private var translator: String = ""
    @State private var selectedFormat: BookFormat?
    @State private var bookDescription: String = ""
    @State private var categories: [String] = []
    @State private var newCategory: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                // Basic Information Section
                Section {
                    StyledTextField(
                        label: "Title",
                        text: $title,
                        icon: "textformat",
                        placeholder: "Enter book title"
                    )
                    
                    StyledTextField(
                        label: "Authors", 
                        text: $authors,
                        icon: "person.2",
                        placeholder: "Separate multiple authors with commas"
                    )
                } header: {
                    Text("Book Information")
                        .titleSmall()
                        .foregroundColor(currentTheme.primaryText)
                }
                
                // Format & Publication Section
                Section {
                    // Book Format Picker
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        HStack(spacing: Theme.Spacing.xs) {
                            Image(systemName: "doc.richtext")
                                .labelMedium()
                                .foregroundColor(currentTheme.primary)
                            Text("Format")
                                .labelLarge()
                                .foregroundColor(currentTheme.primaryText)
                        }
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: Theme.Spacing.sm) {
                            ForEach(BookFormat.allCases) { format in
                                Button(action: {
                                    selectedFormat = selectedFormat == format ? nil : format
                                }) {
                                    VStack(spacing: Theme.Spacing.xs) {
                                        Image(systemName: format.icon)
                                            .font(.system(size: 20))
                                            .foregroundColor(selectedFormat == format ? .white : currentTheme.primary)
                                        
                                        Text(format.rawValue)
                                            .labelSmall()
                                            .foregroundColor(selectedFormat == format ? .white : currentTheme.primaryText)
                                    }
                                    .frame(height: 60)
                                    .frame(maxWidth: .infinity)
                                    .background(selectedFormat == format ? currentTheme.primary : currentTheme.cardBackground)
                                    .cornerRadius(Theme.CornerRadius.medium)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                            .stroke(selectedFormat == format ? currentTheme.primary : currentTheme.outline, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    StyledTextField(
                        label: "Publisher",
                        text: $publisher,
                        icon: "building.2",
                        placeholder: "Publishing company"
                    )
                    
                    StyledTextField(
                        label: "Published Date",
                        text: $publishedDate,
                        icon: "calendar",
                        placeholder: "Year or full date"
                    )
                    
                    StyledTextField(
                        label: "Total Pages",
                        text: $pageCount,
                        icon: "doc.text",
                        placeholder: "Number of pages",
                        keyboardType: .numberPad
                    )
                    
                    StyledTextField(
                        label: "ISBN",
                        text: $isbn,
                        icon: "barcode",
                        placeholder: "International Standard Book Number"
                    )
                } header: {
                    Text("Format & Publication")
                        .titleSmall()
                        .foregroundColor(currentTheme.primaryText)
                }
                
                // Cultural & Language Section
                Section {
                    StyledTextField(
                        label: "Language",
                        text: $language,
                        icon: "globe",
                        placeholder: "Language of this edition"
                    )
                    
                    StyledTextField(
                        label: "Original Language",
                        text: $originalLanguage,
                        icon: "globe.americas",
                        placeholder: "Language originally published in"
                    )
                    
                    StyledTextField(
                        label: "Author Nationality",
                        text: $authorNationality,
                        icon: "flag",
                        placeholder: "Author's country or nationality"
                    )
                    
                    StyledTextField(
                        label: "Translator",
                        text: $translator,
                        icon: "textbook",
                        placeholder: "If this is a translated work"
                    )
                } header: {
                    Text("Cultural & Language Details")
                        .titleSmall()
                        .foregroundColor(currentTheme.primaryText)
                } footer: {
                    Text("Help track the cultural diversity of your reading by adding author nationality and original language information.")
                        .labelSmall()
                        .foregroundColor(currentTheme.secondaryText)
                }
                
                // Categories Section
                Section {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        HStack {
                            StyledTextField(
                                label: "Add Category",
                                text: $newCategory,
                                icon: "tag",
                                placeholder: "Genre, topic, or theme",
                                onSubmit: addCategory
                            )
                            
                            Button("Add", action: addCategory)
                                .materialButton(style: .tonal, size: .small)
                                .disabled(newCategory.isEmpty)
                        }
                        
                        if !categories.isEmpty {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: Theme.Spacing.sm) {
                                ForEach(categories, id: \.self) { category in
                                    HStack(spacing: Theme.Spacing.xs) {
                                        Text(category)
                                            .labelSmall()
                                        
                                        Button(action: {
                                            categories.removeAll { $0 == category }
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption)
                                        }
                                    }
                                    .padding(.horizontal, Theme.Spacing.sm)
                                    .padding(.vertical, Theme.Spacing.xs)
                                    .background(currentTheme.primary.opacity(0.1))
                                    .foregroundColor(currentTheme.primary)
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Categories")
                        .titleSmall()
                        .foregroundColor(currentTheme.primaryText)
                }
                
                // Description Section
                Section {
                    StyledTextEditor(
                        label: "Description",
                        text: $bookDescription,
                        icon: "text.alignleft",
                        placeholder: "Book summary or description"
                    )
                } header: {
                    Text("Description")
                        .titleSmall()
                        .foregroundColor(currentTheme.primaryText)
                }
                
                // Personal Notes Section
                Section {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        HStack {
                            Image(systemName: "note.text")
                                .labelMedium()
                                .foregroundColor(currentTheme.primary)
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
                        .foregroundColor(currentTheme.primaryText)
                } footer: {
                    Text("Personal notes are private and separate from the book's description.")
                        .labelSmall()
                        .foregroundColor(currentTheme.secondaryText)
                }
            }
            .background(currentTheme.surface)
            .scrollContentBackground(.hidden)
            .navigationTitle("Edit Book Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { 
                        dismiss() 
                    }
                    .bodyMedium()
                    .foregroundColor(currentTheme.secondaryText)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .labelLarge()
                    .foregroundColor(currentTheme.primary)
                }
            }
        }
        .onAppear {
            loadBookData()
        }
    }
    
    private func addCategory() {
        let trimmedCategory = newCategory.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedCategory.isEmpty && !categories.contains(trimmedCategory) {
            categories.append(trimmedCategory)
            newCategory = ""
        }
    }
    
    private func loadBookData() {
        if let metadata = book.metadata {
            title = metadata.title
            authors = metadata.authors.joined(separator: ", ")
            publisher = metadata.publisher ?? ""
            publishedDate = metadata.publishedDate ?? ""
            pageCount = metadata.pageCount != nil ? "\(metadata.pageCount!)" : ""
            bookDescription = metadata.bookDescription ?? ""
            isbn = metadata.isbn ?? ""
            categories = metadata.genre
            language = metadata.language ?? ""
            originalLanguage = metadata.originalLanguage ?? ""
            authorNationality = metadata.authorNationality ?? ""
            translator = metadata.translator ?? ""
            selectedFormat = metadata.format
        }
        personalNotes = book.notes ?? ""
    }
    
    private func saveChanges() {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        if let existingMetadata = book.metadata {
            // Update existing metadata
            existingMetadata.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            existingMetadata.authors = authors.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
            existingMetadata.publisher = publisher.nilIfEmptyAfterTrimming
            existingMetadata.publishedDate = publishedDate.nilIfEmptyAfterTrimming
            existingMetadata.bookDescription = bookDescription.nilIfEmptyAfterTrimming
            existingMetadata.isbn = isbn.nilIfEmptyAfterTrimming
            existingMetadata.genre = categories
            existingMetadata.language = language.nilIfEmptyAfterTrimming
            existingMetadata.originalLanguage = originalLanguage.nilIfEmptyAfterTrimming
            existingMetadata.authorNationality = authorNationality.nilIfEmptyAfterTrimming
            existingMetadata.translator = translator.nilIfEmptyAfterTrimming
            existingMetadata.format = selectedFormat
            
            // Handle page count conversion
            if let pages = Int(pageCount.trimmingCharacters(in: .whitespacesAndNewlines)) {
                existingMetadata.pageCount = pages
            } else {
                existingMetadata.pageCount = nil
            }
        } else {
            // Create new metadata
            let newMetadata = BookMetadata(
                googleBooksID: UUID().uuidString,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                authors: authors.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty },
                publishedDate: publishedDate.nilIfEmptyAfterTrimming,
                pageCount: Int(pageCount.trimmingCharacters(in: .whitespacesAndNewlines)),
                bookDescription: bookDescription.nilIfEmptyAfterTrimming,
                publisher: publisher.nilIfEmptyAfterTrimming,
                isbn: isbn.nilIfEmptyAfterTrimming,
                genre: categories,
                originalLanguage: originalLanguage.nilIfEmptyAfterTrimming,
                authorNationality: authorNationality.nilIfEmptyAfterTrimming,
                translator: translator.nilIfEmptyAfterTrimming,
                format: selectedFormat
            )
            
            book.metadata = newMetadata
            modelContext.insert(newMetadata)
        }
        
        // Update user book notes
        book.notes = personalNotes.nilIfEmptyAfterTrimming
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save book changes: \(error)")
        }
    }
}

// MARK: - Styled Text Field Component
struct StyledTextField: View {
    @Environment(\.appTheme) private var currentTheme
    let label: String
    @Binding var text: String
    let icon: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    var onSubmit: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(currentTheme.primaryAction)
                    .frame(width: 20)
                
                Text(label)
                    .labelLarge()
                    .foregroundColor(currentTheme.primaryText)
            }
            
            TextField(placeholder, text: $text)
                .bodyMedium()
                .keyboardType(keyboardType)
                .onSubmit {
                    onSubmit?()
                }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Styled Text Editor Component
struct StyledTextEditor: View {
    @Environment(\.appTheme) private var currentTheme
    let label: String
    @Binding var text: String
    let icon: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(currentTheme.primaryAction)
                    .frame(width: 20)
                
                Text(label)
                    .labelLarge()
                    .foregroundColor(currentTheme.primaryText)
            }
            
            TextField(placeholder, text: $text, axis: .vertical)
                .lineLimit(3...8)
                .bodyMedium()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Helper Extension
fileprivate extension String {
    var nilIfEmptyAfterTrimming: String? {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

// MARK: - Book Status Selector
struct BookStatusSelector: View {
    @Bindable var book: UserBook
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Menu {
            ForEach(ReadingStatus.allCases, id: \.self) { status in
                Button(action: {
                    updateStatus(to: status)
                }) {
                    HStack {
                        Text(status.rawValue)
                        if book.readingStatus == status {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                StatusBadge(status: book.readingStatus, style: .capsule)
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func updateStatus(to status: ReadingStatus) {
        let oldStatus = book.readingStatus
        
        // Update the status
        book.readingStatus = status
        
        // ENHANCED: Explicitly handle reading completion when moving to 'read' status
        if status == .read && oldStatus != .read {
            // Complete the reading progress
            book.readingProgress = 1.0
            
            // Set current page to total pages if available
            if let pageCount = book.metadata?.pageCount, pageCount > 0 {
                book.currentPage = pageCount
                print("✅ BookStatusSelector: Completed progress - currentPage set to \(pageCount), progress set to 1.0")
            } else {
                print("✅ BookStatusSelector: Completed progress - progress set to 1.0, no page count available")
            }
            
            // Set completion date if not already set
            if book.dateCompleted == nil {
                book.dateCompleted = Date()
            }
            
            // Set start date if not already set
            if book.dateStarted == nil {
                book.dateStarted = Date()
            }
            
            // Haptic feedback for completion
            HapticFeedbackManager.shared.bookMarkedAsRead()
        }
        
        // Handle other status changes
        else if status == .reading && oldStatus != .reading && book.dateStarted == nil {
            book.dateStarted = Date()
        }
        else if status == .toRead {
            // Clear dates for "To Read" status
            book.dateStarted = nil
            book.dateCompleted = nil
        }
        
        // Force a refresh of reading progress if needed
        if status != .read {
            book.updateReadingProgress()
        }
        
        // Save the changes
        do {
            try modelContext.save()
            print("✅ BookStatusSelector: Status updated to \(status.rawValue) and saved successfully")
        } catch {
            print("❌ BookStatusSelector: Failed to update status: \(error)")
        }
    }
}

#Preview {
    // This preview now uses the correct BookMetadata initializer.
    let metadata = BookMetadata(
        googleBooksID: "preview",
        title: "Sample Book",
        authors: ["Sample Author"]
    )
    
    let book = UserBook(metadata: metadata)
    
    return EnhancedEditBookView(book: book)
        .modelContainer(for: [UserBook.self, BookMetadata.self], inMemory: true)
}