//
//  LibraryEnhancementView.swift
//  books
//
//  Phase 3: Data source intelligence - Library enhancement with actionable insights
//

import SwiftUI
import SwiftData

struct LibraryEnhancementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    @Query private var allBooks: [UserBook]
    
    @State private var showingBookDetails = false
    @State private var selectedPromptType: UserInputPrompt?
    @State private var booksForPromptType: [UserBook] = []
    @State private var showingOnboarding = false
    
    private var qualityReport: LibraryQualityReport {
        DataCompletenessService.analyzeLibraryQuality(allBooks)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.lg) {
                    // Hero Section
                    heroSection
                    
                    // Quick Metrics Grid
                    metricsGrid
                    
                    // Recommendations List
                    recommendationsSection
                    
                    // Data Source Breakdown
                    dataSourceBreakdown
                    
                    // Quality Insights
                    qualityInsights
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.bottom, Theme.Spacing.xl)
            }
            .navigationTitle("Library Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .materialButton(style: .text)
                }
            }
        }
        .sheet(isPresented: $showingBookDetails) {
            if let promptType = selectedPromptType {
                BooksForPromptView(
                    promptType: promptType,
                    books: booksForPromptType
                )
            }
        }
        .sheet(isPresented: $showingOnboarding) {
            DataQualityOnboardingView {
                UserDefaults.standard.hasSeenDataQualityOnboarding = true
            }
        }
        .onAppear {
            if !UserDefaults.standard.hasSeenDataQualityOnboarding {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showingOnboarding = true
                }
            }
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Icon and title
            HStack {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [theme.primary.opacity(0.2), theme.secondary.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [theme.primary, theme.secondary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .shadow(color: theme.primary.opacity(0.15), radius: 8, x: 0, y: 4)
                
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Library Health")
                        .titleLarge()
                        .foregroundColor(theme.primaryText)
                    
                    Text("Data quality and enhancement opportunities")
                        .bodyMedium()
                        .foregroundColor(theme.secondaryText)
                }
                
                Spacer()
            }
            
            // Overall completeness indicator
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Text("Overall Completeness")
                        .labelLarge()
                        .foregroundColor(theme.primaryText)
                    
                    Spacer()
                    
                    Text("\(Int(qualityReport.overallCompleteness * 100))%")
                        .titleMedium()
                        .fontWeight(.bold)
                        .foregroundColor(completenessColor)
                }
                
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(theme.outline.opacity(0.2))
                            .frame(height: 8)
                            .cornerRadius(4)
                        
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [completenessColor, completenessColor.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * qualityReport.overallCompleteness, height: 8)
                            .cornerRadius(4)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(Theme.Spacing.lg)
        .materialCard(elevation: Theme.Elevation.level2)
    }
    
    // MARK: - Metrics Grid
    
    private var metricsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: Theme.Spacing.md) {
            MetricCard(
                title: "Books Analyzed",
                value: "\(allBooks.count)",
                icon: "books.vertical.fill",
                color: theme.primary,
                trend: nil
            )
            
            MetricCard(
                title: "Need Attention",
                value: "\(qualityReport.booksNeedingAttention)",
                icon: "exclamationmark.triangle.fill",
                color: theme.warning,
                trend: qualityReport.booksNeedingAttention > 0 ? .attention : .good
            )
            
            MetricCard(
                title: "With Ratings",
                value: "\(qualityReport.qualityMetrics.booksWithRatings)",
                icon: "star.fill",
                color: theme.accentHighlight,
                trend: qualityReport.qualityMetrics.booksWithRatings > (allBooks.count / 2) ? .good : .improvement
            )
            
            MetricCard(
                title: "Cultural Data",
                value: "\(qualityReport.qualityMetrics.booksWithCulturalData)",
                icon: "globe.americas.fill",
                color: theme.secondary,
                trend: qualityReport.qualityMetrics.booksWithCulturalData > (allBooks.count / 3) ? .good : .improvement
            )
        }
    }
    
    // MARK: - Recommendations Section
    
    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("Smart Recommendations")
                    .titleMedium()
                    .foregroundColor(theme.primaryText)
                
                Spacer()
                
                Image(systemName: "sparkles")
                    .foregroundColor(theme.primary)
                    .font(.title3)
            }
            
            if qualityReport.recommendations.isEmpty {
                excellentLibraryState
            } else {
                LazyVStack(spacing: Theme.Spacing.sm) {
                    ForEach(qualityReport.recommendations.prefix(6), id: \.type) { recommendation in
                        RecommendationCard(recommendation: recommendation) {
                            handleRecommendationTap(recommendation)
                        }
                    }
                }
            }
        }
        .padding(Theme.Spacing.md)
        .materialCard()
    }
    
    private var excellentLibraryState: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(theme.success)
            
            VStack(spacing: Theme.Spacing.xs) {
                Text("Excellent Library Health!")
                    .titleMedium()
                    .foregroundColor(theme.primaryText)
                
                Text("Your library is well-maintained with complete data and good organization.")
                    .bodyMedium()
                    .foregroundColor(theme.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.lg)
        .background(theme.success.opacity(0.1))
        .cornerRadius(Theme.CornerRadius.medium)
    }
    
    // MARK: - Data Source Breakdown
    
    private var dataSourceBreakdown: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Data Sources")
                .titleMedium()
                .foregroundColor(theme.primaryText)
            
            VStack(spacing: Theme.Spacing.sm) {
                ForEach(Array(qualityReport.dataSourceBreakdown.sorted(by: { $0.value > $1.value })), id: \.key) { source, count in
                    DataSourceRow(
                        source: source,
                        count: count,
                        total: allBooks.count,
                        theme: theme
                    )
                }
            }
        }
        .padding(Theme.Spacing.md)
        .materialCard()
    }
    
    // MARK: - Quality Insights
    
    private var qualityInsights: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Quality Insights")
                .titleMedium()
                .foregroundColor(theme.primaryText)
            
            VStack(spacing: Theme.Spacing.sm) {
                QualityInsightRow(
                    icon: "chart.pie.fill",
                    title: "Book Data Completeness",
                    value: "\(Int(qualityReport.qualityMetrics.averageBookCompleteness * 100))%",
                    color: theme.primary
                )
                
                QualityInsightRow(
                    icon: "person.fill",
                    title: "User Data Completeness",
                    value: "\(Int(qualityReport.qualityMetrics.averageUserCompleteness * 100))%",
                    color: theme.secondary
                )
                
                if qualityReport.qualityMetrics.booksNeedingValidation > 0 {
                    QualityInsightRow(
                        icon: "checkmark.shield.fill",
                        title: "Need Validation",
                        value: "\(qualityReport.qualityMetrics.booksNeedingValidation)",
                        color: theme.warning
                    )
                }
            }
        }
        .padding(Theme.Spacing.md)
        .materialCard()
    }
    
    // MARK: - Helper Properties
    
    private var completenessColor: Color {
        switch qualityReport.overallCompleteness {
        case 0.8...:
            return theme.success
        case 0.6..<0.8:
            return theme.warning
        default:
            return theme.error
        }
    }
    
    // MARK: - Actions
    
    private func handleRecommendationTap(_ recommendation: LibraryRecommendation) {
        let books = getBooksForRecommendation(recommendation)
        
        switch recommendation.type {
        case .addRatings:
            selectedPromptType = .addPersonalRating
        case .addNotes:
            selectedPromptType = .addPersonalNotes
        case .validateImports:
            selectedPromptType = .validateImportedData
        case .completeCulturalData:
            selectedPromptType = .reviewCulturalData
        case .updateProgress:
            selectedPromptType = .updateReadingProgress
        case .addTags:
            selectedPromptType = .addTags
        }
        
        booksForPromptType = books
        showingBookDetails = true
    }
    
    private func getBooksForRecommendation(_ recommendation: LibraryRecommendation) -> [UserBook] {
        switch recommendation.type {
        case .addRatings:
            return allBooks.filter { $0.rating == nil && $0.readingStatus == .read }
        case .addNotes:
            return allBooks.filter { ($0.notes == nil || $0.notes!.isEmpty) && $0.readingStatus != .toRead }
        case .validateImports:
            return allBooks.filter { $0.metadata?.dataSource == .csvImport && ($0.metadata?.dataQualityScore ?? 1.0) < 0.9 }
        case .completeCulturalData:
            return allBooks.filter { $0.metadata?.culturalRegion == nil || $0.metadata?.authorGender == nil }
        case .updateProgress:
            return allBooks.filter { $0.readingStatus == .reading && $0.readingProgress == 0.0 }
        case .addTags:
            return allBooks.filter { $0.tags.isEmpty && $0.readingStatus != .toRead }
        }
    }
}

