import SwiftUI
import SwiftData

struct CulturalDiversityView: View {
    @Environment(\.modelContext) private var modelContext
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
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.lg) {
                headerSection
                culturalBreakdownSection
                languageDiversitySection
                genderDiversitySection
                culturalGoalsSection
                marginizedVoicesSection
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .background(Color.theme.background)
        .navigationTitle("Cultural Diversity")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Goals", systemImage: "target") {
                    showingGoals = true
                }
                .materialButton(style: .tonal, size: .small)
            }
        }
        .sheet(isPresented: $showingGoals) {
            CulturalGoalsView()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Reading the World")
                        .headlineMedium()
                    
                    Text("Exploring diverse voices and cultures through literature")
                        .bodyMedium()
                        .foregroundColor(Color.theme.secondaryText)
                }
                
                Spacer()
                
                VStack(spacing: Theme.Spacing.xs) {
                    Text("\(readBooks.count)")
                        .readingStats()
                    
                    Text("Books Read")
                        .labelSmall()
                        .foregroundColor(Color.theme.secondaryText)
                }
            }
            
            // Progress towards global reading goal
            if readBooks.count > 0 {
                culturalProgressBar
            }
        }
        .padding(Theme.Spacing.md)
        .materialCard()
    }
    
    private var culturalProgressBar: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Cultural Regions Explored")
                    .labelMedium()
                
                Spacer()
                
                Text("\(culturalStats.keys.count)/\(CulturalRegion.allCases.count)")
                    .labelMedium()
                    .foregroundColor(Color.theme.primaryAction)
            }
            
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    ForEach(CulturalRegion.allCases, id: \.self) { region in
                        Rectangle()
                            .fill(culturalStats[region] != nil ? region.color : Color.theme.outline.opacity(0.3))
                            .frame(height: 8)
                            .cornerRadius(4)
                    }
                }
            }
            .frame(height: 8)
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
                    .foregroundColor(region.color)
                    .frame(width: Theme.Size.iconMedium, height: Theme.Size.iconMedium)
                
                Spacer()
                
                Text("\(count)")
                    .titleSmall()
                    .foregroundColor(region.color)
            }
            
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(region.rawValue)
                    .labelMedium()
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("\(Int((Double(count) / Double(readBooks.count)) * 100))% of collection")
                    .labelSmall()
                    .foregroundColor(Color.theme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(Theme.Spacing.md)
        .materialCard()
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                .stroke(region.color.opacity(0.3), lineWidth: 1)
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
                            .foregroundColor(Color.theme.primaryAction)
                        
                        Text("books")
                            .labelMedium()
                            .foregroundColor(Color.theme.secondaryText)
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
                            .foregroundColor(Color.theme.secondaryAction)
                            .frame(width: Theme.Size.iconLarge, height: Theme.Size.iconLarge)
                        
                        Text("\(count)")
                            .titleSmall()
                            .foregroundColor(Color.theme.primaryAction)
                        
                        Text(gender.rawValue)
                            .labelSmall()
                            .foregroundColor(Color.theme.secondaryText)
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
                    goalCard(title: "Indigenous Voices", progress: indigenousAuthorsCount, target: 6)
                }
                .padding(.horizontal, Theme.Spacing.md)
            }
        }
    }
    
    private func goalCard(title: String, progress: Int, target: Int) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(title)
                .labelLarge()
                .foregroundColor(Color.theme.primaryText)
            
            HStack {
                Text("\(progress)")
                    .titleMedium()
                    .foregroundColor(Color.theme.primaryAction)
                
                Text("/ \(target)")
                    .bodyMedium()
                    .foregroundColor(Color.theme.secondaryText)
            }
            
            ProgressView(value: Double(progress), total: Double(target))
                .tint(Color.theme.primaryAction)
                .scaleEffect(y: 0.5)
        }
        .padding(Theme.Spacing.md)
        .frame(width: 150)
        .materialCard()
    }
    
    private var marginizedVoicesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Marginalized Voices")
                .titleMedium()
            
            HStack(spacing: Theme.Spacing.lg) {
                VStack(spacing: Theme.Spacing.xs) {
                    Text("\(indigenousAuthorsCount)")
                        .readingStats()
                        .foregroundColor(Color.theme.cultureIndigenous)
                    
                    Text("Indigenous Authors")
                        .labelSmall()
                        .foregroundColor(Color.theme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: Theme.Spacing.xs) {
                    Text("\(marginizedVoicesCount)")
                        .readingStats()
                        .foregroundColor(Color.theme.secondaryAction)
                    
                    Text("Marginalized Voices")
                        .labelSmall()
                        .foregroundColor(Color.theme.secondaryText)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: Theme.Spacing.xs) {
                    Text("\(translatedWorksCount)")
                        .readingStats()
                        .foregroundColor(Color.theme.tertiary)
                    
                    Text("Translated Works")
                        .labelSmall()
                        .foregroundColor(Color.theme.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(Theme.Spacing.md)
            .materialCard()
        }
    }
    
    // Computed properties for marginalized voices stats
    private var indigenousAuthorsCount: Int {
        readBooks.filter { $0.metadata?.indigenousAuthor == true }.count
    }
    
    private var marginizedVoicesCount: Int {
        readBooks.filter { $0.metadata?.marginizedVoice == true }.count
    }
    
    private var translatedWorksCount: Int {
        readBooks.filter { $0.metadata?.translator != nil }.count
    }
}

struct CulturalGoalsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    Text("Set your cultural reading goals for this year")
                        .bodyLarge()
                        .foregroundColor(Color.theme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.md)
                    
                    // Cultural goals content will be implemented here
                    Text("Cultural Goals Setup Coming Soon")
                        .titleMedium()
                        .foregroundColor(Color.theme.secondaryText)
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