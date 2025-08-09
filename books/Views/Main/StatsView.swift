import SwiftUI
import SwiftData

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var currentTheme
    @Query private var allBooks: [UserBook]
    
    private var readBooks: [UserBook] {
        allBooks.filter { $0.readingStatus == .read }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // ScreenshotMode visual banner (purple gradient, visible only in ScreenshotMode)
            if ScreenshotMode.isEnabled {
                ZStack {
                    LinearGradient(
                        colors: [Color.purple.opacity(0.85), Color.purple.opacity(0.65)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    HStack {
                        Image(systemName: "camera.aperture")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Screenshot Mode")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal)
                }
                .frame(height: 32)
                .cornerRadius(0)
                .shadow(color: Color.purple.opacity(0.15), radius: 7, x: 0, y: 4)
            }
        }
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.xl) {
                // Enhanced hero stats section
                heroStatsSection
                
                // Reading Goals Section
                GoalProgressCard(books: allBooks)
                
                // Charts Section with better presentation
                if !allBooks.isEmpty {
                    chartsSection
                }
                
                // Reading achievements and milestones
                achievementsSection
                
                // Enhanced reading status breakdown
                ReadingStatusBreakdown(books: allBooks)
                
                // Cultural Diversity Section
                if !readBooks.isEmpty {
                    CulturalDiversitySection(books: readBooks)
                }
                
                // Recent Activity with enhanced presentation
                if !recentBooks.isEmpty {
                    RecentBooksSection(books: recentBooks)
                }
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .background(
            LinearGradient(
                colors: [
                    currentTheme.background,
                    currentTheme.surface.opacity(0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .navigationTitle("Reading Stats")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var recentBooks: [UserBook] {
        allBooks.filter { $0.dateCompleted != nil }
             .sorted { 
                 ($0.dateCompleted ?? Date.distantPast) > ($1.dateCompleted ?? Date.distantPast) 
             }
             .prefix(5)
             .map { $0 }
    }
    
    // MARK: - Enhanced Hero Stats Section
    private var heroStatsSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Beautiful header
            VStack(spacing: Theme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    currentTheme.primary.opacity(0.2),
                                    currentTheme.secondary.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [currentTheme.primary, currentTheme.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .shadow(color: currentTheme.primary.opacity(0.2), radius: 16, x: 0, y: 8)
                
                VStack(spacing: Theme.Spacing.sm) {
                    Text("Your Reading Journey")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(currentTheme.primaryText)
                    
                    Text("Track your progress and celebrate your achievements")
                        .font(.body)
                        .foregroundColor(currentTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Enhanced Quick Stats Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Theme.Spacing.md) {
                EnhancedStatCard(
                    title: "Total Books",
                    value: "\(allBooks.count)",
                    icon: "books.vertical.fill",
                    color: currentTheme.primary,
                    subtitle: "in your library"
                )
                
                EnhancedStatCard(
                    title: "Books Read",
                    value: "\(booksRead)",
                    icon: "checkmark.circle.fill",
                    color: currentTheme.tertiary,
                    subtitle: "completed"
                )
                
                EnhancedStatCard(
                    title: "Currently Reading",
                    value: "\(currentlyReading)",
                    icon: "book.fill",
                    color: currentTheme.secondary,
                    subtitle: "in progress"
                )
                
                EnhancedStatCard(
                    title: "Want to Read",
                    value: "\(wantToRead)",
                    icon: "heart.fill",
                    color: currentTheme.primary.opacity(0.7),
                    subtitle: "on wishlist"
                )
            }
        }
        .padding(Theme.Spacing.lg)
        .materialCard()
        .shadow(color: currentTheme.primary.opacity(0.1), radius: 12, x: 0, y: 6)
    }
    
    // MARK: - Enhanced Charts Section
    private var chartsSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Monthly reading chart with enhanced presentation
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Books Read This Year")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(currentTheme.primaryText)
                        
                        Text("Your reading momentum throughout the year")
                            .font(.subheadline)
                            .foregroundColor(currentTheme.secondaryText)
                    }
                    
                    Spacer()
                    
                    Text("\(booksReadThisYear)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(currentTheme.primary)
                }
                
                MonthlyReadsChartView(books: allBooks)
            }
            .padding(Theme.Spacing.md)
            .materialCard()
            
            // Genre breakdown with enhanced presentation
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Genre Breakdown")
                            .font(.headline)
                            .fontWeight(.semibold)  
                            .foregroundColor(currentTheme.primaryText)
                        
                        Text("\(uniqueGenres) different genres explored")
                            .font(.subheadline)
                            .foregroundColor(currentTheme.secondaryText)
                    }
                    
                    Spacer()
                }
                
                GenreBreakdownChartView(books: allBooks)
            }
            .padding(Theme.Spacing.md)
            .materialCard()
        }
    }
    
    // MARK: - Reading Achievements Section
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("Reading Achievements")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(currentTheme.primaryText)
                
                Spacer()
                
                Image(systemName: "trophy.fill")
                    .foregroundColor(currentTheme.tertiary)
                    .font(.title3)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.md) {
                    AchievementCard(
                        title: "First Book",
                        description: "Started your reading journey",
                        icon: "star.fill",
                        isUnlocked: allBooks.count > 0,
                        color: currentTheme.primary
                    )
                    
                    AchievementCard(
                        title: "Bookworm",
                        description: "Read 10 books",
                        icon: "books.vertical.fill",
                        isUnlocked: booksRead >= 10,
                        color: currentTheme.secondary
                    )
                    
                    AchievementCard(
                        title: "Explorer",
                        description: "Read from 3 cultures",
                        icon: "globe.americas.fill",
                        isUnlocked: culturalRegionsExplored >= 3,
                        color: currentTheme.tertiary
                    )
                    
                    AchievementCard(
                        title: "Diverse Reader",
                        description: "Read 5 languages",
                        icon: "text.bubble.fill",
                        isUnlocked: languageCount >= 5,
                        color: currentTheme.primary.opacity(0.8)
                    )
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
        }
        .padding(Theme.Spacing.md)
        .materialCard()
    }
    
    // MARK: - Computed Properties for Enhanced Stats
    private var booksRead: Int {
        allBooks.filter { $0.readingStatus == .read }.count
    }
    
    private var currentlyReading: Int {
        allBooks.filter { $0.readingStatus == .reading }.count
    }
    
    private var wantToRead: Int {
        allBooks.filter { $0.readingStatus == .toRead }.count
    }
    
    private var booksReadThisYear: Int {
        let currentYear = Calendar.current.component(.year, from: Date())
        return readBooks.filter { book in
            guard let dateCompleted = book.dateCompleted else { return false }
            return Calendar.current.component(.year, from: dateCompleted) == currentYear
        }.count
    }
    
    private var uniqueGenres: Int {
        Set(readBooks.compactMap { $0.metadata?.genre }.flatMap { $0 }).count
    }
    
    private var culturalRegionsExplored: Int {
        Set(readBooks.compactMap { $0.metadata?.culturalRegion }).count
    }
    
    private var languageCount: Int {
        Set(readBooks.compactMap { $0.metadata?.originalLanguage ?? $0.metadata?.language }).count
    }
}