// MARK: - Supporting Views

struct MetricCard: View {
    @Environment(\.appTheme) private var theme
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: MetricTrend?
    
    enum MetricTrend {
        case good, improvement, attention
        
        var icon: String {
            switch self {
            case .good: return "checkmark.circle.fill"
            case .improvement: return "arrow.up.circle.fill"
            case .attention: return "exclamationmark.triangle.fill"
            }
        }
        
        func color(theme: AppColorTheme) -> Color {
            switch self {
            case .good: return theme.success
            case .improvement: return theme.warning
            case .attention: return theme.error
            }
        }
    }
    
    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
                
                if let trend = trend {
                    Image(systemName: trend.icon)
                        .foregroundColor(trend.color(theme: theme))
                        .font(.caption)
                }
            }
            
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(value)
                    .titleLarge()
                    .fontWeight(.bold)
                    .foregroundColor(theme.primaryText)
                
                Text(title)
                    .labelMedium()
                    .foregroundColor(theme.secondaryText)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Theme.Spacing.md)
        .materialCard()
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.card)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct RecommendationCard: View {
    @Environment(\.appTheme) private var theme
    let recommendation: LibraryRecommendation
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.md) {
                // Priority indicator
                Rectangle()
                    .fill(priorityColor)
                    .frame(width: 4)
                    .cornerRadius(2)
                
                // Icon
                Image(systemName: recommendationIcon)
                    .foregroundColor(priorityColor)
                    .font(.title3)
                    .frame(width: 24)
                
                // Content
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    HStack {
                        Text(recommendation.title)
                            .bodyMedium()
                            .fontWeight(.medium)
                            .foregroundColor(theme.primaryText)
                        
                        Spacer()
                        
                        Text("\(recommendation.actionCount)")
                            .labelLarge()
                            .fontWeight(.bold)
                            .foregroundColor(priorityColor)
                    }
                    
                    Text(recommendation.description)
                        .labelMedium()
                        .foregroundColor(theme.secondaryText)
                        .multilineTextAlignment(.leading)
                }
                
                // Action indicator
                Image(systemName: "chevron.right")
                    .foregroundColor(theme.outline)
                    .font(.caption)
            }
            .padding(Theme.Spacing.md)
            .background(theme.surface)
            .cornerRadius(Theme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(priorityColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .materialInteractive()
    }
    
    private var priorityColor: Color {
        switch recommendation.priority {
        case .high: return theme.error
        case .medium: return theme.warning
        case .low: return theme.outline
        }
    }
    
    private var recommendationIcon: String {
        switch recommendation.type {
        case .addRatings: return "star.fill"
        case .addNotes: return "note.text"
        case .validateImports: return "checkmark.shield.fill"
        case .completeCulturalData: return "globe.americas.fill"
        case .updateProgress: return "book.fill"
        case .addTags: return "tag.fill"
        }
    }
}

