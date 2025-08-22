//
//  LibraryEnrichmentView.swift
//  books
//
//  UI for managing library metadata enrichment
//

import SwiftUI
import SwiftData

struct LibraryEnrichmentView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var enrichmentService: MetadataEnrichmentService
    @State private var enrichmentStats: EnrichmentStats?
    @State private var incompleteBooks: [EnrichmentCandidate] = []
    @State private var showingEnrichmentProgress = false
    @State private var selectedPriority: EnrichmentPriority = .high
    
    init(modelContext: ModelContext) {
        self._enrichmentService = StateObject(wrappedValue: MetadataEnrichmentService(modelContext: modelContext))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                headerSection
                statsSection
                
                if !incompleteBooks.isEmpty {
                    incompleteSection
                    prioritySection
                    enrichmentControls
                } else {
                    noIncompleteSection
                }
                
                if enrichmentService.isEnriching {
                    progressSection
                }
            }
            .padding(Theme.Spacing.md)
        }
        .navigationTitle("Library Enhancement")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            refreshData()
        }
        .sheet(isPresented: $showingEnrichmentProgress) {
            EnrichmentProgressView(enrichmentService: enrichmentService)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(theme.primary)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Enhance Your Library")
                        .titleLarge()
                        .foregroundColor(theme.primaryText)
                    
                    Text("Automatically fill missing book data like covers, descriptions, and publication details")
                        .bodyMedium()
                        .foregroundColor(theme.secondaryText)
                }
                
                Spacer()
            }
        }
        .padding(Theme.Spacing.md)
        .materialCard()
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Library Status")
                .headlineSmall()
                .foregroundColor(theme.primaryText)
            
            if let stats = enrichmentStats {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: Theme.Spacing.sm) {
                    LibraryStatCard(
                        icon: "books.vertical.fill",
                        title: "Total Books",
                        value: "\(stats.totalBooks)",
                        color: theme.primary
                    )
                    
                    LibraryStatCard(
                        icon: "exclamationmark.triangle.fill",
                        title: "Need Enhancement",
                        value: "\(stats.incompleteBooks)",
                        color: stats.incompleteBooks > 0 ? theme.warning : theme.success
                    )
                }
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: Theme.Spacing.sm) {
                    LibraryStatCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Average Quality",
                        value: "\(Int(stats.averageCompleteness * 100))%",
                        color: completenessColor(stats.averageCompleteness)
                    )
                    
                    LibraryStatCard(
                        icon: "clock.fill",
                        title: "Last Enhanced",
                        value: lastEnhancementText(stats.lastEnrichmentDate),
                        color: theme.secondary
                    )
                }
            } else {
                ProgressView("Loading stats...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(Theme.Spacing.lg)
            }
        }
    }
    
    // MARK: - Incomplete Books Section
    
    private var incompleteSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Text("Books Needing Enhancement")
                    .headlineSmall()
                    .foregroundColor(theme.primaryText)
                
                Spacer()
                
                Text("\(incompleteBooks.count) books")
                    .labelMedium()
                    .foregroundColor(theme.secondaryText)
            }
            
            // Show top incomplete books by priority
            LazyVStack(spacing: Theme.Spacing.sm) {
                ForEach(Array(incompleteBooks.prefix(5).enumerated()), id: \.offset) { index, candidate in
                    IncompleteBookRow(candidate: candidate)
                }
                
                if incompleteBooks.count > 5 {
                    NavigationLink(value: "library-incomplete-books") {
                        Text("View All \(incompleteBooks.count) Books")
                    }
                    .materialButton(style: .text)
                }
            }
        }
    }
    
    // MARK: - Priority Section
    
    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Enhancement Priority")
                .headlineSmall()
                .foregroundColor(theme.primaryText)
            
            Picker("Priority", selection: $selectedPriority) {
                ForEach(EnrichmentPriority.allCases, id: \.self) { priority in
                    Text(priority.description).tag(priority)
                }
            }
            .pickerStyle(.segmented)
            
            priorityDescription
        }
    }
    
    private var priorityDescription: some View {
        Group {
            switch selectedPriority {
            case .high:
                Text("Focus on books missing covers and descriptions - the most visible improvements")
                    .bodySmall()
                    .foregroundColor(theme.secondaryText)
            case .medium:
                Text("Enhance books missing publication details and page counts")
                    .bodySmall()
                    .foregroundColor(theme.secondaryText)
            case .low:
                Text("Complete remaining metadata like genres and languages")
                    .bodySmall()
                    .foregroundColor(theme.secondaryText)
            }
        }
    }
    
    // MARK: - Enhancement Controls
    
    private var enrichmentControls: some View {
        VStack(spacing: Theme.Spacing.md) {
            Button(action: startEnrichment) {
                HStack {
                    if enrichmentService.isEnriching {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "sparkles")
                    }
                    
                    Text(enrichmentService.isEnriching ? "Enhancing..." : "Start Enhancement")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .materialButton(style: .filled)
            .disabled(enrichmentService.isEnriching || filteredCandidates.isEmpty)
            
            if enrichmentService.isEnriching {
                Button("View Progress") {
                    showingEnrichmentProgress = true
                }
                .materialButton(style: .tonal)
                
                Button("Stop Enhancement") {
                    enrichmentService.stopEnrichment()
                }
                .materialButton(style: .outlined)
            }
            
            HStack {
                Text("Will enhance \(filteredCandidates.count) \(selectedPriority.description.lowercased()) priority books")
                    .bodySmall()
                    .foregroundColor(theme.secondaryText)
                
                Spacer()
            }
        }
    }
    
    // MARK: - No Incomplete Section
    
    private var noIncompleteSection: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(theme.success)
            
            Text("Library Fully Enhanced!")
                .headlineMedium()
                .foregroundColor(theme.primaryText)
            
            Text("All your books have complete metadata. Check back after adding new books or importing more data.")
                .bodyMedium()
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.xl)
        .materialCard()
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Enhancement in Progress")
                .headlineSmall()
                .foregroundColor(theme.primaryText)
            
            if let progress = enrichmentService.enrichmentProgress {
                EnrichmentProgressCard(progress: progress)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var filteredCandidates: [EnrichmentCandidate] {
        incompleteBooks.filter { $0.priority == selectedPriority }
    }
    
    private func refreshData() {
        enrichmentStats = enrichmentService.getEnrichmentStats()
        incompleteBooks = enrichmentService.identifyIncompleteBooks()
    }
    
    private func startEnrichment() {
        let candidates = filteredCandidates
        enrichmentService.startEnrichment(candidates: candidates)
        showingEnrichmentProgress = true
    }
    
    private func completenessColor(_ completeness: Double) -> Color {
        switch completeness {
        case 0.8...: return theme.success
        case 0.6..<0.8: return theme.warning
        default: return theme.error
        }
    }
    
    private func lastEnhancementText(_ date: Date?) -> String {
        guard let date = date else { return "Never" }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Supporting Views

struct LibraryStatCard: View {
    @Environment(\.appTheme) private var theme
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            
            Text(value)
                .titleMedium()
                .fontWeight(.bold)
                .foregroundColor(theme.primaryText)
            
            Text(title)
                .labelSmall()
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.md)
        .materialCard()
    }
}

