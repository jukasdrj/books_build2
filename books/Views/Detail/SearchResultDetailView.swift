//
//  SearchResultDetailView.swift
//  books
//
//  Created by Justin Gardner on 7/29/25.
//

import SwiftUI
import SwiftData

struct SearchResultDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var currentTheme
    
    let bookMetadata: BookMetadata
    let fromBarcodeScanner: Bool
    let onReturnToBarcode: (() -> Void)?
    
    init(bookMetadata: BookMetadata, fromBarcodeScanner: Bool = false, onReturnToBarcode: (() -> Void)? = nil) {
        self.bookMetadata = bookMetadata
        self.fromBarcodeScanner = fromBarcodeScanner
        self.onReturnToBarcode = onReturnToBarcode
    }
    
    @State private var showingDuplicateAlert = false
    @State private var existingBook: UserBook?
    @State private var showingSuccessToast = false
    @State private var successMessage = ""
    @State private var isAddingToLibrary = false
    @State private var isAddingToWishlist = false
    @State private var showingEditView = false
    @State private var newlyAddedBook: UserBook?

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    // Enhanced Header Section - matching BookDetailsView style
                    SearchBookHeaderSection(bookMetadata: bookMetadata)
                    
                    // Enhanced Action Buttons Section
                    SearchActionButtonsSection(
                        isAddingToLibrary: $isAddingToLibrary,
                        isAddingToWishlist: $isAddingToWishlist,
                        existingBook: existingBook,
                        onAddToLibrary: { addBook(toWishlist: false) },
                        onAddToWishlist: { addBook(toWishlist: true) }
                    )
                    
                    // Description Section - matching BookDetailsView style
                    if let description = bookMetadata.bookDescription, !description.isEmpty {
                        DescriptionSection(description: description)
                    }
                    
                    // Publication Details Section - matching BookDetailsView style
                    SearchPublicationDetailsSection(bookMetadata: bookMetadata)
                }
                .padding()
            }
            .background(currentTheme.background)
            
            // Success Toast Overlay
            if showingSuccessToast {
                VStack {
                    Spacer()
                    SuccessToast(message: successMessage, isShowing: $showingSuccessToast)
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.bottom, 100) 
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .navigationTitle(bookMetadata.title)
        .navigationBarTitleDisplayMode(.inline)
        .background(currentTheme.background)
        .sheet(isPresented: $showingEditView) {
            if let book = newlyAddedBook {
                NavigationStack {
                    EditBookView(userBook: book) { savedBook in
                        // Handle save completion
// print("Book details saved: \(savedBook.metadata?.title ?? "Unknown")")
                        showingEditView = false
                        dismiss() 
                    }
                }
                .withNavigationDestinations()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ShareLink(item: shareableText) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(currentTheme.primaryAction)
                }
            }
        }
        .onAppear(perform: checkForDuplicate)
        .alert("Book Already Exists", isPresented: $showingDuplicateAlert, presenting: existingBook) { book in
            Button("OK", role: .cancel) {}
        } message: { book in
            Text("\"\(book.metadata?.title ?? "This book")\" is already in your library with the status \"\(book.readingStatus.rawValue)\".")
        }
    }
    
    private var shareableText: String {
        var components: [String] = []
        components.append("Check out this book: \(bookMetadata.title)")
        components.append("By \(bookMetadata.authors.joined(separator: ", "))")
        if let publisher = bookMetadata.publisher {
            components.append("Published by \(publisher)")
        }
        return components.joined(separator: ". ")
    }
    
    private func checkForDuplicate() {
        // Fetch userBooks directly from modelContext instead of using @Query
        let fetchDescriptor = FetchDescriptor<UserBook>()
        
        do {
            let userBooks = try modelContext.fetch(fetchDescriptor)
            if let duplicate = DuplicateDetectionService.findExistingBook(for: bookMetadata, in: userBooks) {
                existingBook = duplicate
            }
        } catch {
// print("Error fetching user books for duplicate check: \(error)")
            // If we can't fetch, just continue without duplicate checking
        }
    }
    
    private func addBook(toWishlist: Bool) {
        // If book already exists, don't add it again
        guard existingBook == nil else {
            showingDuplicateAlert = true
            HapticFeedbackManager.shared.warning()
            return
        }
        
        // Set loading state
        if toWishlist {
            isAddingToWishlist = true
        } else {
            isAddingToLibrary = true
        }
        
        // Light haptic feedback for start of action
        HapticFeedbackManager.shared.lightImpact()
        
        // Simulate a brief delay to show loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let newBook = UserBook(
                readingStatus: toWishlist ? .toRead : .reading,
                onWishlist: toWishlist
            )
            newBook.metadata = bookMetadata
            
            modelContext.insert(newBook)
            
            // Store reference for potential navigation
            newlyAddedBook = newBook
            
            // Clear loading states
            isAddingToLibrary = false
            isAddingToWishlist = false
            
            // Success haptic feedback
            if toWishlist {
                HapticFeedbackManager.shared.lightImpact()
                
                if fromBarcodeScanner {
                    successMessage = "📚 Added to your wishlist! Returning to scanner..."
                } else {
                    successMessage = "📚 Added to your wishlist! Returning to search..."
                }
                
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showingSuccessToast = true
                }
                
                // Show toast for 1.5 seconds, then fade out and dismiss
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    // Start fading out the toast
                    withAnimation(.easeOut(duration: 0.3)) {
                        showingSuccessToast = false
                    }
                    
                    // After toast starts fading, wait briefly then handle navigation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        if fromBarcodeScanner && onReturnToBarcode != nil {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                onReturnToBarcode?()
                            }
                        } else {
                            dismiss()
                        }
                    }
                }
            } else {
                HapticFeedbackManager.shared.success()
                successMessage = "✅ Added to your library! Customize your book..."
                
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showingSuccessToast = true
                }
                
                // After brief success feedback, present EditBookView
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showingSuccessToast = false
                    }
                    
                    // Present EditBookView as sheet for immediate customization
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingEditView = true
                    }
                }
            }
        }
    }
}