// NEW: Cultural Diversity Section for Stats View
struct CulturalDiversitySection: View {
    @Environment(\.appTheme) private var currentTheme
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
        books.filter { $0.metadata?.marginalizedVoice == true }.count
    }
    
    private var translatedWorksCount: Int {
        books.filter { $0.metadata?.translator != nil }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Cultural Diversity")
                .titleLarge()
                .foregroundColor(currentTheme.primaryText)
            
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
        .padding(Theme.Spacing.md)
        .materialCard()
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
                    .foregroundColor(currentTheme.primaryAction)
            }
            
            // Progress bar showing cultural regions explored
            GeometryReader { geometry in
                HStack(spacing: 1) {
                    ForEach(CulturalRegion.allCases, id: \.self) { region in
                        Rectangle()
                            .fill(culturalStats[region] != nil ? region.color(theme: currentTheme) : Color.gray.opacity(0.3))
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
                .foregroundColor(currentTheme.primaryText)
            
            VStack(spacing: Theme.Spacing.xs) {
                ForEach(culturalStats.sorted(by: { $0.value > $1.value }).prefix(3), id: \.key) { region, count in
                    HStack {
                        Image(systemName: region.icon)
                            .foregroundColor(region.color(theme: currentTheme))
                            .frame(width: 16)
                        
                        Text(region.rawValue)
                            .bodyMedium()
                            .foregroundColor(currentTheme.primaryText)
                        
                        Spacer()
                        
                        Text("\(count)")
                            .labelMedium()
                            .fontWeight(.medium)
                            .foregroundColor(currentTheme.primaryText)
                        
                        Text("(\(Int((Double(count) / Double(books.count)) * 100))%)")
                            .labelSmall()
                            .foregroundColor(currentTheme.secondaryText)
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
                .foregroundColor(currentTheme.primaryText)
            
            VStack(spacing: Theme.Spacing.xs) {
                ForEach(languageStats.sorted(by: { $0.value > $1.value }).prefix(3), id: \.key) { language, count in
                    HStack {
                        Text(language.capitalized)
                            .bodyMedium()
                            .foregroundColor(currentTheme.primaryText)
                        
                        Spacer()
                        
                        Text("\(count)")
                            .labelMedium()
                            .fontWeight(.medium)
                            .foregroundColor(currentTheme.primaryText)
                        
                        Text("books")
                            .labelSmall()
                            .foregroundColor(currentTheme.secondaryText)
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
                .foregroundColor(currentTheme.primaryText)
            
            HStack(spacing: Theme.Spacing.md) {
                diverseVoicesStat(title: "Indigenous", count: indigenousAuthorsCount, color: currentTheme.primaryAction)
                diverseVoicesStat(title: "Marginalized", count: marginizedVoicesCount, color: currentTheme.secondaryAction)
                diverseVoicesStat(title: "Translated", count: translatedWorksCount, color: currentTheme.accentHighlight)
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
                .foregroundColor(currentTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Enhanced Stat Card Component
struct EnhancedStatCard: View {
    @Environment(\.appTheme) private var currentTheme
    let title: String
    let value: String
    let icon: String
    let color: Color
    let subtitle: String
    
    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(spacing: Theme.Spacing.xs) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(currentTheme.primaryText)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(currentTheme.primaryText)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(currentTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.md)
        .materialCard()
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct ReadingStatusBreakdown: View {
    @Environment(\.appTheme) private var currentTheme
    let books: [UserBook]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Reading Status")
                .titleLarge()
                .foregroundColor(currentTheme.primaryText)
            
            VStack(spacing: Theme.Spacing.sm) {
                StatusRow(status: .read, count: booksRead, total: books.count)
                StatusRow(status: .reading, count: currentlyReading, total: books.count)
                StatusRow(status: .toRead, count: wantToRead, total: books.count)
            }
        }
        .padding(Theme.Spacing.md)
        .materialCard()
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
    @Environment(\.appTheme) private var currentTheme
    let status: ReadingStatus
    let count: Int
    let total: Int
    
    var body: some View {
        HStack {
            Text(status.rawValue)
                .bodyLarge()
                .foregroundColor(currentTheme.primaryText)
            
            Spacer()
            
            Text("\(count)")
                .bodyLarge()
                .fontWeight(.medium)
                .foregroundColor(currentTheme.primaryText)
            
            if total > 0 {
                Text("(\(Int(Double(count) / Double(total) * 100))%)")
                    .labelSmall()
                    .foregroundColor(currentTheme.secondaryText)
            }
        }
    }
}

struct RecentBooksSection: View {
    @Environment(\.appTheme) private var currentTheme
    let books: [UserBook]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Recently Completed")
                .titleLarge()
                .foregroundColor(currentTheme.primaryText)
            
            ForEach(books, id: \.self) { book in
                HStack(spacing: Theme.Spacing.md) {
                    BookCoverImage(
                        imageURL: book.metadata?.imageURL?.absoluteString,
                        width: 40,
                        height: 60
                    )
                    
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text(book.metadata?.title ?? "Unknown Title")
                            .bodyMedium()
                            .fontWeight(.medium)
                            .foregroundColor(currentTheme.primaryText)
                            .lineLimit(1)
                        
                        Text(book.metadata?.authors.joined(separator: ", ") ?? "Unknown Author")
                            .labelMedium()
                            .foregroundColor(currentTheme.secondaryText)
                            .lineLimit(1)
                        
                        if let dateCompleted = book.dateCompleted {
                            Text("Completed \(dateCompleted.formatted(date: .abbreviated, time: .omitted))")
                                .labelSmall()
                                .foregroundColor(currentTheme.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    if let rating = book.rating, rating > 0 {
                        HStack(spacing: 2) {
                            ForEach(1...rating, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .labelSmall()
                                    .foregroundColor(currentTheme.accentHighlight)
                            }
                        }
                    }
                }
                .padding(.vertical, Theme.Spacing.xs)
            }
        }
        .padding(Theme.Spacing.md)
        .materialCard()
    }
}

struct MetricView: View {
    @Environment(\.appTheme) private var currentTheme
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .bodyMedium()
                .foregroundColor(currentTheme.primaryText)
            
            Text(value)
                .bodyLarge()
                .fontWeight(.medium)
                .foregroundColor(currentTheme.primaryText)
        }
    }
}

// MARK: - Achievement Card Component
struct AchievementCard: View {
    @Environment(\.appTheme) private var currentTheme
    let title: String
    let description: String
    let icon: String
    let isUnlocked: Bool
    let color: Color
    
    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? color.opacity(0.2) : currentTheme.outline.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(isUnlocked ? color : currentTheme.outline)
                
                if !isUnlocked {
                    Circle()
                        .fill(currentTheme.surface.opacity(0.8))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16))
                        .foregroundColor(currentTheme.outline)
                }
            }
            
            VStack(spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isUnlocked ? currentTheme.primaryText : currentTheme.outline)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(currentTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(width: 120)
        .padding(Theme.Spacing.sm)
        .materialCard()
        .opacity(isUnlocked ? 1.0 : 0.6)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isUnlocked)
    }
}

#Preview {
    StatsView()
        .modelContainer(for: UserBook.self, inMemory: true)
}