struct IncompleteBookRow: View {
    @Environment(\.appTheme) private var theme
    let candidate: EnrichmentCandidate
    
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Book cover placeholder
            RoundedRectangle(cornerRadius: Theme.CornerRadius.small)
                .fill(theme.surfaceVariant)
                .frame(width: 40, height: 60)
                .overlay(
                    Image(systemName: "book.closed")
                        .foregroundColor(theme.onSurfaceVariant)
                        .font(.title3)
                )
            
            // Book info
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(candidate.book.metadata?.title ?? "Unknown Title")
                    .bodyMedium()
                    .fontWeight(.medium)
                    .foregroundColor(theme.primaryText)
                    .lineLimit(1)
                
                Text(candidate.book.metadata?.authors.joined(separator: ", ") ?? "Unknown Author")
                    .bodySmall()
                    .foregroundColor(theme.secondaryText)
                    .lineLimit(1)
                
                // Missing fields
                HStack(spacing: Theme.Spacing.xs) {
                    ForEach(Array(candidate.missingFields.prefix(3)), id: \.self) { field in
                        Text(field.displayName)
                            .labelSmall()
                            .padding(.horizontal, Theme.Spacing.xs)
                            .padding(.vertical, 2)
                            .background(priorityColor(candidate.priority).opacity(0.2))
                            .foregroundColor(priorityColor(candidate.priority))
                            .cornerRadius(Theme.CornerRadius.small)
                    }
                    
                    if candidate.missingFields.count > 3 {
                        Text("+\(candidate.missingFields.count - 3)")
                            .labelSmall()
                            .foregroundColor(theme.secondaryText)
                    }
                }
            }
            
            Spacer()
            
            // Priority indicator
            VStack {
                Circle()
                    .fill(priorityColor(candidate.priority))
                    .frame(width: 8, height: 8)
                
                Text("\(Int(candidate.completeness * 100))%")
                    .labelSmall()
                    .foregroundColor(theme.secondaryText)
            }
        }
        .padding(Theme.Spacing.sm)
        .background(theme.surface)
        .cornerRadius(Theme.CornerRadius.medium)
    }
    
    private func priorityColor(_ priority: EnrichmentPriority) -> Color {
        switch priority {
        case .high: return theme.error
        case .medium: return theme.warning
        case .low: return theme.primary
        }
    }
}