struct DataSourceRow: View {
    let source: DataSource
    let count: Int
    let total: Int
    let theme: AppColorTheme
    
    var body: some View {
        HStack {
            // Source icon and name
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: sourceIcon)
                    .foregroundColor(sourceColor)
                    .frame(width: 20)
                
                Text(sourceDisplayName)
                    .bodyMedium()
                    .foregroundColor(theme.primaryText)
            }
            
            Spacer()
            
            // Count and percentage
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(count)")
                    .labelMedium()
                    .fontWeight(.medium)
                    .foregroundColor(theme.primaryText)
                
                Text("\(Int(Double(count) / Double(total) * 100))%")
                    .labelSmall()
                    .foregroundColor(theme.secondaryText)
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
    
    private var sourceIcon: String {
        switch source {
        case .googleBooksAPI: return "cloud.fill"
        case .userInput: return "person.fill"
        case .manualEntry: return "hand.point.up.braille.fill"
        case .csvImport: return "doc.text.fill"
        case .mixedSources: return "rectangle.3.group.fill"
        }
    }
    
    private var sourceColor: Color {
        switch source {
        case .googleBooksAPI: return theme.primary
        case .userInput: return theme.secondary
        case .manualEntry: return theme.tertiary
        case .csvImport: return theme.warning
        case .mixedSources: return theme.outline
        }
    }
    
