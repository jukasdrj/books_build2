import SwiftUI
import SwiftData

struct CulturalDiversityView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var currentTheme
    @Query private var books: [UserBook]
    
    @State private var selectedRegion: CulturalRegion?
    @State private var showingGoals = false
    
    private var readBooks: [UserBook] {
        books.filter { $0.readingStatus == .read }
    }
    
    private var culturalStats: [CulturalRegion: Int] {
        var stats: [CulturalRegion: Int] = [:]
        
        for book in readBooks {
            if let region = book.metadata?.culturalRegion {
                stats[region, default: 0] += 1
            }
        }
        
        return stats
    }
    
    private var languageStats: [String: Int] {
        var stats: [String: Int] = [:]
        
        for book in readBooks {
            if let language = book.metadata?.originalLanguage ?? book.metadata?.language {
                stats[language, default: 0] += 1
            }
        }
        
        return stats
    }
    
    private var genderDiversityStats: [AuthorGender: Int] {
        var stats: [AuthorGender: Int] = [:]
        
        for book in readBooks {
            if let gender = book.metadata?.authorGender {
                stats[gender, default: 0] += 1
            }
        }
        
        return stats
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
            LazyVStack(spacing: Theme.Spacing.xl) {
                // Enhanced hero section for App Store appeal
                heroSection
                culturalProgressSection
                culturalBreakdownSection
                languageDiversitySection
                genderDiversitySection
                culturalGoalsSection
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.xl)
            }
        }
        .background(
            LinearGradient(
                colors: [
                    currentTheme.background,
                    currentTheme.surface.opacity(0.6)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .navigationTitle("Cultural Diversity")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Goals", systemImage: "target") {
                    showingGoals = true
                }
                .foregroundColor(currentTheme.primary)
                .fontWeight(.semibold)
            }
        }
        .sheet(isPresented: $showingGoals) {
            CulturalGoalsView()
        }
    }
    
    // MARK: - Enhanced Hero Section
    private var heroSection: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Beautiful visual header
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                currentTheme.primary.opacity(0.2),
                                currentTheme.tertiary.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "globe.americas.fill")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                currentTheme.primary,
                                currentTheme.tertiary
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .shadow(color: currentTheme.primary.opacity(0.15), radius: 20, x: 0, y: 10)
            
            VStack(spacing: Theme.Spacing.md) {
                Text("Reading the World")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(currentTheme.primaryText)
                
                Text("Explore diverse voices and cultures through the power of literature")
                    .font(.body)
                    .foregroundColor(currentTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.md)
                
                // Enhanced stats display
                HStack(spacing: Theme.Spacing.xl) {
                    VStack(spacing: Theme.Spacing.xs) {
                        Text("\(readBooks.count)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(currentTheme.primary)
                        
                        Text("Books Read")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(currentTheme.secondaryText)
                    }
                    
                    VStack(spacing: Theme.Spacing.xs) {
                        Text("\(culturalStats.keys.count)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(currentTheme.tertiary)
                        
                        Text("Regions")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(currentTheme.secondaryText)
                    }
                    
                    VStack(spacing: Theme.Spacing.xs) {
                        Text("\(languageStats.keys.count)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(currentTheme.secondary)
                        
                        Text("Languages")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(currentTheme.secondaryText)
                    }
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .materialCard()
        .shadow(color: currentTheme.primary.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Enhanced Cultural Progress Section
    private var culturalProgressSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Cultural Journey Progress")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(currentTheme.primaryText)
                    
                    Text("Exploring voices from around the globe")
                        .font(.subheadline)
                        .foregroundColor(currentTheme.secondaryText)
                }
                
                Spacer()
                
                Text("\(culturalStats.keys.count)/\(CulturalRegion.allCases.count)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(currentTheme.primary)
            }
            
            // Simplified progress visualization
            culturalProgressVisualization
        }
        .padding(Theme.Spacing.md)
        .materialCard()
    }
    
    // MARK: - Cultural Progress Visualization Helper
    private var culturalProgressVisualization: some View {
        GeometryReader { geometry in
            HStack(spacing: 3) {
                ForEach(CulturalRegion.allCases, id: \.self) { region in
                    culturalRegionBar(for: region)
                }
            }
        }
        .frame(height: 80)
    }
    
    private func culturalRegionBar(for region: CulturalRegion) -> some View {
        let hasBooks = culturalStats[region] != nil
        let bookCount = culturalStats[region] ?? 0
        let barHeight: CGFloat = hasBooks ? max(30, min(60, CGFloat(bookCount) * 8)) : 20
        
        return VStack(spacing: Theme.Spacing.xs) {
            RoundedRectangle(cornerRadius: 4)
                .fill(hasBooks ? 
                      LinearGradient(
                        colors: [region.color(theme: currentTheme), region.color(theme: currentTheme).opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                      ) : 
                      LinearGradient(
                        colors: [currentTheme.outline.opacity(0.2), currentTheme.outline.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                      )
                )
                .frame(height: barHeight)
                .shadow(color: hasBooks ? region.color(theme: currentTheme).opacity(0.3) : .clear, 
                       radius: 4, x: 0, y: 2)
            
            Text(flagEmoji(for: region))
                .font(.caption2)
                .opacity(hasBooks ? 1.0 : 0.4)
        }
    }
    
    // Helper function to provide flag emojis for regions
    private func flagEmoji(for region: CulturalRegion) -> String {
        switch region {
        case .africa: return "🌍"
        case .asia: return "🌏"
        case .europe: return "🌍"
        case .northAmerica: return "🌎"
        case .southAmerica: return "🌎"
        case .oceania: return "🌏"
        case .middleEast: return "🌍"
        case .caribbean: return "🏝️"
        case .centralAsia: return "🌏"
        case .indigenous: return "🍃"
        }
    }
    
    private var culturalBreakdownSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Cultural Breakdown")
                .titleMedium()
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Theme.Spacing.sm) {
                ForEach(culturalStats.sorted(by: { $0.value > $1.value }), id: \.key) { region, count in
                    culturalRegionCard(region: region, count: count)
                }
            }
        }
    }
    
    private func culturalRegionCard(region: CulturalRegion, count: Int) -> some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: region.icon)
                    .labelMedium()
                    .foregroundColor(region.color(theme: currentTheme))
                    .frame(width: Theme.Size.iconMedium, height: Theme.Size.iconMedium)
                
                Spacer()
                
                Text("\(count)")
                    .readingStats()
                    .foregroundColor(region.color(theme: currentTheme))
            }
            
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(region.rawValue)
                    .culturalTag()
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("\(Int((Double(count) / Double(readBooks.count)) * 100))% of collection")
                    .labelSmall()
                    .foregroundColor(currentTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(Theme.Spacing.md)
        .materialCard()
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                .stroke(region.color(theme: currentTheme).opacity(0.3), lineWidth: 1)
        )
    }
    
    private var languageDiversitySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Language Diversity")
                .titleMedium()
            
            VStack(spacing: Theme.Spacing.sm) {
                ForEach(languageStats.sorted(by: { $0.value > $1.value }).prefix(8), id: \.key) { language, count in
                    HStack {
                        Text(language.capitalized)
                            .bodyMedium()
                        
                        Spacer()
                        
                        Text("\(count)")
                            .labelMedium()
                            .foregroundColor(currentTheme.primaryAction)
                        
                        Text("books")
                            .labelMedium()
                            .foregroundColor(currentTheme.secondaryText)
                    }
                    .padding(.vertical, Theme.Spacing.xs)
                }
            }
            .padding(Theme.Spacing.md)
            .materialCard()
        }
    }
    
    private var genderDiversitySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Author Gender Diversity")
                .titleMedium()
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Theme.Spacing.sm) {
                ForEach(genderDiversityStats.sorted(by: { $0.value > $1.value }), id: \.key) { gender, count in
                    VStack(spacing: Theme.Spacing.sm) {
                        Image(systemName: gender.icon)
                            .foregroundColor(currentTheme.secondaryAction)
                            .frame(width: Theme.Size.iconLarge, height: Theme.Size.iconLarge)
                        
                        Text("\(count)")
                            .titleSmall()
                            .foregroundColor(currentTheme.primaryAction)
                        
                        Text(gender.rawValue)
                            .labelSmall()
                            .foregroundColor(currentTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(Theme.Spacing.sm)
                    .materialCard()
                }
            }
        }
    }
    
    private var culturalGoalsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("Cultural Reading Goals")
                    .titleMedium()
                
                Spacer()
                
                Button("View All", systemImage: "arrow.right") {
                    showingGoals = true
                }
                .materialButton(style: .text, size: .small)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.md) {
                    goalCard(title: "African Literature", progress: culturalStats[.africa] ?? 0, target: 12)
                    goalCard(title: "Translated Works", progress: translatedWorksCount, target: 24)
                    goalCard(title: "Female Authors", progress: femaleAuthorsCount, target: 15)
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
        }
    }
    
    private func goalCard(title: String, progress: Int, target: Int) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(title)
                .labelLarge()
                .foregroundColor(currentTheme.primaryText)
            
            HStack {
                Text("\(progress)")
                    .titleMedium()
                    .foregroundColor(currentTheme.primaryAction)
                
                Text("/ \(target)")
                    .bodyMedium()
                    .foregroundColor(currentTheme.secondaryText)
            }
            
            ProgressView(value: Double(progress), total: Double(target))
                .tint(currentTheme.primaryAction)
                .scaleEffect(y: 0.5)
        }
        .padding(Theme.Spacing.md)
        .frame(width: 150)
        .materialCard()
    }
    
    
    private var translatedWorksCount: Int {
        readBooks.filter { $0.metadata?.translatorNationality != nil && !($0.metadata?.translatorNationality?.isEmpty ?? true) }.count
    }
    
    private var femaleAuthorsCount: Int {
        readBooks.filter { $0.metadata?.authorGender == .female }.count
    }
}

struct CulturalGoalsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var currentTheme
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    Text("Set your cultural reading goals for this year")
                        .bodyLarge()
                        .foregroundColor(currentTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.md)
                    
                    // Cultural goals content will be implemented here
                    Text("Cultural Goals Setup Coming Soon")
                        .titleMedium()
                        .foregroundColor(currentTheme.secondaryText)
                        .padding(Theme.Spacing.xl)
                }
            }
            .navigationTitle("Cultural Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CulturalDiversityView()
    }
    .modelContainer(for: [UserBook.self, BookMetadata.self], inMemory: true)
}