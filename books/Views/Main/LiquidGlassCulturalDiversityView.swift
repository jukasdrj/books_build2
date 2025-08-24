import SwiftUI
import SwiftData
import Charts

// MARK: - Liquid Glass Cultural Diversity View
// Enhanced cultural diversity tracking with immersive visualizations

struct CulturalDiversityView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var theme
    @Query private var allBooks: [UserBook]
    
    @State private var selectedRegion: CulturalRegion?
    @State private var animateVisualization = false
    @State private var showingGoals = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Hero section with globe visualization
                globalDiversityHero
                
                // Interactive region breakdown
                regionBreakdownSection
                
                // Language diversity
                languageDiversitySection
                
                // Cultural goals and achievements
                culturalGoalsSection
                
                // Reading patterns analysis
                readingPatternsSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(
            // Immersive background with cultural themes
            ZStack {
                LinearGradient(
                    colors: [
                        theme.background.opacity(0.95),
                        theme.surface.opacity(0.8),
                        theme.primary.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Subtle cultural pattern overlay
                culturalPatternOverlay
                    .opacity(0.1)
            }
            .ignoresSafeArea()
        )
        .onAppear {
            withAnimation(LiquidGlassTheme.FluidAnimation.flowing.springAnimation.delay(0.3)) {
                animateVisualization = true
            }
        }
        .sheet(isPresented: $showingGoals) {
            CulturalGoalsView()
        }
    }
    
    // MARK: - Global Diversity Hero Section
    
    @ViewBuilder
    private var globalDiversityHero: some View {
        VStack(spacing: 20) {
            // Header with cultural icon
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    theme.primary.opacity(0.3),
                                    theme.secondary.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 10,
                                endRadius: 40
                            )
                        )
                        .frame(width: 80, height: 80)
                        .liquidGlassVibrancy(.subtle)
                    
                    Image(systemName: "globe.americas.fill")
                        .font(.largeTitle)
                        .foregroundStyle(
                            AngularGradient(
                                colors: culturalGradientColors,
                                center: .center
                            )
                        )
                        .liquidGlassVibrancy(.maximum)
                        .rotationEffect(.degrees(animateVisualization ? 360 : 0))
                        .animation(
                            .linear(duration: 20).repeatForever(autoreverses: false),
                            value: animateVisualization
                        )
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Cultural Diversity")
                        .font(LiquidGlassTheme.typography.headlineLarge)
                        .foregroundColor(theme.primaryText)
                        .liquidGlassVibrancy(.maximum)
                    
                    Text("Explore literature from around the world")
                        .font(LiquidGlassTheme.typography.bodyLarge)
                        .foregroundColor(theme.secondaryText)
                        .liquidGlassVibrancy(.medium)
                    
                    // Diversity score
                    diversityScoreIndicator
                }
                
                Spacer()
            }
            
            // World map visualization
            worldMapVisualization
        }
        .liquidGlassCard(
            material: .regular,
            depth: .elevated,
            radius: .flowing,
            vibrancy: .medium
        )
        .padding(.horizontal, 4)
    }
    
    // MARK: - Region Breakdown Section
    
    @ViewBuilder
    private var regionBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Regional Distribution")
                .font(LiquidGlassTheme.typography.headlineMedium)
                .foregroundColor(theme.primaryText)
                .liquidGlassVibrancy(.maximum)
            
            // Interactive region grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(CulturalRegion.allCases, id: \.self) { region in
                    RegionCard(
                        region: region,
                        bookCount: booksCount(for: region),
                        isSelected: selectedRegion == region,
                        onSelect: {
                            withAnimation(LiquidGlassTheme.FluidAnimation.smooth.springAnimation) {
                                selectedRegion = selectedRegion == region ? nil : region
                            }
                        }
                    )
                }
            }
            
            // Selected region details
            if let selectedRegion = selectedRegion {
                selectedRegionDetail(region: selectedRegion)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .bottom).combined(with: .opacity)
                    ))
            }
        }
        .liquidGlassCard(
            material: .regular,
            depth: .elevated,
            radius: .comfortable,
            vibrancy: .medium
        )
        .padding(.horizontal, 4)
    }
    
    // MARK: - Language Diversity Section
    
    @ViewBuilder
    private var languageDiversitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Language Diversity")
                    .font(LiquidGlassTheme.typography.headlineMedium)
                    .foregroundColor(theme.primaryText)
                    .liquidGlassVibrancy(.maximum)
                
                Spacer()
                
                Text("\(uniqueLanguages.count) languages")
                    .font(LiquidGlassTheme.typography.titleSmall)
                    .foregroundColor(theme.primary)
                    .liquidGlassVibrancy(.prominent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.regularMaterial.opacity(0.7))
                    .clipShape(Capsule())
            }
            
            // Language cloud visualization
            languageCloudVisualization
        }
        .liquidGlassCard(
            material: .regular,
            depth: .elevated,
            radius: .comfortable,
            vibrancy: .medium
        )
        .padding(.horizontal, 4)
    }
    
    // MARK: - Cultural Goals Section
    
    @ViewBuilder
    private var culturalGoalsSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cultural Reading Goals")
                        .font(LiquidGlassTheme.typography.headlineMedium)
                        .foregroundColor(theme.primaryText)
                        .liquidGlassVibrancy(.maximum)
                    
                    Text("Challenge yourself to read diverse voices")
                        .font(LiquidGlassTheme.typography.bodyMedium)
                        .foregroundColor(theme.secondaryText)
                        .liquidGlassVibrancy(.medium)
                }
                
                Spacer()
                
                Button("Set Goals") {
                    showingGoals = true
                }
                .liquidGlassButton(style: .primary)
            }
            
            // Current progress indicators
            VStack(spacing: 12) {
                goalProgressView(
                    title: "Read from 5 continents",
                    progress: min(1.0, Double(uniqueRegions.count) / 5.0),
                    current: uniqueRegions.count,
                    target: 5
                )
                
                goalProgressView(
                    title: "Discover 10 languages",
                    progress: min(1.0, Double(uniqueLanguages.count) / 10.0),
                    current: uniqueLanguages.count,
                    target: 10
                )
                
                goalProgressView(
                    title: "Explore diverse authors",
                    progress: diversityScore,
                    current: Int(diversityScore * 100),
                    target: 100,
                    suffix: "%"
                )
            }
        }
        .liquidGlassCard(
            material: .regular,
            depth: .elevated,
            radius: .comfortable,
            vibrancy: .medium
        )
        .padding(.horizontal, 4)
    }
    
    // MARK: - Reading Patterns Section
    
    @ViewBuilder
    private var readingPatternsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reading Patterns")
                .font(LiquidGlassTheme.typography.headlineMedium)
                .foregroundColor(theme.primaryText)
                .liquidGlassVibrancy(.maximum)
            
            // Cultural timeline chart
            culturalTimelineChart
                .frame(height: 180)
        }
        .liquidGlassCard(
            material: .regular,
            depth: .elevated,
            radius: .comfortable,
            vibrancy: .medium
        )
        .padding(.horizontal, 4)
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private var diversityScoreIndicator: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(theme.primary.opacity(0.3), lineWidth: 4)
                    .frame(width: 40, height: 40)
                
                Circle()
                    .trim(from: 0, to: animateVisualization ? diversityScore : 0)
                    .stroke(
                        AngularGradient(
                            colors: culturalGradientColors,
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                    .animation(
                        LiquidGlassTheme.FluidAnimation.flowing.springAnimation.delay(0.5),
                        value: animateVisualization
                    )
                
                Text("\(Int(diversityScore * 100))")
                    .font(LiquidGlassTheme.typography.labelMedium)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primary)
                    .liquidGlassVibrancy(.maximum)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Diversity Score")
                    .font(LiquidGlassTheme.typography.labelMedium)
                    .foregroundColor(theme.primaryText)
                    .liquidGlassVibrancy(.medium)
                
                Text("Keep exploring!")
                    .font(LiquidGlassTheme.typography.labelSmall)
                    .foregroundColor(theme.secondaryText)
                    .liquidGlassVibrancy(.subtle)
            }
        }
    }
    
    @ViewBuilder
    private var worldMapVisualization: some View {
        // Simplified world map with region indicators
        ZStack {
            // Background map shape (simplified)
            RoundedRectangle(cornerRadius: 12)
                .fill(.thinMaterial.opacity(0.5))
                .frame(height: 120)
                .overlay(
                    // Simulated world continents with cultural colors
                    HStack(spacing: 8) {
                        ForEach(CulturalRegion.allCases.prefix(6), id: \.self) { region in
                            regionMapIndicator(region: region)
                        }
                    }
                    .padding()
                )
        }
    }
    
    @ViewBuilder
    private func regionMapIndicator(region: CulturalRegion) -> some View {
        VStack(spacing: 4) {
            Circle()
                .fill(region.liquidGlassColor(theme: .crystalClear).adaptive)
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 2)
                )
                .scaleEffect(animateVisualization ? 1.0 : 0.5)
                .animation(
                    LiquidGlassTheme.FluidAnimation.smooth.springAnimation.delay(
                        Double(CulturalRegion.allCases.firstIndex(of: region) ?? 0) * 0.1
                    ),
                    value: animateVisualization
                )
            
            Text(region.emoji)
                .font(.caption2)
                .opacity(animateVisualization ? 1 : 0)
                .animation(
                    LiquidGlassTheme.FluidAnimation.smooth.springAnimation.delay(0.8),
                    value: animateVisualization
                )
        }
    }
    
    @ViewBuilder
    private var culturalPatternOverlay: some View {
        // Subtle pattern overlay inspired by world cultures
        Canvas { context, size in
            let pattern = createCulturalPattern(size: size)
            context.draw(pattern, at: CGPoint(x: size.width/2, y: size.height/2))
        }
    }
    
    @ViewBuilder
    private var languageCloudVisualization: some View {
        // Language tag cloud with varying sizes
        FlowLayout(spacing: 8) {
            ForEach(Array(languageData.enumerated()), id: \.offset) { index, language in
                Text(language.name)
                    .font(.system(size: fontSizeForLanguage(language), design: .rounded))
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(language.color.opacity(0.2))
                            .overlay(.ultraThinMaterial.opacity(0.5))
                    )
                    .foregroundColor(language.color)
                    .liquidGlassVibrancy(.medium)
                    .scaleEffect(animateVisualization ? 1.0 : 0.3)
                    .animation(
                        LiquidGlassTheme.FluidAnimation.smooth.springAnimation.delay(
                            Double(index) * 0.05
                        ),
                        value: animateVisualization
                    )
            }
        }
        .padding()
        .background(.thinMaterial.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var culturalTimelineChart: some View {
        Chart {
            ForEach(monthlyDiversityData, id: \.month) { data in
                ForEach(data.regions, id: \.region) { regionData in
                    AreaMark(
                        x: .value("Month", data.month),
                        yStart: .value("Start", regionData.stackStart),
                        yEnd: .value("End", regionData.stackEnd)
                    )
                    .foregroundStyle(regionData.region.liquidGlassColor(theme: .crystalClear).adaptive.opacity(0.8))
                    .opacity(animateVisualization ? 1 : 0)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine()
                    .foregroundStyle(theme.outline.opacity(0.2))
                AxisValueLabel()
                    .foregroundStyle(theme.secondaryText)
                    .font(LiquidGlassTheme.typography.labelSmall)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine()
                    .foregroundStyle(theme.outline.opacity(0.2))
                AxisValueLabel()
                    .foregroundStyle(theme.secondaryText)
                    .font(LiquidGlassTheme.typography.labelSmall)
            }
        }
        .animation(
            LiquidGlassTheme.FluidAnimation.flowing.springAnimation.delay(1.0),
            value: animateVisualization
        )
        .padding()
    }
    
    @ViewBuilder
    private func selectedRegionDetail(region: CulturalRegion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(region.emoji)
                    .font(.largeTitle)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(region.rawValue)
                        .font(LiquidGlassTheme.typography.titleLarge)
                        .foregroundColor(theme.primaryText)
                        .liquidGlassVibrancy(.maximum)
                    
                    Text("\(booksCount(for: region)) books from this region")
                        .font(LiquidGlassTheme.typography.bodyMedium)
                        .foregroundColor(theme.secondaryText)
                        .liquidGlassVibrancy(.medium)
                }
                
                Spacer()
            }
            
            if let recentBooks = recentBooks(from: region) {
                Text("Recent reads:")
                    .font(LiquidGlassTheme.typography.labelMedium)
                    .foregroundColor(theme.secondaryText)
                    .liquidGlassVibrancy(.medium)
                
                ForEach(recentBooks.prefix(3), id: \.id) { book in
                    HStack {
                        Text("•")
                            .foregroundColor(region.liquidGlassColor(theme: .crystalClear).adaptive)
                        
                        Text(book.metadata?.title ?? "Unknown")
                            .font(LiquidGlassTheme.typography.bodySmall)
                            .foregroundColor(theme.primaryText)
                            .liquidGlassVibrancy(.medium)
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private func goalProgressView(
        title: String,
        progress: Double,
        current: Int,
        target: Int,
        suffix: String = ""
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(LiquidGlassTheme.typography.bodyMedium)
                    .foregroundColor(theme.primaryText)
                    .liquidGlassVibrancy(.medium)
                
                Spacer()
                
                Text("\(current)\(suffix) / \(target)\(suffix)")
                    .font(LiquidGlassTheme.typography.labelMedium)
                    .foregroundColor(theme.primary)
                    .liquidGlassVibrancy(.prominent)
            }
            
            ProgressView(value: animateVisualization ? progress : 0)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(
                    LinearGradient(
                        colors: [theme.primary, theme.secondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .background(.regularMaterial.opacity(0.3))
                .clipShape(Capsule())
                .animation(
                    LiquidGlassTheme.FluidAnimation.flowing.springAnimation.delay(0.7),
                    value: animateVisualization
                )
        }
    }
    
    // MARK: - Helper Functions
    
    private func createCulturalPattern(size: CGSize) -> Image {
        // Create a simple cultural pattern
        let renderer = ImageRenderer(
            content: Rectangle()
                .fill(.clear)
                .frame(width: size.width, height: size.height)
        )
        return renderer.uiImage.map(Image.init) ?? Image(systemName: "globe")
    }
    
    private func fontSizeForLanguage(_ language: LanguageData) -> CGFloat {
        let baseSize: CGFloat = 12
        let maxSize: CGFloat = 20
        return baseSize + (maxSize - baseSize) * (Double(language.count) / Double(maxLanguageCount))
    }
    
    private func booksCount(for region: CulturalRegion) -> Int {
        allBooks.filter { $0.metadata?.culturalRegion == region }.count
    }
    
    private func recentBooks(from region: CulturalRegion) -> [UserBook]? {
        let books = allBooks.filter { $0.metadata?.culturalRegion == region }
        return books.isEmpty ? nil : Array(books.suffix(3))
    }
    
    // MARK: - Computed Properties
    
    private var uniqueRegions: Set<CulturalRegion> {
        Set(allBooks.compactMap { $0.metadata?.culturalRegion })
    }
    
    private var uniqueLanguages: Set<String> {
        Set(allBooks.compactMap { $0.metadata?.language })
    }
    
    private var diversityScore: Double {
        let regionScore = Double(uniqueRegions.count) / Double(CulturalRegion.allCases.count)
        let languageScore = min(1.0, Double(uniqueLanguages.count) / 10.0)
        return (regionScore + languageScore) / 2.0
    }
    
    private var culturalGradientColors: [Color] {
        CulturalRegion.allCases.map { region in
            region.liquidGlassColor(theme: .crystalClear).adaptive
        }
    }
    
    private var languageData: [LanguageData] {
        let languageCounts = Dictionary(grouping: allBooks.compactMap { $0.metadata?.language }) { $0 }
            .mapValues { $0.count }
        
        return languageCounts.map { language, count in
            LanguageData(
                name: language,
                count: count,
                color: Color.random
            )
        }
        .sorted { $0.count > $1.count }
    }
    
    private var maxLanguageCount: Int {
        languageData.map { $0.count }.max() ?? 1
    }
    
    private var monthlyDiversityData: [MonthlyDiversityData] {
        // Mock data for demonstration
        [
            MonthlyDiversityData(month: "Jan", regions: [
                RegionStackData(region: .europe, stackStart: 0, stackEnd: 2),
                RegionStackData(region: .asia, stackStart: 2, stackEnd: 3),
                RegionStackData(region: .northAmerica, stackStart: 3, stackEnd: 5)
            ]),
            MonthlyDiversityData(month: "Feb", regions: [
                RegionStackData(region: .europe, stackStart: 0, stackEnd: 1),
                RegionStackData(region: .asia, stackStart: 1, stackEnd: 3),
                RegionStackData(region: .africa, stackStart: 3, stackEnd: 4)
            ]),
            // Add more months...
        ]
    }
}

// MARK: - Supporting Views

struct RegionCard: View {
    let region: CulturalRegion
    let bookCount: Int
    let isSelected: Bool
    let onSelect: () -> Void
    
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                // Region emoji with enhanced styling
                ZStack {
                    Circle()
                        .fill(regionColor.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .overlay(.ultraThinMaterial.opacity(0.5))
                    
                    Text(region.emoji)
                        .font(.largeTitle)
                        .liquidGlassVibrancy(.prominent)
                }
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .shadow(
                    color: regionColor.opacity(isSelected ? 0.4 : 0.2),
                    radius: isSelected ? 12 : 6,
                    x: 0,
                    y: isSelected ? 6 : 3
                )
                
                VStack(spacing: 4) {
                    Text(region.shortName)
                        .font(LiquidGlassTheme.typography.titleSmall)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryText)
                        .liquidGlassVibrancy(.maximum)
                    
                    Text("\(bookCount) books")
                        .font(LiquidGlassTheme.typography.labelMedium)
                        .foregroundColor(regionColor)
                        .liquidGlassVibrancy(.prominent)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.regularMaterial.opacity(isSelected ? 0.8 : 0.5))
                    .stroke(
                        regionColor.opacity(isSelected ? 0.6 : 0.2),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(LiquidGlassTheme.FluidAnimation.smooth.springAnimation, value: isSelected)
    }
    
    private var regionColor: Color {
        region.liquidGlassColor(theme: .crystalClear).adaptive
    }
}



// MARK: - Data Models

struct LanguageData {
    let name: String
    let count: Int
    let color: Color
}

struct MonthlyDiversityData {
    let month: String
    let regions: [RegionStackData]
}

struct RegionStackData {
    let region: CulturalRegion
    let stackStart: Double
    let stackEnd: Double
}

// MARK: - Extensions

extension Color {
    static var random: Color {
        Color(
            red: Double.random(in: 0.3...0.8),
            green: Double.random(in: 0.3...0.8),
            blue: Double.random(in: 0.3...0.8)
        )
    }
}

extension CulturalRegion {
    var shortName: String {
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
        case .international: return "International"
        }
    }
}

#Preview {
    NavigationStack {
        CulturalDiversityView()
            .navigationTitle("Cultural Diversity")
            .navigationBarTitleDisplayMode(.large)
    }
    .modelContainer(for: [UserBook.self, BookMetadata.self], inMemory: true)
    .environment(\.appTheme, AppColorTheme(variant: .purpleBoho))
}