struct EnrichmentProgressCard: View {
    @Environment(\.appTheme) private var theme
    let progress: EnrichmentProgress
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Progress bar
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack {
                    Text("Progress")
                        .labelMedium()
                        .foregroundColor(theme.primaryText)
                    
                    Spacer()
                    
                    Text("\(progress.processedBooks) / \(progress.totalBooks)")
                        .labelSmall()
                        .foregroundColor(theme.secondaryText)
                }
                
                ProgressView(value: Double(progress.processedBooks), total: Double(progress.totalBooks))
                    .progressViewStyle(.linear)
                    .tint(theme.primary)
            }
            
            // Stats
            HStack {
                StatPill(
                    icon: "checkmark.circle.fill",
                    value: "\(progress.successfulEnrichments)",
                    label: "Enhanced",
                    color: theme.success
                )
                
                if progress.failedEnrichments > 0 {
                    StatPill(
                        icon: "xmark.circle.fill",
                        value: "\(progress.failedEnrichments)",
                        label: "Failed",
                        color: theme.error
                    )
                }
                
                Spacer()
                
                if progress.estimatedTimeRemaining > 0 {
                    Text("~\(Int(progress.estimatedTimeRemaining))s remaining")
                        .labelSmall()
                        .foregroundColor(theme.secondaryText)
                }
            }
        }
        .padding(Theme.Spacing.md)
        .materialCard()
    }
}

struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
            
            Text(value)
                .labelMedium()
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(label)
                .labelSmall()
                .foregroundColor(color.opacity(0.8))
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(color.opacity(0.1))
        .cornerRadius(Theme.CornerRadius.small)
    }
}

// MARK: - Incomplete Book List View

// MARK: - Enhanced Incomplete Books List with Virtual Scrolling