    private var sourceDisplayName: String {
        switch source {
        case .googleBooksAPI: return "Google Books API"
        case .userInput: return "User Input"
        case .manualEntry: return "Manual Entry"
        case .csvImport: return "CSV Import"
        case .mixedSources: return "Mixed Sources"
        }
    }
}

struct QualityInsightRow: View {
    @Environment(\.appTheme) private var theme
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .bodyMedium()
                .foregroundColor(theme.primaryText)
            
            Spacer()
            
            Text(value)
                .labelLarge()
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}

// MARK: - Books for Prompt View

struct BooksForPromptView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme
    let promptType: UserInputPrompt
    let books: [UserBook]
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(books, id: \.id) { book in
                        BookRowForPrompt(book: book, promptType: promptType)
                    }
                } header: {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text(promptType.displayText)
                            .titleMedium()
                        
                        Text("\(books.count) books need attention")
                            .labelMedium()
                            .foregroundColor(theme.secondaryText)
                    }
                    .padding(.vertical, Theme.Spacing.sm)
                }
            }
            .navigationTitle("Action Required")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .navigationDestination(for: UserBook.self) { book in
            BookDetailsView(book: book)
        }
    }
}

struct BookRowForPrompt: View {
    @Environment(\.appTheme) private var theme
    let book: UserBook
    let promptType: UserInputPrompt
    
    var body: some View {
        NavigationLink(value: book) {
            HStack(spacing: Theme.Spacing.md) {
                BookCoverImage(
                    imageURL: book.metadata?.imageURL?.absoluteString,
                    width: 50,
                    height: 75
                )
                
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(book.metadata?.title ?? "Unknown Title")
                        .bodyMedium()
                        .fontWeight(.medium)
                        .foregroundColor(theme.primaryText)
                        .lineLimit(2)
                    
                    Text(book.metadata?.authors.joined(separator: ", ") ?? "Unknown Author")
                        .labelMedium()
                        .foregroundColor(theme.secondaryText)
                        .lineLimit(1)
                    
                    // Show specific prompt context
                    Text(promptContextText)
                        .labelSmall()
                        .foregroundColor(theme.warning)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(theme.outline)
                    .font(.caption)
            }
        }
    }
    
    private var promptContextText: String {
        switch promptType {
        case .addPersonalRating:
            return "No rating added"
        case .addPersonalNotes:
            return "No notes added"
        case .reviewCulturalData:
            return "Missing cultural info"
        case .validateImportedData:
            return "Import validation needed"
        case .addTags:
            return "No tags added"
        case .updateReadingProgress:
            return "Progress not updated"
        case .confirmBookDetails:
            return "Details need confirmation"
        }
    }
}

#Preview {
    LibraryEnhancementView()
        .modelContainer(for: [UserBook.self, BookMetadata.self], inMemory: true)
}