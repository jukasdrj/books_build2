import SwiftUI
import SwiftData
import Charts

// MARK: - Liquid Glass Stats View
// Enhanced reading statistics with translucent materials and fluid animations

struct LiquidGlassStatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTheme) private var theme
    @Query private var allBooks: [UserBook]
    
    @State private var animateCharts = false
    @State private var selectedTimeframe: StatsTimeframe = .allTime
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Hero stats section
                heroStatsSection
                
                // Reading progress charts
                readingProgressSection
                
                // Achievement gallery
                achievementSection
                
                // Detailed statistics
                detailedStatsSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(
            // Dynamic background with subtle animation
            LinearGradient(
                colors: [
                    theme.background.opacity(0.95),
                    theme.surface.opacity(0.8)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay(.ultraThinMaterial.opacity(0.3))
            .ignoresSafeArea()
        )
        .onAppear {
            withAnimation(LiquidGlassTheme.FluidAnimation.flowing.springAnimation.delay(0.2)) {
                animateCharts = true
            }
        }
    }
    
    // MARK: - Hero Stats Section
    
    @ViewBuilder
    private var heroStatsSection: some View {
        VStack(spacing: 16) {
            // Welcome message with personality
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Reading Journey")
                        .font(LiquidGlassTheme.typography.headlineMedium)
                        .foregroundColor(theme.primaryText)
                        .liquidGlassVibrancy(.maximum)
                    
                    Text("Track your progress and celebrate your achievements")
                        .font(LiquidGlassTheme.typography.bodyMedium)
                        .foregroundColor(theme.secondaryText)
                        .liquidGlassVibrancy(.medium)
                }
                
                Spacer()
                
                // Reading streak indicator
                readingStreakView
            }
            
            // Main stats grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                StatCard(
                    icon: "books.vertical.fill",
                    title: "Total Books",
                    value: "\(allBooks.filter { !$0.onWishlist }.count)",
                    subtitle: "in your library",
                    color: theme.primary,
                    material: .regular
                )
                
                StatCard(
                    icon: "checkmark.circle.fill",
                    title: "Books Read",
                    value: "\(completedBooksCount)",
                    subtitle: "completed",
                    color: theme.success,
                    material: .thick
                )
                
                StatCard(
                    icon: "book.fill",
                    title: "Currently Reading",
                    value: "\(currentlyReadingCount)",
                    subtitle: "in progress",
                    color: theme.secondary,
                    material: .regular
                )
                
                StatCard(
                    icon: "heart.fill",
                    title: "Want to Read",
                    value: "\(wishlistCount)",
                    subtitle: "on wishlist",
                    color: theme.error,
                    material: .thin
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
    
    // MARK: - Reading Progress Section
    
    @ViewBuilder
    private var readingProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Reading Progress")
                    .font(LiquidGlassTheme.typography.headlineSmall)
                    .foregroundColor(theme.primaryText)
                    .liquidGlassVibrancy(.maximum)
                
                Spacer()
                
                // Timeframe picker
                timeframePicker
            }
            
            // Progress chart with liquid glass styling
            readingProgressChart
                .frame(height: 200)
                .liquidGlassCard(
                    material: .thin,
                    depth: .floating,
                    radius: .comfortable,
                    vibrancy: .subtle
                )
        }
        .liquidGlassCard(
            material: .regular,
            depth: .elevated,
            radius: .comfortable,
            vibrancy: .medium
        )
        .padding(.horizontal, 4)
    }
    
    // MARK: - Achievement Section
    
    @ViewBuilder
    private var achievementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Reading Achievements")
                    .font(LiquidGlassTheme.typography.headlineSmall)
                    .foregroundColor(theme.primaryText)
                    .liquidGlassVibrancy(.maximum)
                
                Spacer()
                
                Image(systemName: "trophy.fill")
                    .font(.title3)
                    .foregroundColor(theme.warning)
                    .liquidGlassVibrancy(.prominent)
            }
            
            // Achievement grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                ForEach(achievements, id: \.title) { achievement in
                    AchievementView(achievement: achievement)
                }
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
    
    // MARK: - Detailed Stats Section
    
    @ViewBuilder
    private var detailedStatsSection: some View {
        VStack(spacing: 16) {
            // Reading status breakdown
            readingStatusSection
            
            // Goals section
            readingGoalsSection
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private var readingStreakView: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(theme.primary.opacity(0.3), lineWidth: 3)
                    .frame(width: 50, height: 50)
                
                Circle()
                    .trim(from: 0, to: animateCharts ? 0.7 : 0)
                    .stroke(
                        theme.primary,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                    .animation(
                        LiquidGlassTheme.FluidAnimation.flowing.springAnimation.delay(0.5),
                        value: animateCharts
                    )
                
                Text("7")
                    .font(LiquidGlassTheme.typography.titleMedium)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primary)
                    .liquidGlassVibrancy(.maximum)
            }
            
            Text("Day Streak")
                .font(LiquidGlassTheme.typography.labelSmall)
                .foregroundColor(theme.secondaryText)
                .liquidGlassVibrancy(.medium)
        }
        .liquidGlassCard(
            material: .thin,
            depth: .floating,
            radius: .compact,
            vibrancy: .subtle
        )
    }
    
    @ViewBuilder
    private var timeframePicker: some View {
        Picker("Timeframe", selection: $selectedTimeframe) {
            ForEach(StatsTimeframe.allCases, id: \.self) { timeframe in
                Text(timeframe.displayName)
                    .tag(timeframe)
            }
        }
        .pickerStyle(.segmented)
        .background(.regularMaterial.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .liquidGlassVibrancy(.medium)
    }
    
    @ViewBuilder
    private var readingProgressChart: some View {
        Chart {
            ForEach(progressData, id: \.month) { data in
                LineMark(
                    x: .value("Month", data.month),
                    y: .value("Books", animateCharts ? data.books : 0)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.primary, theme.secondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .lineStyle(.init(lineWidth: 3, lineCap: .round))
                
                AreaMark(
                    x: .value("Month", data.month),
                    y: .value("Books", animateCharts ? data.books : 0)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            theme.primary.opacity(0.3),
                            theme.secondary.opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine()
                    .foregroundStyle(theme.outline.opacity(0.2))
                AxisTick()
                    .foregroundStyle(theme.outline.opacity(0.3))
                AxisValueLabel()
                    .foregroundStyle(theme.secondaryText)
                    .font(LiquidGlassTheme.typography.labelSmall)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine()
                    .foregroundStyle(theme.outline.opacity(0.2))
                AxisTick()
                    .foregroundStyle(theme.outline.opacity(0.3))
                AxisValueLabel()
                    .foregroundStyle(theme.secondaryText)
                    .font(LiquidGlassTheme.typography.labelSmall)
            }
        }
        .animation(
            LiquidGlassTheme.FluidAnimation.flowing.springAnimation.delay(0.8),
            value: animateCharts
        )
        .padding()
    }
    
    @ViewBuilder
    private var readingStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Reading Status")
                .font(LiquidGlassTheme.typography.headlineSmall)
                .foregroundColor(theme.primaryText)
                .liquidGlassVibrancy(.maximum)
            
            VStack(spacing: 8) {
                ForEach(ReadingStatus.allCases, id: \.self) { status in
                    HStack {
                        Text(status.displayName)
                            .font(LiquidGlassTheme.typography.bodyMedium)
                            .foregroundColor(theme.primaryText)
                            .liquidGlassVibrancy(.medium)
                        
                        Spacer()
                        
                        Text("\(booksCount(for: status))")
                            .font(LiquidGlassTheme.typography.titleMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(status.color(theme: theme))
                            .liquidGlassVibrancy(.prominent)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.thinMaterial.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
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
    
    @ViewBuilder
    private var readingGoalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "target")
                    .font(.title2)
                    .foregroundColor(theme.warning)
                    .liquidGlassVibrancy(.prominent)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Set Reading Goals")
                        .font(LiquidGlassTheme.typography.headlineSmall)
                        .foregroundColor(theme.primaryText)
                        .liquidGlassVibrancy(.maximum)
                    
                    Text("Track daily and weekly reading progress")
                        .font(LiquidGlassTheme.typography.bodySmall)
                        .foregroundColor(theme.secondaryText)
                        .liquidGlassVibrancy(.medium)
                }
                
                Spacer()
                
                Button("Set Goals") {
                    // Goals action
                }
                .liquidGlassButton(style: .primary)
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
    
    // MARK: - Computed Properties
    
    private var completedBooksCount: Int {
        allBooks.filter { $0.readingStatus == .read }.count
    }
    
    private var currentlyReadingCount: Int {
        allBooks.filter { $0.readingStatus == .reading }.count
    }
    
    private var wishlistCount: Int {
        allBooks.filter { $0.onWishlist }.count
    }
    
    private var achievements: [Achievement] {
        [
            Achievement(
                title: "First Book",
                description: "Started your reading journey",
                icon: "star.fill",
                isUnlocked: completedBooksCount > 0,
                color: theme.warning
            ),
            Achievement(
                title: "Bookworm",
                description: "Read 10 books",
                icon: "books.vertical.fill",
                isUnlocked: completedBooksCount >= 10,
                color: theme.primary
            ),
            Achievement(
                title: "Explorer",
                description: "Read from 3 cultures",
                icon: "globe.americas.fill",
                isUnlocked: culturalRegionsCount >= 3,
                color: theme.secondary
            ),
            Achievement(
                title: "Diverse Reader",
                description: "Read 5 languages",
                icon: "text.bubble.fill",
                isUnlocked: languagesCount >= 5,
                color: theme.success
            )
        ]
    }
    
    private var culturalRegionsCount: Int {
        Set(allBooks.compactMap { $0.metadata?.culturalRegion }).count
    }
    
    private var languagesCount: Int {
        Set(allBooks.compactMap { $0.metadata?.language }).count
    }
    
    private var progressData: [MonthlyProgress] {
        // Mock data for demo - replace with real data
        [
            MonthlyProgress(month: "Jan", books: 3),
            MonthlyProgress(month: "Feb", books: 5),
            MonthlyProgress(month: "Mar", books: 2),
            MonthlyProgress(month: "Apr", books: 7),
            MonthlyProgress(month: "May", books: 4),
            MonthlyProgress(month: "Jun", books: 6)
        ]
    }
    
    private func booksCount(for status: ReadingStatus) -> Int {
        allBooks.filter { $0.readingStatus == status }.count
    }
}

// MARK: - Supporting Views and Models

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let material: LiquidGlassTheme.GlassMaterial
    
    @Environment(\.appTheme) private var theme
    @State private var isAnimated = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon with enhanced styling
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(.ultraThinMaterial.opacity(0.5))
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .liquidGlassVibrancy(.prominent)
            }
            .scaleEffect(isAnimated ? 1.0 : 0.8)
            .animation(
                LiquidGlassTheme.FluidAnimation.smooth.springAnimation.delay(0.3),
                value: isAnimated
            )
            
            VStack(spacing: 4) {
                // Value with counting animation
                Text(value)
                    .font(LiquidGlassTheme.typography.displaySmall)
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryText)
                    .liquidGlassVibrancy(.maximum)
                    .contentTransition(.numericText())
                
                Text(title)
                    .font(LiquidGlassTheme.typography.titleSmall)
                    .foregroundColor(color)
                    .liquidGlassVibrancy(.prominent)
                
                Text(subtitle)
                    .font(LiquidGlassTheme.typography.bodySmall)
                    .foregroundColor(theme.secondaryText)
                    .liquidGlassVibrancy(.medium)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .padding(.horizontal, 12)
        .background(material.material.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(
            color: color.opacity(0.2),
            radius: 8,
            x: 0,
            y: 4
        )
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                isAnimated = true
            }
        }
    }
}