struct IncompleteBookListView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    
    @State private var analyzer: IncompleteBookAnalyzer? = nil
    @State private var searchText = ""
    @State private var selectedSeverity: DataCompletenessLevel = .all
    @State private var isInitialized = false
    
    private let pageSize = 50 // Virtual scrolling page size
    
    var body: some View {
        Group {
            if let analyzer = analyzer {
                if analyzer.isLoading && analyzer.incompleteBooks.isEmpty {
                    loadingView
                } else if let errorMessage = analyzer.errorMessage {
                    errorView(errorMessage)
                } else if analyzer.incompleteBooks.isEmpty {
                    emptyStateView
                } else {
                    contentView(analyzer)
                }
            } else {
                loadingView
            }
        }
        .navigationTitle("Incomplete Books")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await initializeAnalyzer()
        }
        .refreshable {
            await analyzer?.forceRefresh()
        }
        .searchable(text: $searchText, prompt: "Search books...")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                severityFilterMenu
            }
        }
    }
    
    // MARK: - Content Views
    
    @ViewBuilder
    private func contentView(_ analyzer: IncompleteBookAnalyzer) -> some View {
        let filteredBooks = filteredIncompleteBooks(analyzer)
        
        List {
            if analyzer.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Analyzing books...")
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            
            Section {
                ForEach(filteredBooks, id: \.id) { book in
                    NavigationLink(value: book) {
                        LiquidGlassBookRowView(
                            userBook: book,
                            analysisResult: analyzer.getAnalysisResult(for: book)
                        )
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }
            } header: {
                if !filteredBooks.isEmpty {
                    Text("\(filteredBooks.count) incomplete book\(filteredBooks.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(theme.secondaryText)
                        .textCase(.none)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Analyzing book completeness...")
                .font(.subheadline)
                .foregroundColor(theme.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
    }
    
    @ViewBuilder
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(theme.error)
            
            Text("Analysis Failed")
                .font(.headline)
                .foregroundColor(theme.primaryText)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                Task {
                    await analyzer?.forceRefresh()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(theme.background)
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(theme.primary)
            
            Text("All Books Complete!")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(theme.primaryText)
            
            Text("Your library has complete metadata for all books. Great job maintaining your collection!")
                .font(.subheadline)
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
    }
    
    @ViewBuilder
    private var severityFilterMenu: some View {
        Menu {
            ForEach(DataCompletenessLevel.allCases, id: \.rawValue) { level in
                Button {
                    selectedSeverity = level
                } label: {
                    HStack {
                        Text(level.rawValue)
                        if selectedSeverity == level {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease")
                .foregroundColor(theme.primary)
        }
    }
    
    // MARK: - Helper Methods
    
    private func initializeAnalyzer() async {
        if !isInitialized {
            analyzer = IncompleteBookAnalyzer(modelContext: modelContext)
            await analyzer?.analyzeIncompleteBooks()
            isInitialized = true
        }
    }
    
    private func filteredIncompleteBooks(_ analyzer: IncompleteBookAnalyzer) -> [UserBook] {
        let books = analyzer.getIncompleteBooks(severity: selectedSeverity)
        
        if searchText.isEmpty {
            return books
        }
        
        return books.filter { book in
            let title = book.metadata?.title ?? ""
            let authors = book.metadata?.authors.joined(separator: " ") ?? ""
            let searchableText = "\(title) \(authors)".lowercased()
            return searchableText.contains(searchText.lowercased())
        }
    }
    
    private func completionColor(_ score: Double) -> Color {
        switch score {
        case 0.8...: return theme.primary
        case 0.6..<0.8: return Color.orange
        case 0.4..<0.6: return Color.yellow
        default: return theme.error
        }
    }
    
    private func priorityColor(_ priority: AnalysisPriority) -> Color {
        switch priority {
        case .critical: return theme.error
        case .high: return Color.orange
        case .medium: return Color.yellow
        case .low: return theme.outline
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        LibraryEnrichmentView(modelContext: ModelContext(try! ModelContainer(for: UserBook.self, BookMetadata.self)))
            .environment(\.appTheme, AppColorTheme(variant: .purpleBoho))
    }
}