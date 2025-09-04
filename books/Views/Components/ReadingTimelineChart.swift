import SwiftUI
import Charts
import SwiftData
#if canImport(Accessibility)
import Accessibility
#endif

// MARK: - Simplified Interactive Reading Timeline Chart (iOS 26 Phase 2)
// Minimal working version to avoid compiler type-check timeout

struct ReadingTimelineChart: View {
    let timelineData: [TimelineDataPoint]
    @Environment(\.unifiedThemeStore) private var themeStore
    
    private var displayData: [TimelineDataPoint] {
        Array(timelineData.suffix(6))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Chart Header with iOS 26 styling
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reading Timeline")
                        .liquidGlassTypography(style: .title2, vibrancy: .prominent)
                        .foregroundColor(currentTheme.primaryText)
                    
                    Text("Monthly progress trends")
                        .liquidGlassTypography(style: .caption1, vibrancy: .medium)
                        .foregroundColor(currentTheme.secondaryText)
                }
                
                Spacer()
            }
            
            // Enhanced Dual Visualization Chart
            if displayData.isEmpty {
                chartEmptyState
            } else {
                Chart(displayData, id: \.id) { dataPoint in
                    // Reading Volume (Bar Chart)
                    BarMark(
                        x: .value("Month", dataPoint.date, unit: .month),
                        y: .value("Books", dataPoint.bookCount)
                    )
                    .foregroundStyle(currentTheme.primary.gradient)
                    .opacity(0.8)
                    
                    // Cultural Diversity (Line Chart Overlay)
                    LineMark(
                        x: .value("Month", dataPoint.date, unit: .month),
                        y: .value("Diversity %", dataPoint.diversityPercentage / 10.0) // Scale to match book count range
                    )
                    .foregroundStyle(currentTheme.secondary)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    // Diversity Points
                    PointMark(
                        x: .value("Month", dataPoint.date, unit: .month),
                        y: .value("Diversity %", dataPoint.diversityPercentage / 10.0)
                    )
                    .foregroundStyle(currentTheme.secondary)
                    .symbolSize(50)
                }
                .frame(height: 180)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                            .foregroundStyle(currentTheme.surface.opacity(0.3))
                        AxisValueLabel()
                            .foregroundStyle(currentTheme.secondaryText)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { _ in
                        AxisGridLine()
                            .foregroundStyle(currentTheme.surface.opacity(0.2))
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                            .foregroundStyle(currentTheme.secondaryText)
                    }
                }
                .chartLegend(position: .bottom, alignment: .center) {
                    HStack(spacing: 20) {
                        legendItem(color: currentTheme.primary, label: "Books Read")
                        legendItem(color: currentTheme.secondary, label: "Cultural Diversity")
                    }
                    .padding(.top, 12)
                }
                .accessibilityLabel(chartAccessibilityLabel)
                .accessibilityValue(chartAccessibilityValue)
                .optimizedLiquidGlassCard(
                    material: .ultraThin,
                    depth: .floating,
                    radius: .comfortable,
                    vibrancy: .subtle
                )
                .drawingGroup() // Performance optimization for complex chart rendering
            }
        }
        .optimizedLiquidGlassCard(
            material: .thin,
            depth: .elevated,
            radius: .comfortable,
            vibrancy: .medium
        )
        .padding(.horizontal, 4)
    }
    
    // MARK: - Empty State
    
    @ViewBuilder
    private var chartEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundStyle(currentTheme.primary.opacity(0.6))
            
            Text("Start Your Reading Journey")
                .liquidGlassTypography(style: .headline, vibrancy: .medium)
                .foregroundColor(currentTheme.primaryText)
            
            Text("Add books to see your progress timeline")
                .liquidGlassTypography(style: .callout, vibrancy: .subtle)
                .foregroundColor(currentTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Helper Methods
    
    @ViewBuilder
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(currentTheme.secondaryText)
        }
    }
    
    private var chartAccessibilityLabel: String {
        "Reading timeline chart showing monthly book count and cultural diversity trends"
    }
    
    private var chartAccessibilityValue: String {
        guard !displayData.isEmpty else { return "No reading data available" }
        
        let totalBooks = displayData.reduce(0) { $0 + $1.bookCount }
        let avgDiversity = displayData.reduce(0.0) { $0 + $1.diversityPercentage } / Double(displayData.count)
        
        return "Chart shows \(displayData.count) months of data. Total books: \(totalBooks). Average cultural diversity: \(String(format: "%.1f", avgDiversity)) percent."
    }
    
    
    private var currentTheme: AppColorTheme {
        themeStore.appTheme
    }
}

// MARK: - Timeline Data Structures

struct TimelineDataPoint: Identifiable, Sendable, Hashable {
    let id = UUID()
    let date: Date
    let bookCount: Int
    let diversityPercentage: Double
    let averageRating: Double?
    let genreBreakdown: [String: Int]
    let authorDemographics: AuthorDemographics
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

struct AuthorDemographics: Sendable, Hashable {
    let genderDistribution: [String: Int]
    let regionalDistribution: [String: Int] 
    let diversityScore: Double
}

// MARK: - Preview

#Preview {
    let sampleData = [
        TimelineDataPoint(
            date: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date(),
            bookCount: 4,
            diversityPercentage: 45.0,
            averageRating: 4.2,
            genreBreakdown: ["Fiction": 3, "Non-Fiction": 1],
            authorDemographics: AuthorDemographics(
                genderDistribution: ["Female": 2, "Male": 2],
                regionalDistribution: ["North America": 2, "Europe": 1, "Asia": 1],
                diversityScore: 0.45
            )
        )
    ]
    
    NavigationStack {
        ScrollView {
            ReadingTimelineChart(timelineData: sampleData)
                .padding()
        }
    }
    .environment(\.unifiedThemeStore, UnifiedThemeStore())
}