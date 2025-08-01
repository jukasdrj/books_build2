import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allBooks: [UserBook]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.lg) {
                    // Quick Stats Grid
                    StatsQuickGrid(books: allBooks)
                    
                    // NEW: Charts Section
                    if !allBooks.isEmpty {
                        MonthlyReadsChartView(books: allBooks)
                        
                        GenreBreakdownChartView(books: allBooks)
                    }
                    
                    // Enhanced stats sections
                    ReadingStatusBreakdown(books: allBooks)
                    
                    // Recent Activity
                    if !recentBooks.isEmpty {
                        RecentBooksSection(books: recentBooks)
                    }
                }
                .padding()
            }
            .navigationTitle("Reading Stats")
        }
    }
    
    private var recentBooks: [UserBook] {
        allBooks.filter { $0.dateCompleted != nil }
             .sorted { 
                 ($0.dateCompleted ?? Date.distantPast) > ($1.dateCompleted ?? Date.distantPast) 
             }
             .prefix(5)
             .map { $0 }
    }
}

struct StatsQuickGrid: View {
    let books: [UserBook]
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(
                title: "Total Books",
                value: "\(books.count)",
                icon: "books.vertical",
                color: Theme.Color.PrimaryAction
            )
            
            StatCard(
                title: "Books Read",
                value: "\(booksRead)",
                icon: "checkmark.circle",
                color: Theme.Color.PrimaryAction.opacity(0.8)
            )
            
            StatCard(
                title: "Currently Reading",
                value: "\(currentlyReading)",
                icon: "book",
                color: Theme.Color.PrimaryAction.opacity(0.6)
            )
            
            StatCard(
                title: "Want to Read",
                value: "\(wantToRead)",
                icon: "heart",
                color: Theme.Color.PrimaryAction.opacity(0.4)
            )
        }
    }
    
    private var booksRead: Int {
        books.filter { $0.readingStatus == .read }.count
    }
    
    private var currentlyReading: Int {
        books.filter { $0.readingStatus == .reading }.count
    }
    
    private var wantToRead: Int {
        books.filter { $0.readingStatus == .toRead }.count
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .headlineSmall()
                .fontWeight(.bold)
                .foregroundColor(Theme.Color.PrimaryText)
            
            Text(title)
                .labelMedium()
                .multilineTextAlignment(.center)
                .foregroundColor(Theme.Color.SecondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ReadingStatusBreakdown: View {
    let books: [UserBook]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reading Status")
                .titleLarge()
                .foregroundColor(Theme.Color.PrimaryText)
            
            VStack(spacing: 8) {
                StatusRow(status: .read, count: booksRead, total: books.count)
                StatusRow(status: .reading, count: currentlyReading, total: books.count)
                StatusRow(status: .toRead, count: wantToRead, total: books.count)
            }
        }
        .padding()
        .background(Theme.Color.CardBackground)
        .cornerRadius(12)
    }
    
    private var booksRead: Int {
        books.filter { $0.readingStatus == .read }.count
    }
    
    private var currentlyReading: Int {
        books.filter { $0.readingStatus == .reading }.count
    }
    
    private var wantToRead: Int {
        books.filter { $0.readingStatus == .toRead }.count
    }
}

struct StatusRow: View {
    let status: ReadingStatus
    let count: Int
    let total: Int
    
    var body: some View {
        HStack {
            Text(status.rawValue)
                .bodyLarge()
                .foregroundColor(Theme.Color.PrimaryText)
            
            Spacer()
            
            Text("\(count)")
                .bodyLarge()
                .fontWeight(.medium)
                .foregroundColor(Theme.Color.PrimaryText)
            
            if total > 0 {
                Text("(\(Int(Double(count) / Double(total) * 100))%)")
                    .labelMedium()
                    .foregroundColor(Theme.Color.SecondaryText)
            }
        }
    }
}

struct RecentBooksSection: View {
    let books: [UserBook]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recently Completed")
                .titleLarge()
                .foregroundColor(Theme.Color.PrimaryText)
            
            ForEach(books, id: \.self) { book in
                HStack(spacing: 12) {
                    BookCoverImage(
                        imageURL: book.metadata?.imageURL?.absoluteString,
                        width: 40,
                        height: 60
                    )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(book.metadata?.title ?? "Unknown Title")
                            .bodyMedium()
                            .fontWeight(.medium)
                            .foregroundColor(Theme.Color.PrimaryText)
                            .lineLimit(1)
                        
                        Text(book.metadata?.authors.joined(separator: ", ") ?? "Unknown Author")
                            .labelMedium()
                            .foregroundColor(Theme.Color.SecondaryText)
                            .lineLimit(1)
                        
                        if let dateCompleted = book.dateCompleted {
                            Text("Completed \(dateCompleted.formatted(date: .abbreviated, time: .omitted))")
                                .labelSmall()
                                .foregroundColor(Theme.Color.SecondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    if let rating = book.rating, rating > 0 {
                        HStack(spacing: 2) {
                            ForEach(1...rating, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundColor(Theme.Color.AccentHighlight)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Theme.Color.CardBackground)
        .cornerRadius(12)
    }
}

#Preview {
    StatsView()
        .modelContainer(for: UserBook.self, inMemory: true)
}