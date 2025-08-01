import SwiftUI
import Charts

struct GenreBreakdownChartView: View {
    let books: [UserBook]
    
    private var genreCounts: [GenreCount] {
        var genreDict: [String: Int] = [:]
        
        // Count genres from all books (not just completed ones)
        for book in books {
            if let genres = book.metadata?.genre, !genres.isEmpty {
                for genre in genres {
                    let cleanGenre = genre.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !cleanGenre.isEmpty {
                        genreDict[cleanGenre, default: 0] += 1
                    }
                }
            } else {
                // Handle books without genre data
                genreDict["Uncategorized", default: 0] += 1
            }
        }
        
        // Convert to GenreCount array, sorted by count (descending)
        let sortedGenres = genreDict.sorted { $0.value > $1.value }
        
        // Take top 8 genres to avoid overcrowding, group rest as "Other"
        let maxGenres = 8
        var result: [GenreCount] = []
        var otherCount = 0
        
        for (index, (genre, count)) in sortedGenres.enumerated() {
            if index < maxGenres {
                result.append(GenreCount(name: genre, count: count))
            } else {
                otherCount += count
            }
        }
        
        if otherCount > 0 {
            result.append(GenreCount(name: "Other", count: otherCount))
        }
        
        return result
    }
    
    private var totalBooks: Int {
        genreCounts.reduce(0) { $0 + $1.count }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("Genre Breakdown")
                    .titleLarge()
                    .foregroundColor(Theme.Color.PrimaryText)
                
                Spacer()
                
                Text("\(totalBooks) books")
                    .labelMedium()
                    .foregroundColor(Theme.Color.SecondaryText)
            }
            
            if genreCounts.isEmpty {
                // Empty state
                VStack(spacing: Theme.Spacing.sm) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 32))
                        .foregroundColor(Theme.Color.SecondaryText.opacity(0.6))
                    
                    Text("No genre data available")
                        .bodyMedium()
                        .foregroundColor(Theme.Color.SecondaryText)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            } else {
                Chart(genreCounts) { item in
                    SectorMark(
                        angle: .value("Count", item.count),
                        innerRadius: .ratio(0.618), // Golden ratio for aesthetically pleasing donut
                        angularInset: 1.5
                    )
                    .foregroundStyle(by: .value("Genre", item.name))
                    .opacity(0.9)
                }
                .chartBackground { chartProxy in
                    GeometryReader { geometry in
                        let frame = geometry[chartProxy.plotAreaFrame]
                        VStack(spacing: 4) {
                            Text("Total")
                                .labelSmall()
                                .foregroundColor(Theme.Color.SecondaryText)
                            Text("\(totalBooks)")
                                .titleMedium()
                                .foregroundColor(Theme.Color.PrimaryText)
                            Text("books")
                                .labelSmall()
                                .foregroundColor(Theme.Color.SecondaryText)
                        }
                        .position(x: frame.midX, y: frame.midY)
                    }
                }
                .chartLegend(position: .bottom, alignment: .center, spacing: Theme.Spacing.sm) {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: Theme.Spacing.xs) {
                        ForEach(genreCounts) { item in
                            HStack(spacing: Theme.Spacing.xs) {
                                Circle()
                                    .fill(Color.accentColor) // Will use chart's automatic colors
                                    .frame(width: 8, height: 8)
                                
                                Text(item.name)
                                    .labelSmall()
                                    .foregroundColor(Theme.Color.PrimaryText)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text("\(item.count)")
                                    .labelSmall()
                                    .foregroundColor(Theme.Color.SecondaryText)
                            }
                        }
                    }
                }
                .frame(height: 280)
                .animation(Theme.Animation.smooth, value: genreCounts)
            }
        }
        .materialCard()
    }
}

// Data structure for the genre chart
struct GenreCount: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let count: Int
    
    static func == (lhs: GenreCount, rhs: GenreCount) -> Bool {
        return lhs.name == rhs.name && lhs.count == rhs.count
    }
}

#Preview {
    let sampleMetadata1 = BookMetadata(
        googleBooksID: "1",
        title: "Dune",
        authors: ["Frank Herbert"],
        genre: ["Science Fiction", "Fantasy"]
    )
    
    let sampleMetadata2 = BookMetadata(
        googleBooksID: "2", 
        title: "Pride and Prejudice",
        authors: ["Jane Austen"],
        genre: ["Romance", "Classic Literature"]
    )
    
    let sampleMetadata3 = BookMetadata(
        googleBooksID: "3",
        title: "The Hobbit",
        authors: ["J.R.R. Tolkien"],
        genre: ["Fantasy", "Adventure"]
    )
    
    let sampleBooks = [
        UserBook(readingStatus: .read, metadata: sampleMetadata1),
        UserBook(readingStatus: .reading, metadata: sampleMetadata2),
        UserBook(readingStatus: .read, metadata: sampleMetadata3),
        UserBook(readingStatus: .read, metadata: sampleMetadata1) // Duplicate to show counts
    ]
    
    GenreBreakdownChartView(books: sampleBooks)
        .padding()
        .background(Theme.Color.Surface)
}