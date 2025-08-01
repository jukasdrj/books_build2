import SwiftUI
import SwiftData

// MARK: - Status Badge
struct StatusBadge: View {
    let status: ReadingStatus
    
    var body: some View {
        Text(status.rawValue)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.2))
            .foregroundColor(status.color)
            .cornerRadius(8)
    }
}

// MARK: - Date Picker Types
extension UserBook {
    enum DatePickerType: String, CaseIterable {
        case started = "Date Started"
        case completed = "Date Completed"
        case added = "Date Added"
        
        var title: String {
            return self.rawValue
        }
        
        var systemImage: String {
            switch self {
            case .started:
                return "play.circle"
            case .completed:
                return "checkmark.circle"
            case .added:
                return "plus.circle"
            }
        }
    }
}

// MARK: - Date Picker Sheet
struct DatePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var book: UserBook
    let dateType: UserBook.DatePickerType
    
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 16) {
                    Image(systemName: dateType.systemImage)
                        .font(.largeTitle)
                        .foregroundStyle(.blue)
                    
                    Text("Set \(dateType.title)")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.wheel)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button("Save") {
                        saveDate()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding()
            .navigationTitle(dateType.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        saveDate()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            selectedDate = currentDate
        }
    }
    
    private var currentDate: Date {
        switch dateType {
        case .started:
            return book.dateStarted ?? book.dateAdded
        case .completed:
            return book.dateCompleted ?? Date()
        case .added:
            return book.dateAdded
        }
    }
    
    private func saveDate() {
        switch dateType {
        case .started:
            book.dateStarted = selectedDate
            // Status change will trigger auto-date logic
            if book.readingStatus == .toRead {
                book.readingStatus = .reading
            }
        case .completed:
            book.dateCompleted = selectedDate
            // Status change will trigger auto-date logic
            book.readingStatus = .read
        case .added:
            book.dateAdded = selectedDate
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save date: \(error)")
        }
    }
}

// MARK: - Progress Update View
struct ProgressUpdateView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var book: UserBook
    
    @State private var currentPage: Int = 0
    @State private var totalPages: Int = 0
    @State private var showingPageValidation = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "book.pages")
                        .font(.largeTitle)
                        .foregroundStyle(.blue)
                    
                    Text("Update Reading Progress")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let title = book.metadata?.title {
                        Text(title)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                }
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total Pages")
                            .font(.headline)
                        
                        TextField("Enter total pages", value: $totalPages, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Page")
                            .font(.headline)
                        
                        HStack {
                            TextField("Page number", value: $currentPage, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .keyboardType(.numberPad)
                            
                            Text("of \(totalPages)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if totalPages > 0 && currentPage >= 0 {
                        VStack(spacing: 12) {
                            ProgressView(value: min(Double(currentPage) / Double(totalPages), 1.0))
                                .progressViewStyle(.linear)
                                .scaleEffect(y: 3)
                                .animation(.easeInOut(duration: 0.3), value: currentPage)
                            
                            HStack {
                                Text("\(min(Int(Double(currentPage) / Double(totalPages) * 100), 100))% complete")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                if currentPage >= totalPages && totalPages > 0 {
                                    Text("🎉 Finished!")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                
                Spacer()
                
                HStack(spacing: 16) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button("Save Progress") {
                        saveProgress()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!isValidProgress)
                }
            }
            .padding()
            .navigationTitle("Reading Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveProgress()
                    }
                    .disabled(!isValidProgress)
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            setupInitialValues()
        }
        .alert("Invalid Progress", isPresented: $showingPageValidation) {
            Button("OK") { }
        } message: {
            Text("Current page cannot be greater than total pages.")
        }
    }
    
    private var isValidProgress: Bool {
        return totalPages > 0 && currentPage >= 0 && currentPage <= totalPages
    }
    
    private func setupInitialValues() {
        totalPages = book.metadata?.pageCount ?? 0
        switch book.readingStatus {
        case .toRead:
            currentPage = 0
        case .reading:
            currentPage = totalPages / 3
        case .read:
            currentPage = totalPages
        }
    }
    
    private func saveProgress() {
        guard isValidProgress else {
            showingPageValidation = true
            return
        }
        
        if let metadata = book.metadata {
            metadata.pageCount = totalPages
        }
        
        // Let the model handle the auto-date logic by setting status
        if currentPage == 0 {
            book.readingStatus = .toRead
            // Reset dates manually only for .toRead since it doesn't trigger auto-dates
            book.dateStarted = nil
            book.dateCompleted = nil
        } else if currentPage >= totalPages && totalPages > 0 {
            book.readingStatus = .read // Auto-date logic will handle dates
        } else {
            book.readingStatus = .reading // Auto-date logic will handle dates
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save progress: \(error)")
        }
    }
}

// MARK: - Enhanced Edit Book View - UPDATED with Stylized Field Labels
struct EnhancedEditBookView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
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
                        .foregroundColor(Theme.Color.PrimaryText)
                }
                
                // Format & Publication Section
                Section {
                    // Book Format Picker
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        HStack(spacing: Theme.Spacing.xs) {
                            Image(systemName: "doc.richtext")
                                .font(.system(size: 16))
                                .foregroundColor(Theme.Color.PrimaryAction)
                            Text("Format")
                                .labelLarge()
                                .foregroundColor(Theme.Color.PrimaryText)
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
                        .foregroundColor(Theme.Color.PrimaryText)
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
                        .foregroundColor(Theme.Color.PrimaryText)
                } footer: {
                    Text("Help track the cultural diversity of your reading by adding author nationality and original language information.")
                        .labelSmall()
                        .foregroundColor(Theme.Color.SecondaryText)
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
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                                ForEach(categories, id: \.self) { category in
                                    HStack(spacing: 4) {
                                        Text(category)
                                            .labelSmall()
                                        
                                        Button(action: {
                                            categories.removeAll { $0 == category }
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.caption)
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Theme.Color.PrimaryAction.opacity(0.1))
                                    .foregroundColor(Theme.Color.PrimaryAction)
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Categories")
                        .titleSmall()
                        .foregroundColor(Theme.Color.PrimaryText)
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
                        .foregroundColor(Theme.Color.PrimaryText)
                }
                
                // Personal Notes Section
                Section {
                    StyledTextEditor(
                        label: "Personal Notes",
                        text: $personalNotes,
                        icon: "note.text",
                        placeholder: "Your thoughts, quotes, or reflections about this book"
                    )
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
                        saveChanges()
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .labelLarge()
                    .foregroundColor(Theme.Color.PrimaryAction)
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
                    .foregroundColor(Theme.Color.PrimaryAction)
                    .frame(width: 20)
                
                Text(label)
                    .labelLarge()
                    .foregroundColor(Theme.Color.PrimaryText)
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
    let label: String
    @Binding var text: String
    let icon: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.Color.PrimaryAction)
                    .frame(width: 20)
                
                Text(label)
                    .labelLarge()
                    .foregroundColor(Theme.Color.PrimaryText)
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
                StatusBadge(status: book.readingStatus)
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func updateStatus(to status: ReadingStatus) {
        // Simple status change - let the model handle auto-date logic
        book.readingStatus = status
        
        // Only manually handle .toRead since it clears dates
        if status == .toRead {
            book.dateStarted = nil
            book.dateCompleted = nil
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to update status: \(error)")
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