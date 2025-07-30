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
        // Corrected from NavigationView
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
            if book.readingStatus == .toRead {
                book.readingStatus = .reading
            }
        case .completed:
            book.dateCompleted = selectedDate
            book.readingStatus = .read
            if book.dateStarted == nil {
                book.dateStarted = selectedDate
            }
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
        // Corrected from NavigationView
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
        
        if currentPage == 0 {
            book.readingStatus = .toRead
            book.dateStarted = nil
            book.dateCompleted = nil
        } else if currentPage >= totalPages && totalPages > 0 {
            book.readingStatus = .read
            if book.dateCompleted == nil {
                book.dateCompleted = Date()
            }
            if book.dateStarted == nil {
                book.dateStarted = book.dateAdded
            }
        } else {
            book.readingStatus = .reading
            if book.dateStarted == nil {
                book.dateStarted = Date()
            }
            book.dateCompleted = nil
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save progress: \(error)")
        }
    }
}

// MARK: - Enhanced Edit Book View
struct EnhancedEditBookView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var book: UserBook
    
    @State private var title: String = ""
    @State private var authors: [String] = []
    @State private var authorText: String = ""
    @State private var publisher: String = ""
    @State private var publishedDate: String = ""
    @State private var pageCount: Int = 0
    @State private var bookDescription: String = ""
    @State private var isbn: String = ""
    @State private var categories: [String] = []
    @State private var newCategory: String = ""
    
    var body: some View {
        // Corrected from NavigationView
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Image(systemName: "square.and.pencil")
                            .font(.largeTitle)
                            .foregroundStyle(.blue)
                        
                        Text("Edit Book Details")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    GroupBox("Basic Information") {
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Title")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                TextField("Book title", text: $title)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Authors")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                TextField("Author names (comma separated)", text: $authorText)
                                    .textFieldStyle(.roundedBorder)
                                    .onChange(of: authorText) { _, newValue in
                                        authors = newValue.split(separator: ",")
                                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                            .filter { !$0.isEmpty }
                                    }
                            }
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Pages")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    TextField("0", value: $pageCount, format: .number)
                                        .textFieldStyle(.roundedBorder)
                                        .keyboardType(.numberPad)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Published")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    TextField("Year", text: $publishedDate)
                                        .textFieldStyle(.roundedBorder)
                                        .keyboardType(.numberPad)
                                }
                            }
                        }
                    }
                    
                    GroupBox("Publication Details") {
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Publisher")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                TextField("Publisher name", text: $publisher)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("ISBN")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                TextField("ISBN number", text: $isbn)
                                    .textFieldStyle(.roundedBorder)
                                    .keyboardType(.numberPad)
                            }
                        }
                    }
                    
                    GroupBox("Categories") {
                        VStack(spacing: 12) {
                            HStack {
                                TextField("Add category", text: $newCategory)
                                    .textFieldStyle(.roundedBorder)
                                    .onSubmit(addCategory)
                                
                                Button("Add", action: addCategory)
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                    .disabled(newCategory.isEmpty)
                            }
                            
                            if !categories.isEmpty {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                                    ForEach(categories, id: \.self) { category in
                                        HStack(spacing: 4) {
                                            Text(category)
                                                .font(.caption)
                                            
                                            Button(action: {
                                                categories.removeAll { $0 == category }
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.caption)
                                            }
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                        }
                    }
                    
                    GroupBox("Description") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Book Description")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField("Enter book description...", text: $bookDescription, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3...6)
                        }
                    }
                    
                    HStack(spacing: 16) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        
                        Button("Save Changes") {
                            saveChanges()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(title.isEmpty || authors.isEmpty)
                    }
                    .padding(.top)
                }
                .padding()
            }
            .navigationTitle("Edit Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(title.isEmpty || authors.isEmpty)
                    .fontWeight(.semibold)
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
            authors = metadata.authors
            authorText = metadata.authors.joined(separator: ", ")
            publisher = metadata.publisher ?? ""
            publishedDate = metadata.publishedDate ?? ""
            pageCount = metadata.pageCount ?? 0
            bookDescription = metadata.bookDescription ?? ""
            isbn = metadata.isbn ?? ""
            categories = metadata.genre ?? [] // Use genre now
        }
    }
    
    private func saveChanges() {
        guard !title.isEmpty, !authors.isEmpty else { return }
        
        if let existingMetadata = book.metadata {
            existingMetadata.title = title
            existingMetadata.authors = authors
            existingMetadata.publisher = publisher.isEmpty ? nil : publisher
            existingMetadata.publishedDate = publishedDate.isEmpty ? nil : publishedDate
            existingMetadata.pageCount = pageCount > 0 ? pageCount : nil
            existingMetadata.bookDescription = bookDescription.isEmpty ? nil : bookDescription
            existingMetadata.isbn = isbn.isEmpty ? nil : isbn
            existingMetadata.genre = categories.isEmpty ? nil : categories // Save to genre
        } else {
            let newMetadata = BookMetadata(
                googleBooksID: UUID().uuidString,
                title: title,
                authors: authors,
                publishedDate: publishedDate.isEmpty ? nil : publishedDate,
                pageCount: pageCount > 0 ? pageCount : nil,
                bookDescription: bookDescription.isEmpty ? nil : bookDescription,
                publisher: publisher.isEmpty ? nil : publisher,
                isbn: isbn.isEmpty ? nil : isbn,
                genre: categories.isEmpty ? nil : categories // Save to genre
            )
            
            book.metadata = newMetadata
            modelContext.insert(newMetadata)
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save book changes: \(error)")
        }
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
        book.readingStatus = status
        
        switch status {
        case .toRead:
            book.dateStarted = nil
            book.dateCompleted = nil
        case .reading:
            if book.dateStarted == nil {
                book.dateStarted = Date()
            }
            book.dateCompleted = nil
        case .read:
            if book.dateStarted == nil {
                book.dateStarted = book.dateAdded
            }
            if book.dateCompleted == nil {
                book.dateCompleted = Date()
            }
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
