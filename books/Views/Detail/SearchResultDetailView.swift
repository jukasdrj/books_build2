//
//  SearchResultDetailView.swift
//  books
//
//  Created by Justin Gardner on 7/29/25.
//

import SwiftUI
import SwiftData

struct SearchResultDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let bookMetadata: BookMetadata
    
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
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    // Header with cover, title, author
                    HStack(alignment: .top, spacing: Theme.Spacing.lg) {
                        BookCoverImage(
                            imageURL: bookMetadata.imageURL?.absoluteString,
                            width: 120,
                            height: 180
                        )
                        
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            Text(bookMetadata.title)
                                .titleLarge()
                            
                            Text(bookMetadata.authors.joined(separator: ", "))
                                .headlineMedium()
                                .foregroundStyle(.secondary)
                            
                            // Fixed: genre is no longer optional
                            if !bookMetadata.genre.isEmpty {
                                Text(bookMetadata.genre.first!)
                                    .labelMedium()
                                    .fontWeight(.medium)
                                    .padding(.horizontal, Theme.Spacing.sm)
                                    .padding(.vertical, Theme.Spacing.xs)
                                    .background(Color.theme.primary.opacity(0.2))
                                    .foregroundColor(Color.theme.primary)
                                    .cornerRadius(8)
                            }
                            Spacer()
                        }
                        .frame(minHeight: 180)
                    }
                    
                    // Enhanced Action Buttons with Loading States
                    VStack(spacing: Theme.Spacing.md) {
                        Button(action: {
                            addBook(toWishlist: false)
                        }) {
                            HStack(spacing: Theme.Spacing.sm) {
                                if isAddingToLibrary {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "books.vertical.fill")
                                }
                                Text("Add to Library")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                        }
                        .materialButton(style: .filled)
                        .disabled(isAddingToLibrary || isAddingToWishlist || existingBook != nil)
                        .animation(.easeInOut(duration: 0.2), value: isAddingToLibrary)
                        
                        Button(action: {
                            addBook(toWishlist: true)
                        }) {
                            HStack(spacing: Theme.Spacing.sm) {
                                if isAddingToWishlist {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .tint(Color.theme.primaryAction)
                                } else {
                                    Image(systemName: "wand.and.stars")
                                }
                                Text("Add to Wishlist")
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                        }
                        .materialButton(style: .outlined)
                        .disabled(isAddingToLibrary || isAddingToWishlist || existingBook != nil)
                        .animation(.easeInOut(duration: 0.2), value: isAddingToWishlist)
                        
                        // Status indicator for existing books
                        if let existing = existingBook {
                            HStack(spacing: Theme.Spacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color.theme.success)
                                Text("Already in your \(existing.onWishlist ? "wishlist" : "library")")
                                    .font(.subheadline)
                                    .foregroundColor(Color.theme.secondaryText)
                            }
                            .padding(.horizontal, Theme.Spacing.md)
                            .padding(.vertical, Theme.Spacing.sm)
                            .background(Color.theme.success.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
                    // Description
                    if let description = bookMetadata.bookDescription, !description.isEmpty {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            Text("Description")
                                .headlineMedium()
                            Text(description)
                                .bodyMedium()
                        }
                    }
                    
                    // Other Details
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Details")
                            .headlineMedium()
                        DetailRow(label: "Published", value: bookMetadata.publishedDate ?? "N/A")
                        DetailRow(label: "Publisher", value: bookMetadata.publisher ?? "N/A")
                        DetailRow(label: "Pages", value: bookMetadata.pageCount != nil ? "\(bookMetadata.pageCount!)" : "N/A")
                        DetailRow(label: "ISBN", value: bookMetadata.isbn ?? "N/A")
                    }
                    .padding(.top)

                    Spacer()
                }
                .padding()
            }
            
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
        .navigationTitle("Book Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingEditView) {
            if let book = newlyAddedBook {
                NavigationStack {
                    EditBookView(userBook: book) { savedBook in
                        // Handle save completion
                        print("Book details saved: \(savedBook.metadata?.title ?? "Unknown")")
                        showingEditView = false
                        dismiss() 
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .opacity(showingSuccessToast ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.3), value: showingSuccessToast)
            }
        }
        .onAppear(perform: checkForDuplicate)
        .alert("Book Already Exists", isPresented: $showingDuplicateAlert, presenting: existingBook) { book in
            Button("OK", role: .cancel) {}
        } message: { book in
            Text("\"\(book.metadata?.title ?? "This book")\" is already in your library with the status \"\(book.readingStatus.rawValue)\".")
        }
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
            print("Error fetching user books for duplicate check: \(error)")
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
        HapticFeedbackManager.shared.lightImpact() // Changed to use shared manager
        
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
                successMessage = "📚 Added to your wishlist!"
                
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showingSuccessToast = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showingSuccessToast = false
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

// MARK: - Success Toast Component
struct SuccessToast: View {
    let message: String
    @Binding var isShowing: Bool
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .titleMedium()
                .foregroundColor(Color.theme.success)
            
            Text(message)
                .headlineMedium()
                .foregroundColor(Color.theme.primaryText)
            
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.md)
        .background(Color.theme.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.theme.success.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
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

// MARK: - DetailRow Component
struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .bodyMedium()
                .foregroundColor(Color.theme.secondaryText)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .bodyMedium()
                .foregroundColor(Color.theme.primaryText)
            
            Spacer()
        }
        .padding(.vertical, Theme.Spacing.xs)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
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
        SearchResultDetailView(bookMetadata: sampleMetadata)
            .modelContainer(for: [UserBook.self, BookMetadata.self], inMemory: true)
    }
}