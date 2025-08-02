import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allBooks: [UserBook]
    
    private var readBooks: [UserBook] {
        allBooks.filter { $0.readingStatus == .read }
    }
    
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
                    
                    // NEW: Cultural Diversity Section
                    if !readBooks.isEmpty {
                        CulturalDiversitySection(books: readBooks)
                    }
                    
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

// NEW: Cultural Diversity Section for Stats View
struct CulturalDiversitySection: View {
    let books: [UserBook]
    
    private var culturalStats: [CulturalRegion: Int] {
        var stats: [CulturalRegion: Int] = [:]
        
        for book in books {
            if let region = book.metadata?.culturalRegion {
                stats[region, default: 0] += 1
            }
        }
        
        return stats
    }
    
    private var languageStats: [String: Int] {
        var stats: [String: Int] = [:]
        
        for book in books {
            if let language = book.metadata?.originalLanguage ?? book.metadata?.language {
                stats[language, default: 0] += 1
            }
        }
        
        return stats
    }
    
    private var genderDiversityStats: [AuthorGender: Int] {
        var stats: [AuthorGender: Int] = [:]
        
        for book in books {
            if let gender = book.metadata?.authorGender {
                stats[gender, default: 0] += 1
            }
        }
        
        return stats
    }
    
    private var indigenousAuthorsCount: Int {
        books.filter { $0.metadata?.indigenousAuthor == true }.count
    }
    
    private var marginizedVoicesCount: Int {
        books.filter { $0.metadata?.marginizedVoice == true }.count
    }
    
