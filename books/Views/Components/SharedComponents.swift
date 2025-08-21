import SwiftUI
import SwiftData

// MARK: - Book List Item (used in multiple views)
struct BookListItem: View {
    @Environment(\.appTheme) private var currentTheme
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
                            .foregroundColor(currentTheme.primaryAction)
                            .underline(true)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(book.metadata?.authors.joined(separator: ", ") ?? "Unknown Author")
                        .authorName() // Use .authorName() even for plain display
                        .foregroundColor(currentTheme.secondaryText)
                }
                
                HStack(spacing: Theme.Spacing.sm) {
                    StatusBadge(status: book.readingStatus, style: .full)
                    
                    Spacer()
                    
                    if let rating = book.rating, rating > 0 {
                        HStack(spacing: Theme.Spacing.xs) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rating ? "star.fill" : "star")
                                    .labelSmall()
                                    .foregroundColor(star <= rating ? currentTheme.accentHighlight : currentTheme.secondaryText.opacity(0.3))
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
        .materialInteractive()
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
    @Environment(\.appTheme) private var currentTheme
    
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
            .background(currentTheme.surface)
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
                    .foregroundColor(isFormValid ? currentTheme.primaryAction : currentTheme.disabledText)
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
                
            }
        } header: {
            Text("Cultural & Language Details")
                .titleSmall()
        } footer: {
            Text("Help track the cultural diversity of your reading by adding author nationality and original language information.")
                .labelSmall()
                .foregroundColor(currentTheme.secondaryText)
        }
    }
    
    @ViewBuilder
    private var readingStatusSection: some View {
        Section {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Image(systemName: "book.closed")
                        .foregroundColor(currentTheme.primaryAction)
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
                        .foregroundColor(currentTheme.primaryAction)
                        .frame(width: 20)
                    Text("Rating")
                        .labelLarge()
                }
                
                HStack(spacing: Theme.Spacing.xs) {
                    HStack(spacing: Theme.Spacing.xs) {
                        ForEach(1...5, id: \.self) { star in
                            Button(action: { 
                                personalRating = personalRating == star ? 0 : star 
                            }) {
                                Image(systemName: star <= personalRating ? "star.fill" : "star")
                                    .foregroundColor(star <= personalRating ? currentTheme.accentHighlight : currentTheme.secondaryText)
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
                        .foregroundColor(currentTheme.secondaryText)
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
                        .foregroundColor(currentTheme.primaryAction)
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
                .foregroundColor(currentTheme.secondaryText)
        }
    }
    
    private func saveBook() {
        guard isFormValid else { return }
        
        // Parse authors from comma-separated string
        let authorsList = authors.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        guard !authorsList.isEmpty else { return }
        
        // Safe page count parsing
        let safePageCount: Int? = {
            let trimmed = pageCount.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : Int(trimmed)
        }()
        
        // Create BookMetadata with all fields including the new ones
        let metadata = BookMetadata(
            googleBooksID: UUID().uuidString, // Generate unique ID for manually added books
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            authors: authorsList,
            publishedDate: publishedDate.isEmpty ? nil : publishedDate,
            pageCount: safePageCount,
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
// print("Error saving book: \(error)")
        }
    }
}

// MARK: - Form Field Component
struct FormField: View {
    @Environment(\.appTheme) private var currentTheme
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
                    .foregroundColor(currentTheme.primaryAction)
                    .frame(width: 20)
                
                Text(label)
                    .labelLarge()
                    .foregroundColor(currentTheme.primaryText)
                
                if isRequired {
                    Text("*")
                        .labelLarge()
                        .foregroundColor(currentTheme.error)
                }
            }
            
            TextField(placeholder, text: $text)
                .bodyMedium()
                .keyboardType(keyboardType)
                .padding(.leading, 24) // Align with label text
        }
    }
}

