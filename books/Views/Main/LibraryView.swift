//
//  LibraryView.swift
//  books
//
//  Enhanced with reading status filters and optimized navigation
//

import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserBook.dateAdded, order: .reverse) private var books: [UserBook]
    @State private var searchText: String = ""
    @State private var selectedLayout: LayoutType = .grid
    @State private var selectedFilter: FilterType = .all
    
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
    
    enum FilterType: String, CaseIterable {
        case all = "All"
        case tbr = "TBR"
        case reading = "Reading"
        case read = "Read"
        case onHold = "On Hold"
        case dnf = "DNF"
        case favorites = "Favorites"
        
        var icon: String {
            switch self {
            case .all: return "books.vertical"
            case .tbr: return "bookmark"
            case .reading: return "book.pages"
            case .read: return "checkmark.circle"
            case .onHold: return "pause.circle"
            case .dnf: return "xmark.circle"
            case .favorites: return "heart"
            }
        }
        
        var readingStatus: ReadingStatus? {
            switch self {
            case .all, .favorites: return nil
            case .tbr: return .toRead
            case .reading: return .reading
            case .read: return .read
            case .onHold: return .onHold
            case .dnf: return .dnf
            }
        }
    }
    
    private var filteredBooks: [UserBook] {
        let searchFiltered = searchText.isEmpty ? books : books.filter { book in
            let title = book.metadata?.title ?? ""
            let authors = book.metadata?.authors.joined(separator: " ") ?? ""
            return title.localizedCaseInsensitiveContains(searchText) ||
                   authors.localizedCaseInsensitiveContains(searchText)
        }
        
        switch selectedFilter {
        case .all:
            return searchFiltered
        case .favorites:
            return searchFiltered.filter { $0.isFavorited }
        case .tbr, .reading, .read, .onHold, .dnf:
            guard let status = selectedFilter.readingStatus else { return searchFiltered }
            return searchFiltered.filter { $0.readingStatus == status }
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
                
                // Layout toggle
                HStack {
                    Spacer()
                    
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
            }
            .padding(.vertical, Theme.Spacing.sm)
            .background(Color.theme.surface)
            
            Divider()
            
            // Books content
            if filteredBooks.isEmpty {
                EmptyLibraryView(
                    searchText: searchText,
                    selectedFilter: selectedFilter
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
        .navigationTitle("Library (\(filteredBooks.count))")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $searchText, prompt: "Search books...")
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
                NavigationLink("Add Your First Book") {
                    SearchView()
                }
                .materialButton(style: .filled, size: .large)
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
        case .favorites: return "No Favorite Books"
        }
    }
    
    private var emptyStateMessage: String {
        if !searchText.isEmpty {
            return "Try adjusting your search terms or check the spelling."
        }
        
        switch selectedFilter {
        case .all: return "Start building your reading library by adding your first book."
        case .tbr: return "Books on your reading list will appear here."
        case .reading: return "Books you're currently reading will appear here."
        case .read: return "Books you've finished will appear here."
        case .onHold: return "Books you've paused will appear here."
        case .dnf: return "Books you didn't finish will appear here."
        case .favorites: return "Books you've marked as favorites will appear here."
        }
    }
}

#Preview {
    NavigationStack {
        LibraryView()
    }
    .modelContainer(for: UserBook.self, inMemory: true)
}