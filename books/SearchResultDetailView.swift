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

    var body: some View {
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
                                .background(Color.purple.opacity(0.2))
                                .foregroundColor(.purple)
                                .cornerRadius(8)
                        }
                        Spacer()
                    }
                    .frame(minHeight: 180)
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        addBook(toWishlist: false)
                    }) {
                        Label("Add to Library", systemImage: "books.vertical.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Button(action: {
                        addBook(toWishlist: true)
                    }) {
                        Label("Add to Wishlist", systemImage: "wand.and.stars")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
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
        .navigationTitle("Book Details")
        .navigationBarTitleDisplayMode(.inline)
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
            showingDuplicateAlert = true
        }
    }
    
    private func addBook(toWishlist: Bool) {
        // If book already exists, don't add it again
        guard existingBook == nil else {
            showingDuplicateAlert = true
            return
        }
        
        let newBook = UserBook(
            readingStatus: toWishlist ? .toRead : .reading, // Default to 'Reading' if not for wishlist
            onWishlist: toWishlist
        )
        newBook.metadata = bookMetadata
        
        modelContext.insert(newBook)
        
        // Use a light haptic feedback on success
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.impactOccurred()
        
        // Dismiss this view to return to the search results
        dismiss()
    }
}