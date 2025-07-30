import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allBooks: [UserBook]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 24) {
                    // Quick Stats Grid
                    StatsQuickGrid(books: allBooks)
                    
                    // Simple stats sections
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
                color: .blue
            )
            
            StatCard(
                title: "Books Read",
                value: "\(booksRead)",
                icon: "checkmark.circle",
                color: .green
            )
            
            StatCard(
                title: "Currently Reading",
                value: "\(currentlyReading)",
                icon: "book",
                color: .orange
            )
            
            StatCard(
                title: "Want to Read",
                value: "\(wantToRead)",
                icon: "heart",
                color: .red
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
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
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
                .font(.headline)
            
            VStack(spacing: 8) {
                StatusRow(status: .read, count: booksRead, total: books.count)
                StatusRow(status: .reading, count: currentlyReading, total: books.count)
                StatusRow(status: .toRead, count: wantToRead, total: books.count)
            }
        }
        .padding()
        .background(Color(.systemGray6))
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
                .font(.subheadline)
            
            Spacer()
            
            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.medium)
            
            if total > 0 {
                Text("(\(Int(Double(count) / Double(total) * 100))%)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct RecentBooksSection: View {
    let books: [UserBook]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recently Completed")
                .font(.headline)
            
            ForEach(books, id: \.self) { book in
                HStack(spacing: 12) {
                    BookCoverImage(
                        imageURL: book.metadata?.imageURL?.absoluteString,
                        width: 40,
                        height: 60
                    )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(book.metadata?.title ?? "Unknown Title")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        
                        Text(book.metadata?.authors.joined(separator: ", ") ?? "Unknown Author")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        if let dateCompleted = book.dateCompleted {
                            Text("Completed \(dateCompleted.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    if let rating = book.rating, rating > 0 {
                        HStack(spacing: 2) {
                            ForEach(1...rating, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    StatsView()
        .modelContainer(for: UserBook.self, inMemory: true)
}