// MARK: - Consolidated StatCard Component
/// Unified StatCard component that combines the liquid glass styling from LiquidGlassStatsView
/// with the flexibility needed for BackgroundImportProgressIndicator
struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    let subtitle: String?
    let material: LiquidGlassTheme.GlassMaterial?
    
    @Environment(\.appTheme) private var theme
    @State private var isAnimated = false
    
    // Primary initializer for liquid glass style (used in LiquidGlassStatsView)
    init(
        icon: String,
        title: String,
        value: String,
        subtitle: String,
        color: Color,
        material: LiquidGlassTheme.GlassMaterial
    ) {
        self.icon = icon
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.color = color
        self.material = material
    }
    
    // Simple initializer for basic style (used in BackgroundImportProgressIndicator)
    init(
        icon: String,
        title: String,
        value: String,
        color: Color
    ) {
        self.icon = icon
        self.title = title
        self.value = value
        self.subtitle = nil
        self.color = color
        self.material = nil
    }
    
    var body: some View {
        if let material = material, let subtitle = subtitle {
            // Liquid glass enhanced style
            liquidGlassStyle(subtitle: subtitle, material: material)
        } else {
            // Simple style
            simpleStyle
        }
    }
    
    @ViewBuilder
    private func liquidGlassStyle(subtitle: String, material: LiquidGlassTheme.GlassMaterial) -> some View {
        VStack(spacing: 12) {
            // Icon with enhanced styling
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(.ultraThinMaterial.opacity(0.5))
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .liquidGlassVibrancy(.prominent)
            }
            .scaleEffect(isAnimated ? 1.0 : 0.8)
            .animation(
                LiquidGlassTheme.FluidAnimation.smooth.springAnimation.delay(0.3),
                value: isAnimated
            )
            
            VStack(spacing: 4) {
                // Value with counting animation
                Text(value)
                    .font(LiquidGlassTheme.typography.displaySmall)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryText)
                    .liquidGlassVibrancy(.maximum)
                    .contentTransition(.numericText())
                
                Text(title)
                    .font(LiquidGlassTheme.typography.titleSmall)
                    .foregroundColor(color)
                    .liquidGlassVibrancy(.prominent)
                
                Text(subtitle)
                    .font(LiquidGlassTheme.typography.bodySmall)
                    .foregroundColor(theme.secondaryText)
                    .liquidGlassVibrancy(.medium)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .background(material.fallbackMaterial.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(
            color: color.opacity(0.2),
            radius: 8,
            x: 0,
            y: 4
        )
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                isAnimated = true
            }
        }
    }
    
    @ViewBuilder
    private var simpleStyle: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .titleMedium()
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .labelSmall()
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Consolidated CulturalGoalsView Component
/// Unified CulturalGoalsView that combines both implementations
struct CulturalGoalsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Header content
                    VStack(spacing: Theme.Spacing.md) {
                        Text("Cultural Reading Goals")
                            .font(LiquidGlassTheme.typography.headlineLarge)
                            .foregroundColor(theme.primaryText)
                            .liquidGlassVibrancy(.maximum)
                        
                        Text("Set your cultural reading goals for this year")
                            .bodyLarge()
                            .foregroundColor(theme.secondaryText)
                            .liquidGlassVibrancy(.medium)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Theme.Spacing.md)
                    }
                    
                    // Placeholder content
                    Text("Cultural Goals Setup Coming Soon")
                        .titleMedium()
                        .foregroundColor(theme.secondaryText)
                        .padding(Theme.Spacing.xl)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Cultural Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Consolidated FlowLayout Component
/// Unified FlowLayout implementation that combines both versions
struct FlowLayout: Layout {
    let spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        
        for (index, subview) in subviews.enumerated() {
            subview.place(at: result.positions[index], proposal: ProposedViewSize(result.sizes[index]))
        }
    }
}

/// FlowResult helper for FlowLayout calculations
struct FlowResult {
    let size: CGSize
    let positions: [CGPoint]
    let sizes: [CGSize]
    
    init(in maxWidth: CGFloat, subviews: LayoutSubviews, spacing: CGFloat) {
        var sizes: [CGSize] = []
        var positions: [CGPoint] = []
        
        var currentRowY: CGFloat = 0
        var currentRowX: CGFloat = 0
        var currentRowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentRowX + size.width > maxWidth && currentRowX > 0 {
                // Start new row
                currentRowY += currentRowHeight + spacing
                currentRowX = 0
                currentRowHeight = 0
            }
            
            positions.append(CGPoint(x: currentRowX, y: currentRowY))
            sizes.append(size)
            
            currentRowX += size.width + spacing
            currentRowHeight = max(currentRowHeight, size.height)
        }
        
        self.positions = positions
        self.sizes = sizes
        self.size = CGSize(
            width: maxWidth,
            height: currentRowY + currentRowHeight
        )
    }
}

#Preview {
    AddBookView()
        .modelContainer(for: [UserBook.self, BookMetadata.self], inMemory: true)
        .preferredColorScheme(.dark)
}