struct AchievementView: View {
    let achievement: Achievement
    @State private var showingDetail = false
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? achievement.color.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .overlay(.ultraThinMaterial.opacity(0.3))
                
                Image(systemName: achievement.icon)
                    .font(.title3)
                    .foregroundColor(achievement.isUnlocked ? achievement.color : .gray)
                    .liquidGlassVibrancy(achievement.isUnlocked ? .prominent : .subtle)
                
                if !achievement.isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .offset(x: 15, y: -15)
                }
            }
            
            Text(achievement.title)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(achievement.isUnlocked ? .primary : .gray)
                .liquidGlassVibrancy(achievement.isUnlocked ? .medium : .subtle)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(.thinMaterial.opacity(achievement.isUnlocked ? 0.5 : 0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            showingDetail = true
        }
        .popover(isPresented: $showingDetail) {
            AchievementDetailView(achievement: achievement)
        }
    }
}

struct AchievementDetailView: View {
    let achievement: Achievement
    @Environment(\.appTheme) private var theme
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: achievement.icon)
                .font(.largeTitle)
                .foregroundColor(achievement.color)
                .liquidGlassVibrancy(.maximum)
            
            Text(achievement.title)
                .font(LiquidGlassTheme.typography.headlineSmall)
                .foregroundColor(theme.primaryText)
                .liquidGlassVibrancy(.maximum)
            
            Text(achievement.description)
                .font(LiquidGlassTheme.typography.bodyMedium)
                .foregroundColor(theme.secondaryText)
                .liquidGlassVibrancy(.medium)
                .multilineTextAlignment(.center)
            
            if achievement.isUnlocked {
                Text("🎉 Unlocked!")
                    .font(LiquidGlassTheme.typography.titleMedium)
                    .foregroundColor(achievement.color)
                    .liquidGlassVibrancy(.prominent)
            } else {
                Text("Keep reading to unlock!")
                    .font(LiquidGlassTheme.typography.bodySmall)
                    .foregroundColor(.gray)
                    .liquidGlassVibrancy(.subtle)
            }
        }
        .padding(24)
        .liquidGlassCard(
            material: .regular,
            depth: .prominent,
            radius: .comfortable,
            vibrancy: .medium
        )
        .frame(maxWidth: 280)
    }
}

// MARK: - Data Models

enum StatsTimeframe: CaseIterable {
    case thisWeek, thisMonth, thisYear, allTime
    
    var displayName: String {
        switch self {
        case .thisWeek: return "Week"
        case .thisMonth: return "Month"
        case .thisYear: return "Year"
        case .allTime: return "All Time"
        }
    }
}

struct Achievement {
    let title: String
    let description: String
    let icon: String
    let isUnlocked: Bool
    let color: Color
}

struct MonthlyProgress {
    let month: String
    let books: Int
}

#Preview {
    NavigationStack {
        LiquidGlassStatsView()
            .navigationTitle("Reading Stats")
            .navigationBarTitleDisplayMode(.large)
    }
    .modelContainer(for: [UserBook.self, BookMetadata.self], inMemory: true)
    .environment(\.appTheme, AppColorTheme(variant: .purpleBoho))
}