// MARK: - Enhanced Header Section (matching BookDetailsView)
struct SearchBookHeaderSection: View {
    @Environment(\.appTheme) private var currentTheme
    let bookMetadata: BookMetadata
    
    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.lg) {
            BookCoverImage(
                imageURL: bookMetadata.imageURL?.absoluteString,
                width: 120,
                height: 180
            )
            .shadow(color: .black.opacity(0.2), radius: 8, x: 4, y: 4)
            
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text(bookMetadata.title)
                    .bookTitle()
                    .foregroundColor(currentTheme.primaryText)
                
                // Author names with proper styling
                Text(bookMetadata.authors.joined(separator: ", "))
                    .authorName()
                    .foregroundColor(currentTheme.secondaryText)
                
                // Genre with beautiful styling
                if !bookMetadata.genre.isEmpty {
                    Text(bookMetadata.genre.first!)
                        .culturalTag()
                        .fontWeight(.medium)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(currentTheme.primaryAction.opacity(0.2))
                        .foregroundColor(currentTheme.primaryAction)
                        .cornerRadius(Theme.CornerRadius.small)
                }
                
                // Book preview badge
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "magnifyingglass")
                        .font(.caption)
                        .foregroundColor(currentTheme.tertiary)
                    Text("Search Result")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(currentTheme.tertiary)
                }
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xs)
                .background(currentTheme.tertiaryContainer)
                .cornerRadius(Theme.CornerRadius.small)
                
                Spacer()
            }
            .frame(minHeight: 180)
        }
    }
}

// MARK: - Enhanced Action Buttons Section
struct SearchActionButtonsSection: View {
    @Environment(\.appTheme) private var currentTheme
    @Binding var isAddingToLibrary: Bool
    @Binding var isAddingToWishlist: Bool
    let existingBook: UserBook?
    let onAddToLibrary: () -> Void
    let onAddToWishlist: () -> Void
    
