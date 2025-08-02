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
    
    @Query private var userBooks: [UserBook]
    
    @State private var showingDuplicateAlert = false
    @State private var existingBook: UserBook?
    @State private var showingSuccessToast = false
    @State private var successMessage = ""
    @State private var isAddingToLibrary = false
    @State private var isAddingToWishlist = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with cover, title, author
                    HStack(alignment: .top, spacing: 20) {
                        BookCoverImage(
                            imageURL: bookMetadata.imageURL?.absoluteString,
                            width: 120,
                            height: 180
                        )
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text(bookMetadata.title)
                                .font(.title2.bold())
                            
                            Text(bookMetadata.authors.joined(separator: ", "))
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            // Fixed: genre is no longer optional
                            if !bookMetadata.genre.isEmpty {
                                Text(bookMetadata.genre.first!)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(SwiftUI.Color.purple.opacity(0.2))
                                    .foregroundColor(.purple)
                                    .cornerRadius(8)
                            }
                            Spacer()
                        }
                        .frame(minHeight: 180)
                    }
                    
                    // Enhanced Action Buttons with Loading States
                    VStack(spacing: 12) {
                        Button(action: {
                            addBook(toWishlist: false)
                        }) {
                            HStack(spacing: 8) {
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
                        .buttonStyle(.borderedProminent)
                        .disabled(isAddingToLibrary || isAddingToWishlist || existingBook != nil)
                        .animation(.easeInOut(duration: 0.2), value: isAddingToLibrary)
                        
                        Button(action: {
                            addBook(toWishlist: true)
                        }) {
                            HStack(spacing: 8) {
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
                        .buttonStyle(.bordered)
                        .disabled(isAddingToLibrary || isAddingToWishlist || existingBook != nil)
                        .animation(.easeInOut(duration: 0.2), value: isAddingToWishlist)
                        
                        // Status indicator for existing books
                        if let existing = existingBook {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color.theme.success)
                                Text("Already in your \(existing.onWishlist ? "wishlist" : "library")")
                                    .font(.subheadline)
                                    .foregroundColor(Color.theme.secondaryText)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.theme.success.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    
                    // Description
                    if let description = bookMetadata.bookDescription, !description.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.headline)
                            Text(description)
                                .font(.body)
                        }
                    }
                    
                    // Other Details
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Details")
                            .font(.headline)
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
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .navigationTitle("Book Details")
        .navigationBarTitleDisplayMode(.inline)
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
        if let duplicate = DuplicateDetectionService.findExistingBook(for: bookMetadata, in: userBooks) {
            existingBook = duplicate
        }
    }
    
    private func addBook(toWishlist: Bool) {
        // If book already exists, don't add it again
        guard existingBook == nil else {
            showingDuplicateAlert = true
            return
        }
        
        // Set loading state
        if toWishlist {
            isAddingToWishlist = true
        } else {
            isAddingToLibrary = true
        }
        
        // Light haptic feedback for start of action
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Simulate a brief delay to show loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let newBook = UserBook(
                readingStatus: toWishlist ? .toRead : .reading,
                onWishlist: toWishlist
            )
            newBook.metadata = bookMetadata
            
            modelContext.insert(newBook)
            
            // Clear loading states
            isAddingToLibrary = false
            isAddingToWishlist = false
            
            // Success haptic feedback
            let successFeedback = UINotificationFeedbackGenerator()
            successFeedback.notificationOccurred(.success)
            
            // Show success message
            successMessage = toWishlist ? 
                "📚 Added to your wishlist!" : 
                "✅ Added to your library!"
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showingSuccessToast = true
            }
            
            // Auto-hide toast after delay (but don't auto-dismiss the view)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showingSuccessToast = false
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
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(Color.theme.success)
            
            Text(message)
                .font(.headline)
                .foregroundColor(Color.theme.primaryText)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.theme.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.theme.success.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 5)
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
        .onChange(of: isShowing) { _, newValue in
            if !newValue {
                withAnimation(.easeOut(duration: 0.3)) {
                    scale = 0.8
                    opacity = 0
                }
            }
        }
    }
}

// MARK: - DetailRow Component
struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(Color.theme.secondaryText)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(Color.theme.primaryText)
            
            Spacer()
        }
        .padding(.vertical, 2)
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