    private var translatedWorksCount: Int {
        books.filter { $0.metadata?.translator != nil }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Cultural Diversity")
                .titleLarge()
                .foregroundColor(Color.theme.primaryText)
            
            // Cultural Progress Overview
            culturalProgressOverview
            
            // Cultural Regions Breakdown
            if !culturalStats.isEmpty {
                culturalRegionsSection
            }
            
            // Language Diversity
            if !languageStats.isEmpty {
                languageDiversitySection
            }
            
            // Marginalized Voices Summary
            marginizedVoicesSection
        }
        .padding()
        .background(Color.theme.cardBackground)
        .cornerRadius(12)
    }
    
    private var culturalProgressOverview: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Reading the World")
                    .bodyLarge()
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(culturalStats.keys.count)/\(CulturalRegion.allCases.count) regions")
                    .labelMedium()
                    .foregroundColor(Color.theme.primaryAction)
            }
            
            // Progress bar showing cultural regions explored
            GeometryReader { geometry in
                HStack(spacing: 1) {
                    ForEach(CulturalRegion.allCases, id: \.self) { region in
                        Rectangle()
                            .fill(culturalStats[region] != nil ? region.color : Color.gray.opacity(0.3))
                            .frame(height: 6)
                            .cornerRadius(3)
                    }
                }
            }
            .frame(height: 6)
        }
    }
    
    private var culturalRegionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Top Cultural Regions")
                .bodyMedium()
                .fontWeight(.medium)
                .foregroundColor(Color.theme.primaryText)
            
            VStack(spacing: Theme.Spacing.xs) {
                ForEach(culturalStats.sorted(by: { $0.value > $1.value }).prefix(3), id: \.key) { region, count in
                    HStack {
                        Image(systemName: region.icon)
                            .foregroundColor(region.color)
                            .frame(width: 16)
                        
                        Text(region.rawValue)
                            .bodyMedium()
                            .foregroundColor(Color.theme.primaryText)
                        
                        Spacer()
                        
                        Text("\(count)")
                            .labelMedium()
                            .fontWeight(.medium)
                            .foregroundColor(Color.theme.primaryText)
                        
                        Text("(\(Int((Double(count) / Double(books.count)) * 100))%)")
                            .labelSmall()
                            .foregroundColor(Color.theme.secondaryText)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
    
    private var languageDiversitySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Language Diversity")
                .bodyMedium()
                .fontWeight(.medium)
                .foregroundColor(Color.theme.primaryText)
            
            VStack(spacing: Theme.Spacing.xs) {
                ForEach(languageStats.sorted(by: { $0.value > $1.value }).prefix(3), id: \.key) { language, count in
                    HStack {
                        Text(language.capitalized)
                            .bodyMedium()
                            .foregroundColor(Color.theme.primaryText)
                        
                        Spacer()
                        
                        Text("\(count)")
                            .labelMedium()
                            .fontWeight(.medium)
                            .foregroundColor(Color.theme.primaryText)
                        
                        Text("books")
                            .labelSmall()
                            .foregroundColor(Color.theme.secondaryText)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }
    
    private var marginizedVoicesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Diverse Voices")
                .bodyMedium()
                .fontWeight(.medium)
                .foregroundColor(Color.theme.primaryText)
            
            HStack(spacing: Theme.Spacing.md) {
                diverseVoicesStat(title: "Indigenous", count: indigenousAuthorsCount, color: Color.theme.primaryAction)
                diverseVoicesStat(title: "Marginalized", count: marginizedVoicesCount, color: Color.theme.secondaryAction)
                diverseVoicesStat(title: "Translated", count: translatedWorksCount, color: Color.theme.accentHighlight)
            }
        }
    }
    
    private func diverseVoicesStat(title: String, count: Int, color: Color) -> some View {
        VStack(spacing: Theme.Spacing.xs) {
            Text("\(count)")
                .titleSmall()
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .labelSmall()
                .foregroundColor(Color.theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
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
                color: Color.theme.primaryAction
            )
            
            StatCard(
                title: "Books Read",
                value: "\(booksRead)",
                icon: "checkmark.circle",
                color: Color.theme.primaryAction.opacity(0.8)
            )
            
            StatCard(
                title: "Currently Reading",
                value: "\(currentlyReading)",
                icon: "book",
                color: Color.theme.primaryAction.opacity(0.6)
            )
            
            StatCard(
                title: "Want to Read",
                value: "\(wantToRead)",
                icon: "heart",
                color: Color.theme.primaryAction.opacity(0.4)
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
                .labelLarge()
                .foregroundColor(color)
            
            Text(value)
                .readingStats()
                .fontWeight(.bold)
                .foregroundColor(Color.theme.primaryText)
            
            Text(title)
                .labelMedium()
                .multilineTextAlignment(.center)
                .foregroundColor(Color.theme.secondaryText)
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
                .foregroundColor(Color.theme.primaryText)
            
            VStack(spacing: 8) {
                StatusRow(status: .read, count: booksRead, total: books.count)
                StatusRow(status: .reading, count: currentlyReading, total: books.count)
                StatusRow(status: .toRead, count: wantToRead, total: books.count)
            }
        }
        .padding()
        .background(Color.theme.cardBackground)
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
                .foregroundColor(Color.theme.primaryText)
            
            Spacer()
            
            Text("\(count)")
                .bodyLarge()
                .fontWeight(.medium)
                .foregroundColor(Color.theme.primaryText)
            
            if total > 0 {
                Text("(\(Int(Double(count) / Double(total) * 100))%)")
                    .labelSmall()
                    .foregroundColor(Color.theme.secondaryText)
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
                .foregroundColor(Color.theme.primaryText)
            
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
                            .foregroundColor(Color.theme.primaryText)
                            .lineLimit(1)
                        
                        Text(book.metadata?.authors.joined(separator: ", ") ?? "Unknown Author")
                            .labelMedium()
                            .foregroundColor(Color.theme.secondaryText)
                            .lineLimit(1)
                        
                        if let dateCompleted = book.dateCompleted {
                            Text("Completed \(dateCompleted.formatted(date: .abbreviated, time: .omitted))")
                                .labelSmall()
                                .foregroundColor(Color.theme.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    if let rating = book.rating, rating > 0 {
                        HStack(spacing: 2) {
                            ForEach(1...rating, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .labelSmall()
                                    .foregroundColor(Color.theme.accentHighlight)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color.theme.cardBackground)
        .cornerRadius(12)
    }
}

#Preview {
    StatsView()
        .modelContainer(for: UserBook.self, inMemory: true)
}