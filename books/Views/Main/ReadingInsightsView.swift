import SwiftUI
import SwiftData
import Charts

// MARK: - iOS 26 Liquid Glass Reading Insights View
// Clean combination of reading stats and cultural diversity tracking

struct ReadingInsightsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.unifiedThemeStore) private var themeStore
    @Query private var allBooks: [UserBook]
    
    @State private var selectedTimeframe: TimeFrame = .allTime
    @State private var animateElements = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 24) {
                    // Hero section with reading journey
                    heroSection
                    
                    // Key metrics dashboard
                    metricsSection
                    
                    // Cultural diversity section
                    culturalSection
                    
                    // Reading goals section
                    goalsSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .background(liquidGlassBackground)
            .navigationTitle("Reading Insights")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
                    animateElements = true
                }
            }
        }
    }
    
    // MARK: - Liquid Glass Background
    
    @ViewBuilder
    private var liquidGlassBackground: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    currentTheme.background.opacity(0.95),
                    currentTheme.surface.opacity(0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Glass overlay
            Rectangle()
                .fill(.ultraThinMaterial.opacity(0.3))
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Hero Section
    
    @ViewBuilder
    private var heroSection: some View {
        VStack(spacing: 20) {
            // Header with cultural globe
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    currentTheme.primary.opacity(0.3),
                                    currentTheme.secondary.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 30
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "globe.americas.fill")
                        .font(.title)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [currentTheme.primary, currentTheme.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(animateElements ? 5 : -5))
                        .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateElements)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Reading Journey")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(currentTheme.primaryText)
                    
                    Text("Exploring \(culturesExplored) cultures across \(booksReadThisYear) books")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(currentTheme.secondaryText)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            
            // Progress visualization
            HStack(spacing: 24) {
                // Reading progress ring
                ZStack {
                    Circle()
                        .stroke(currentTheme.surface.opacity(0.8), lineWidth: 10)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: animateElements ? readingProgress : 0)
                        .stroke(
                            AngularGradient(
                                colors: [currentTheme.primary, currentTheme.secondary, currentTheme.primary],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.5), value: animateElements)
                    
                    VStack(spacing: 2) {
                        Text("\(Int(readingProgress * 100))%")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(currentTheme.primary)
                        Text("Goal")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(currentTheme.secondaryText)
                    }
                }
                
                // Key stats
                VStack(alignment: .leading, spacing: 12) {
                    statItem(icon: "book.fill", value: "\(booksReadThisYear)", label: "Books Read")
                    statItem(icon: "globe", value: "\(culturesExplored)", label: "Cultures")
                    statItem(icon: "star.fill", value: String(format: "%.1f", averageRating), label: "Avg Rating")
                }
            }
        }
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.regularMaterial.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [currentTheme.primary.opacity(0.3), currentTheme.secondary.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        }
        .shadow(color: currentTheme.primary.opacity(0.1), radius: 20, x: 0, y: 10)
        .scaleEffect(animateElements ? 1 : 0.95)
        .opacity(animateElements ? 1 : 0.8)
        .animation(.spring(response: 0.8, dampingFraction: 0.8), value: animateElements)
    }
    
    @ViewBuilder
    private func statItem(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(currentTheme.primary)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(currentTheme.primaryText)
                
                Text(label)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(currentTheme.secondaryText)
            }
        }
    }
    
    // MARK: - Metrics Section
    
    @ViewBuilder
    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Metrics")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(currentTheme.primaryText)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                metricCard(
                    icon: "book.fill",
                    title: "Books Read",
                    value: "\(booksReadThisYear)",
                    subtitle: "this year",
                    color: currentTheme.primary,
                    animationDelay: 0.1
                )
                
                metricCard(
                    icon: "globe.americas.fill",
                    title: "Cultures",
                    value: "\(culturesExplored)",
                    subtitle: "explored",
                    color: currentTheme.secondary,
                    animationDelay: 0.2
                )
                
                metricCard(
                    icon: "star.fill",
                    title: "Average Rating",
                    value: String(format: "%.1f", averageRating),
                    subtitle: "out of 5",
                    color: currentTheme.tertiary,
                    animationDelay: 0.3
                )
                
                metricCard(
                    icon: "flame.fill",
                    title: "Reading Streak",
                    value: "\(readingStreak)",
                    subtitle: "days",
                    color: .orange,
                    animationDelay: 0.4
                )
            }
        }
        .padding(.horizontal, 4)
    }
    
    @ViewBuilder
    private func metricCard(
        icon: String,
        title: String,
        value: String,
        subtitle: String,
        color: Color,
        animationDelay: Double
    ) -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 30, height: 30)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(currentTheme.primaryText)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(currentTheme.secondaryText)
                
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .regular, design: .rounded))
                        .foregroundColor(currentTheme.secondaryText.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.thinMaterial.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(color.opacity(0.3), lineWidth: 1)
                )
        }
        .shadow(color: color.opacity(0.1), radius: 10, x: 0, y: 5)
        .scaleEffect(animateElements ? 1 : 0.9)
        .opacity(animateElements ? 1 : 0.6)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(animationDelay), value: animateElements)
    }
    
    // MARK: - Cultural Section
    
    @ViewBuilder
    private var culturalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Cultural Diversity")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(currentTheme.primaryText)
                
                Spacer()
                
                Text("\(culturesExplored) regions")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(currentTheme.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background {
                        Capsule()
                            .fill(.ultraThinMaterial.opacity(0.8))
                            .overlay(Capsule().strokeBorder(currentTheme.primary.opacity(0.3), lineWidth: 1))
                    }
            }
            
            // Cultural regions grid
            let regions = uniqueRegions.prefix(6)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(Array(regions.enumerated()), id: \.offset) { index, region in
                    culturalRegionCard(region: region, animationDelay: Double(index) * 0.1 + 0.6)
                }
            }
            
            if uniqueRegions.count > 6 {
                Text("+ \(uniqueRegions.count - 6) more regions")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(currentTheme.secondaryText)
                    .padding(.top, 8)
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.regularMaterial.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [currentTheme.secondary.opacity(0.3), currentTheme.primary.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        }
        .shadow(color: currentTheme.secondary.opacity(0.1), radius: 15, x: 0, y: 8)
        .padding(.horizontal, 4)
    }
    
    @ViewBuilder
    private func culturalRegionCard(region: CulturalRegion, animationDelay: Double) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(region.color(theme: AppColorTheme(variant: .purpleBoho)).opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(.ultraThinMaterial.opacity(0.3))
                
                Text(region.emoji)
                    .font(.title2)
            }
            
            Text(region.shortDisplayName)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(currentTheme.primaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .scaleEffect(animateElements ? 1 : 0.8)
        .opacity(animateElements ? 1 : 0.5)
        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(animationDelay), value: animateElements)
    }
    
    // MARK: - Goals Section
    
    @ViewBuilder
    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reading Goals")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(currentTheme.primaryText)
            
            VStack(spacing: 16) {
                goalCard(
                    title: "Annual Reading Goal",
                    progress: readingProgress,
                    current: booksReadThisYear,
                    target: 25,
                    color: currentTheme.primary,
                    animationDelay: 1.0
                )
                
                goalCard(
                    title: "Cultural Diversity Goal",
                    progress: Double(culturesExplored) / 10.0,
                    current: culturesExplored,
                    target: 10,
                    color: currentTheme.secondary,
                    animationDelay: 1.1
                )
            }
        }
        .padding(.horizontal, 4)
    }
    
    @ViewBuilder
    private func goalCard(
        title: String,
        progress: Double,
        current: Int,
        target: Int,
        color: Color,
        animationDelay: Double
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(currentTheme.primaryText)
                
                Spacer()
                
                Text("\(current)/\(target)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }
            
            // Progress bar with glass effect
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.ultraThinMaterial.opacity(0.6))
                        .overlay(Capsule().strokeBorder(currentTheme.surface.opacity(0.3), lineWidth: 1))
                        .frame(height: 12)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geometry.size.width * (animateElements ? min(progress, 1.0) : 0),
                            height: 12
                        )
                        .animation(.spring(response: 1.2, dampingFraction: 0.8).delay(animationDelay), value: animateElements)
                }
            }
            .frame(height: 12)
            
            HStack {
                Text("\(Int(progress * 100))% complete")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(currentTheme.secondaryText)
                
                Spacer()
                
                let remaining = max(target - current, 0)
                Text("\(remaining) remaining")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(currentTheme.secondaryText)
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.thinMaterial.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(color.opacity(0.2), lineWidth: 1)
                )
        }
        .shadow(color: color.opacity(0.08), radius: 12, x: 0, y: 6)
        .scaleEffect(animateElements ? 1 : 0.95)
        .opacity(animateElements ? 1 : 0.7)
        .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(animationDelay), value: animateElements)
    }
    
    // MARK: - Theme Helper
    
    private var currentTheme: AppColorTheme {
        themeStore.appTheme
    }
    
    // MARK: - Computed Properties
    
    private var booksReadThisYear: Int {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        
        return allBooks.filter { book in
            guard book.readingStatus == .read,
                  let completedDate = book.dateCompleted else { return false }
            return calendar.component(.year, from: completedDate) == currentYear
        }.count
    }
    
    private var culturesExplored: Int {
        let cultures = Set(allBooks.compactMap { $0.metadata?.culturalRegion })
        return cultures.count
    }
    
    private var averageRating: Double {
        let ratings = allBooks.compactMap { $0.rating }
        guard !ratings.isEmpty else { return 0.0 }
        return Double(ratings.reduce(0, +)) / Double(ratings.count)
    }
    
    private var readingStreak: Int {
        // Simple implementation - count recent completed books
        let recentBooks = allBooks.filter { book in
            guard book.readingStatus == .read,
                  let completedDate = book.dateCompleted else { return false }
            return completedDate >= Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        }
        return min(recentBooks.count, 30) // Cap at 30 days
    }
    
    private var readingProgress: Double {
        let target = 25.0 // Default annual goal
        return min(Double(booksReadThisYear) / target, 1.0)
    }
    
    private var uniqueRegions: [CulturalRegion] {
        Array(Set(allBooks.compactMap { $0.metadata?.culturalRegion }))
    }
}

// MARK: - Extensions

extension CulturalRegion {
    var shortDisplayName: String {
        switch self {
        case .africa: return "Africa"
        case .asia: return "Asia"
        case .europe: return "Europe"
        case .northAmerica: return "N. America"
        case .southAmerica: return "S. America"
        case .oceania: return "Oceania"
        case .middleEast: return "Middle East"
        case .caribbean: return "Caribbean"
        case .centralAsia: return "C. Asia"
        case .indigenous: return "Indigenous"
        case .antarctica: return "Antarctica"
        case .international: return "Global"
        }
    }
}

// MARK: - Supporting Types

private enum TimeFrame: String, CaseIterable {
    case week = "Week"
    case month = "Month"  
    case year = "Year"
    case allTime = "All Time"
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ReadingInsightsView()
            .navigationTitle("Reading Insights")
            .navigationBarTitleDisplayMode(.large)
    }
    .modelContainer(for: [UserBook.self, BookMetadata.self], inMemory: true)
    .environment(\.unifiedThemeStore, UnifiedThemeStore())
}