    var body: some View {
        GroupBox {
            VStack(spacing: Theme.Spacing.md) {
                // Status indicator for existing books
                if let existing = existingBook {
                    HStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(currentTheme.success)
                        Text("Already in your \(existing.onWishlist ? "wishlist" : "library")")
                            .bodyMedium()
                            .foregroundColor(currentTheme.secondaryText)
                        Spacer()
                        
                        Text(existing.readingStatus.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, Theme.Spacing.sm)
                            .padding(.vertical, Theme.Spacing.xs)
                            .background(existing.readingStatus.containerColor(theme: currentTheme))
                            .foregroundColor(existing.readingStatus.textColor(theme: currentTheme))
                            .cornerRadius(Theme.CornerRadius.small)
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(currentTheme.success.opacity(0.1))
                    .cornerRadius(Theme.CornerRadius.medium)
                } else {
                    // Action buttons for new books
                    VStack(spacing: Theme.Spacing.sm) {
                        Button(action: onAddToLibrary) {
                            HStack(spacing: Theme.Spacing.sm) {
                                if isAddingToLibrary {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "books.vertical.fill")
                                }
                                Text("Add to Library")
                                    .labelLarge()
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .materialButton(style: .filled, size: .large)
                        .disabled(isAddingToLibrary || isAddingToWishlist)
                        .shadow(color: currentTheme.primary.opacity(0.3), radius: 4, x: 0, y: 2)
                        .animation(.easeInOut(duration: 0.2), value: isAddingToLibrary)
                        
                        Button(action: onAddToWishlist) {
                            HStack(spacing: Theme.Spacing.sm) {
                                if isAddingToWishlist {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(currentTheme.primaryAction)
                                } else {
                                    Image(systemName: "wand.and.stars")
                                }
                                Text("Add to Wishlist")
                                    .labelLarge()
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .materialButton(style: .tonal, size: .large)
                        .disabled(isAddingToLibrary || isAddingToWishlist)
                        .animation(.easeInOut(duration: 0.2), value: isAddingToWishlist)
                    }
                    
                    // Helper text
                    HStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundColor(currentTheme.secondaryText)
                        Text("Library books can be customized and tracked. Wishlist items are saved for later.")
                            .font(.caption)
                            .foregroundColor(currentTheme.secondaryText)
                    }
                    .padding(.top, Theme.Spacing.xs)
                }
            }
        } label: {
            Text("Add to Collection")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(currentTheme.secondaryText)
        }
    }
}

// MARK: - Enhanced Publication Details Section (matching BookDetailsView)
struct SearchPublicationDetailsSection: View {
    @Environment(\.appTheme) private var currentTheme
    let bookMetadata: BookMetadata
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 0) {
                if let publisher = bookMetadata.publisher, !publisher.isEmpty {
                    DetailRowView(
                        label: "Publisher",
                        value: publisher
                    )
                }
                
                if let publishedDate = bookMetadata.publishedDate, !publishedDate.isEmpty {
                    DetailRowView(
                        label: "Published",
                        value: publishedDate
                    )
                }
                
                if let pageCount = bookMetadata.pageCount, pageCount > 0 {
                    DetailRowView(
                        label: "Pages",
                        value: "\(pageCount)"
                    )
                }
                
                if let language = bookMetadata.language, !language.isEmpty {
                    DetailRowView(
                        label: "Language",
                        value: language
                    )
                }
                
                if let isbn = bookMetadata.isbn, !isbn.isEmpty {
                    DetailRowView(
                        label: "ISBN",
                        value: isbn
                    )
                }
                
                // Google Books ID (for reference)
                DetailRowView(
                    label: "Source",
                    value: "Google Books",
                    isPlaceholder: false
                )
            }
        } label: {
            Text("Publication Details")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(currentTheme.secondaryText)
        }
    }
}

// MARK: - Enhanced Success Toast Component
struct SuccessToast: View {
    @Environment(\.appTheme) private var currentTheme
    let message: String
    @Binding var isShowing: Bool
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(currentTheme.success)
                    .frame(width: 32, height: 32)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text(message)
                .bodyMedium()
                .fontWeight(.medium)
                .foregroundColor(currentTheme.primaryText)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .background(
            LinearGradient(
                colors: [currentTheme.cardBackground, currentTheme.surface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .stroke(
                    LinearGradient(
                        colors: [currentTheme.success.opacity(0.4), currentTheme.success.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .cornerRadius(Theme.CornerRadius.medium)
        .shadow(color: currentTheme.success.opacity(0.2), radius: 15, x: 0, y: 8)
        .scaleEffect(scale)
        .opacity(opacity)
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(UIAccessibility.isReduceMotionEnabled ? 
                         Animation.linear(duration: 0.1) : 
                         Animation.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
        .onChange(of: isShowing) { _, newValue in
            if !newValue {
                withAnimation(UIAccessibility.isReduceMotionEnabled ? 
                             Animation.linear(duration: 0.1) : 
                             Animation.easeOut(duration: 0.3)) {
                    scale = 0.8
                    opacity = 0
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }
}

#Preview {
    let sampleMetadata = BookMetadata(
        googleBooksID: "sample-id",
        title: "Sample Book",
        authors: ["Sample Author"],
        publishedDate: "2023",
        pageCount: 300,
        bookDescription: "This is a sample book description for preview purposes.",
        publisher: "Sample Publisher",
        isbn: "1234567890",
        genre: ["Fiction"]
    )
    
    return NavigationStack {
        SearchResultDetailView(bookMetadata: sampleMetadata, fromBarcodeScanner: false, onReturnToBarcode: nil)
            .modelContainer(for: [UserBook.self, BookMetadata.self], inMemory: true)
    }
}