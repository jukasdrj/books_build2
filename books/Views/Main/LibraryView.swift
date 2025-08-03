//
//  LibraryView.swift
//  books
//
//  Enhanced with reading status filters and CSV import access
//

import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var searchText: String = ""
    @State private var selectedLayout: LayoutType = .grid
    @State private var showingAddBookFlow = false
    @State private var showingFilters = false
    @State private var showingSettings = false
    
    let isWishlist: Bool
    
    @Query private var allBooks: [UserBook]
    
    init(isWishlist: Bool = false) {
        self.isWishlist = isWishlist
        let predicate = #Predicate<UserBook> { book in
            isWishlist ? book.onWishlist == true : true
        }
        _allBooks = Query(filter: predicate, sort: \UserBook.dateAdded, order: .reverse)
    }
    
    enum LayoutType: String, CaseIterable {
        case grid = "Grid"
        case list = "List"
        
        var icon: String {
            switch self {
            case .grid: return "square.grid.2x2"
            case .list: return "list.bullet"
            }
        }
    }
    
    private var filteredBooks: [UserBook] {
        let searchFiltered = searchText.isEmpty ? allBooks : allBooks.filter { book in
            let title = book.metadata?.title ?? ""
            let authors = book.metadata?.authors.joined(separator: " ") ?? ""
            return title.localizedCaseInsensitiveContains(searchText) ||
                   authors.localizedCaseInsensitiveContains(searchText)
        }
        
        switch selectedLayout {
        case .grid:
            return searchFiltered
        case .list:
            return searchFiltered
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter and layout controls
            VStack(spacing: Theme.Spacing.sm) {
                // Filter picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.sm) {
                        ForEach(FilterType.allCases, id: \.self) { filter in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedFilter = filter
                                }
                            } label: {
                                HStack(spacing: Theme.Spacing.xs) {
                                    Image(systemName: filter.icon)
                                        .font(.system(size: 14))
                                    Text(filter.rawValue)
                                        .labelMedium()
                                }
                                .padding(.horizontal, Theme.Spacing.md)
                                .padding(.vertical, Theme.Spacing.sm)
                                .background(selectedFilter == filter ? Color.theme.primary : Color.theme.surfaceVariant)
                                .foregroundColor(selectedFilter == filter ? Color.theme.onPrimary : Color.theme.primaryText)
                                .cornerRadius(Theme.CornerRadius.full)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                }
                
                // Layout toggle and Import button
                HStack {
                    // Import button with purple boho styling
                    Button {
                        showingImportView = true
                    } label: {
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "square.and.arrow.down.on.square")
                                .font(.system(size: 16, weight: .medium))
                            Text("Import CSV")
                                .labelLarge()
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.md)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color.theme.secondary,
                                    Color.theme.secondary.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .foregroundColor(Color.theme.onSecondary)
                        .cornerRadius(Theme.CornerRadius.medium)
                        .shadow(
                            color: Color.theme.secondary.opacity(0.3),
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                    }
                    .materialInteractive()
                    .accessibilityLabel("Import books from CSV file")
                    .accessibilityHint("Opens import flow for Goodreads CSV files")
                    
                    Spacer()
                    
                    // Layout toggle
                    Picker("Layout", selection: $selectedLayout) {
                        ForEach(LayoutType.allCases, id: \.self) { layout in
                            Image(systemName: layout.icon)
                                .tag(layout)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(Color.theme.surface)
            }
            
            Divider()
            
            // Main content
            if filteredBooks.isEmpty {
                EmptyLibraryView(
                    searchText: searchText,
                    selectedFilter: selectedFilter,
                    onImport: { showingImportView = true }
                )
            } else {
                ScrollView(.vertical) {
                    Group {
                        if selectedLayout == .grid {
                            UniformGridLayoutView(books: filteredBooks)
                        } else {
                            ListLayoutView(books: filteredBooks)
                        }
                    }
                    .padding(.bottom, Theme.Spacing.xl) // Tab bar padding
                }
            }
        }
        .navigationTitle(isWishlist ? "Wishlist (\(filteredBooks.count))" : "Library (\(filteredBooks.count))")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search by title or author...")
        .sheet(isPresented: $showingAddBookFlow) {
            SearchView(isPresented: $showingAddBookFlow)
        }
        .sheet(isPresented: $showingFilters) {
            // Filter view will go here
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: Theme.Spacing.md) {
                    
                    // Filter button
                    Button {
                        showingFilters.toggle()
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    .disabled(true) // TODO: Implement filters
                    
                    // Settings Button
                    Button {
                        showingSettings.toggle()
                    } label: {
                        Image(systemName: "gearshape")
                    }

                    // Main add button
                    Button {
                        showingAddBookFlow.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

// MARK: - Layout Views

struct UniformGridLayoutView: View {
    let books: [UserBook]
    
    var body: some View {
        let columns = [
            GridItem(.fixed(140), spacing: Theme.Spacing.md),
            GridItem(.fixed(140), spacing: Theme.Spacing.md)
        ]
        
        LazyVGrid(columns: columns, spacing: Theme.Spacing.lg) {
            ForEach(books) { book in
                NavigationLink(value: book) {
                    BookCardView(book: book)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Theme.Spacing.md)
    }
}

struct ListLayoutView: View {
    let books: [UserBook]
    
    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(books) { book in
                NavigationLink(value: book) {
                    BookRowView(userBook: book)
                }
                .buttonStyle(.plain)
                
                if book.id != books.last?.id {
                    Divider()
                        .padding(.leading, 80) // Align with text
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
    }
}

// MARK: - Empty State

struct EmptyLibraryView: View {
    let searchText: String
    let selectedFilter: LibraryView.FilterType
    let onImport: () -> Void
    
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()
            
            Image(systemName: emptyStateIcon)
                .font(.system(size: 64))
                .foregroundColor(Color.theme.primary.opacity(0.6))
            
            VStack(spacing: Theme.Spacing.sm) {
                Text(emptyStateTitle)
                    .titleLarge()
                    .foregroundColor(Color.theme.primaryText)
                    .multilineTextAlignment(.center)
                
                Text(emptyStateMessage)
                    .bodyMedium()
                    .foregroundColor(Color.theme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            if searchText.isEmpty && selectedFilter == .all {
                VStack(spacing: Theme.Spacing.md) {
                    NavigationLink("Add Your First Book") {
                        SearchView()
                    }
                    .materialButton(style: .filled, size: .large)
                    
                    Button("Import from Goodreads") {
                        onImport()
                    }
                    .materialButton(style: .tonal, size: .large)
                    
                    // Enhanced visual separator
                    HStack {
                        Rectangle()
                            .fill(Color.theme.outline.opacity(0.3))
                            .frame(height: 1)
                        
                        Text("or")
                            .labelSmall()
                            .foregroundColor(Color.theme.secondaryText)
                            .padding(.horizontal, Theme.Spacing.md)
                        
                        Rectangle()
                            .fill(Color.theme.outline.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.vertical, Theme.Spacing.sm)
                    
                    // Secondary import option with boho styling
                    Button {
                        onImport()
                    } label: {
                        VStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "doc.text.below.ecg")
                                .font(.system(size: 32))
                                .foregroundColor(Color.theme.tertiary)
                            
                            VStack(spacing: Theme.Spacing.xs) {
                                Text("Import Your Library")
                                    .titleSmall()
                                    .foregroundColor(Color.theme.primaryText)
                                
                                Text("From Goodreads CSV export")
                                    .labelMedium()
                                    .foregroundColor(Color.theme.secondaryText)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(Theme.Spacing.lg)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color.theme.surfaceVariant,
                                    Color.theme.surfaceVariant.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color.theme.tertiary.opacity(0.3),
                                            Color.theme.secondary.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .cornerRadius(Theme.CornerRadius.medium)
                    }
                    .materialInteractive()
                }
                .padding(.top, Theme.Spacing.md)
            }
            
            Spacer()
        }
        .padding(Theme.Spacing.xl)
    }
    
    private var emptyStateIcon: String {
        if !searchText.isEmpty {
            return "magnifyingglass"
        }
        return selectedFilter.icon
    }
    
    private var emptyStateTitle: String {
        if !searchText.isEmpty {
            return "No Results Found"
        }
        
        switch selectedFilter {
        case .all: return "Your Library is Empty"
        case .tbr: return "No Books To Read"
        case .reading: return "Not Currently Reading"
        case .read: return "No Books Completed"
        case .onHold: return "No Books On Hold"
        case .dnf: return "No DNF Books"
        }
    }
    
    private var emptyStateMessage: String {
        if !searchText.isEmpty {
            return "Try adjusting your search terms or check the spelling."
        }
        
        switch selectedFilter {
        case .all: return "Start building your reading library by adding your first book or importing from Goodreads."
        case .tbr: return "Books on your reading list will appear here."
        case .reading: return "Books you're currently reading will appear here."
        case .read: return "Books you've finished will appear here."
        case .onHold: return "Books you've paused will appear here."
        case .dnf: return "Books you didn't finish will appear here."
        }
    }
}

#Preview {
    NavigationStack {
        LibraryView()
    }
    .modelContainer(for: UserBook.self, inMemory: true)
}