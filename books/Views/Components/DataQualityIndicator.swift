//
//  DataQualityIndicator.swift
//  books
//
//  Data quality indicators for CSV import preview
//  Shows validation results and quality scores
//

import SwiftUI

/// Data quality indicator for import preview
struct DataQualityIndicator: View {
    @Environment(\.appTheme) private var theme
    let session: CSVImportSession
    
    private var qualityAnalysis: DataQualityAnalysis {
        analyzeDataQuality(session)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(qualityColor)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Data Quality Analysis")
                        .titleMedium()
                        .foregroundColor(theme.primaryText)
                    
                    Text(qualityDescription)
                        .bodyMedium()
                        .foregroundColor(theme.secondaryText)
                }
                
                Spacer()
                
                // Overall score badge
                QualityScoreBadge(score: qualityAnalysis.overallScore)
            }
            
            // Quality metrics
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Theme.Spacing.sm) {
                QualityMetricCard(
                    title: "ISBN Quality",
                    score: qualityAnalysis.isbnQuality,
                    icon: "number.circle.fill"
                )
                
                QualityMetricCard(
                    title: "Title Quality", 
                    score: qualityAnalysis.titleQuality,
                    icon: "text.book.closed.fill"
                )
                
                QualityMetricCard(
                    title: "Author Quality",
                    score: qualityAnalysis.authorQuality,
                    icon: "person.fill"
                )
                
                QualityMetricCard(
                    title: "Date Quality",
                    score: qualityAnalysis.dateQuality,
                    icon: "calendar.circle.fill"
                )
                
                QualityMetricCard(
                    title: "Completeness",
                    score: qualityAnalysis.completeness,
                    icon: "chart.pie.fill"
                )
                
                QualityMetricCard(
                    title: "Consistency",
                    score: qualityAnalysis.consistency,
                    icon: "checkmark.circle.fill"
                )
            }
            
            // Issues summary (if any)
            if !qualityAnalysis.commonIssues.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Common Issues Detected")
                        .labelLarge()
                        .foregroundColor(theme.primaryText)
                    
                    ForEach(qualityAnalysis.commonIssues.prefix(3), id: \.self) { issue in
                        HStack(spacing: Theme.Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(theme.warning)
                                .font(.caption)
                            
                            Text(issue)
                                .labelMedium()
                                .foregroundColor(theme.secondaryText)
                            
                            Spacer()
                        }
                    }
                    
                    if qualityAnalysis.commonIssues.count > 3 {
                        Text("+ \\(qualityAnalysis.commonIssues.count - 3) more issues")
                            .labelSmall()
                            .foregroundColor(theme.secondaryText)
                            .padding(.leading, 20)
                    }
                }
            }
        }
        .padding(Theme.Spacing.md)
        .materialCard()
    }
    
    private var qualityColor: Color {
        switch qualityAnalysis.overallScore {
        case 0.8...:
            return theme.success
        case 0.6..<0.8:
            return theme.warning
        default:
            return theme.error
        }
    }
    
    private var qualityDescription: String {
        switch qualityAnalysis.overallScore {
        case 0.9...:
            return "Excellent data quality - ready for import"
        case 0.8..<0.9:
            return "Good data quality - minor issues will be auto-corrected"
        case 0.6..<0.8:
            return "Fair data quality - some issues may affect matching"
        case 0.4..<0.6:
            return "Poor data quality - manual review recommended"
        default:
            return "Very poor data quality - significant issues detected"
        }
    }
}

/// Individual quality metric card
struct QualityMetricCard: View {
    @Environment(\.appTheme) private var theme
    let title: String
    let score: Double
    let icon: String
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Image(systemName: icon)
                .foregroundColor(scoreColor)
                .font(.title3)
            
            Text(title)
                .labelSmall()
                .foregroundColor(theme.primaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            Text("\(Int(score * 100))%")
                .labelMedium()
                .fontWeight(.semibold)
                .foregroundColor(scoreColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.sm)
        .background(scoreColor.opacity(0.1))
        .cornerRadius(Theme.CornerRadius.small)
    }
    
    private var scoreColor: Color {
        switch score {
        case 0.8...:
            return theme.success
        case 0.6..<0.8:
            return theme.warning
        default:
            return theme.error
        }
    }
}

/// Quality score badge
struct QualityScoreBadge: View {
    @Environment(\.appTheme) private var theme
    let score: Double
    
    var body: some View {
        Text("\\(Int(score * 100))%")
            .labelLarge()
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(scoreColor)
            .cornerRadius(Theme.CornerRadius.small)
    }
    
    private var scoreColor: Color {
        switch score {
        case 0.8...:
            return theme.success
        case 0.6..<0.8:
            return theme.warning
        default:
            return theme.error
        }
    }
}

// MARK: - Data Analysis

struct DataQualityAnalysis {
    let overallScore: Double
    let isbnQuality: Double
    let titleQuality: Double
    let authorQuality: Double
    let dateQuality: Double
    let completeness: Double
    let consistency: Double
    let commonIssues: [String]
}

private func analyzeDataQuality(_ session: CSVImportSession) -> DataQualityAnalysis {
    // Parse sample books for quality analysis
    let parser = CSVParser()
    let sampleBooks = parser.parseBooks(from: session, columnMappings: [:]).prefix(min(20, session.totalRows))
    
    var isbnScores: [Double] = []
    var titleScores: [Double] = []
    var authorScores: [Double] = []
    var dateScores: [Double] = []
    var completenessScores: [Double] = []
    var allIssues: [String] = []
    
    for book in sampleBooks {
        // Analyze each field
        if let isbn = book.isbn {
            let result = DataValidationService.validateISBN(isbn)
            isbnScores.append(result.confidence)
            allIssues.append(contentsOf: result.issues.map { $0.description })
        }
        
        if let title = book.title {
            let result = DataValidationService.validateTitle(title)
            titleScores.append(result.confidence)
            allIssues.append(contentsOf: result.issues.map { $0.description })
        }
        
        if let author = book.author {
            let result = DataValidationService.validateAuthor(author)
            authorScores.append(result.confidence)
            allIssues.append(contentsOf: result.issues.map { $0.description })
        }
        
        // Calculate completeness (fields present)
        let fieldsPresent = [
            book.title != nil,
            book.author != nil,
            book.isbn != nil,
            book.publisher != nil,
            book.dateRead != nil
        ].compactMap { $0 ? 1.0 : 0.0 }
        
        completenessScores.append(Double(fieldsPresent.count) / 5.0)
    }
    
    // Calculate averages
    let avgISBN = isbnScores.isEmpty ? 1.0 : isbnScores.reduce(0, +) / Double(isbnScores.count)
    let avgTitle = titleScores.isEmpty ? 1.0 : titleScores.reduce(0, +) / Double(titleScores.count)
    let avgAuthor = authorScores.isEmpty ? 1.0 : authorScores.reduce(0, +) / Double(authorScores.count)
    let avgDate = 0.8 // Placeholder for date quality
    let avgCompleteness = completenessScores.isEmpty ? 0.5 : completenessScores.reduce(0, +) / Double(completenessScores.count)
    let avgConsistency = 0.9 // Placeholder for consistency analysis
    
    // Overall score (weighted average)
    let overallScore = (avgISBN * 0.25 + avgTitle * 0.2 + avgAuthor * 0.2 + avgDate * 0.1 + avgCompleteness * 0.15 + avgConsistency * 0.1)
    
    // Get most common issues
    let issueCounts = Dictionary(grouping: allIssues, by: { $0 }).mapValues { $0.count }
    let commonIssues = issueCounts.sorted { $0.value > $1.value }.prefix(5).map { $0.key }
    
    return DataQualityAnalysis(
        overallScore: overallScore,
        isbnQuality: avgISBN,
        titleQuality: avgTitle,
        authorQuality: avgAuthor,
        dateQuality: avgDate,
        completeness: avgCompleteness,
        consistency: avgConsistency,
        commonIssues: Array(commonIssues)
    )
}

#Preview {
    // Create mock session for preview
    let mockColumns = [
        CSVColumn(originalName: "Title", index: 0, mappedField: .title, sampleValues: ["Sample Book", "Another Title"]),
        CSVColumn(originalName: "Author", index: 1, mappedField: .author, sampleValues: ["John Doe", "Jane Smith"]),
        CSVColumn(originalName: "ISBN", index: 2, mappedField: .isbn, sampleValues: ["9781234567890", "invalid-isbn"])
    ]
    
    let mockSession = CSVImportSession(
        fileName: "goodreads_library_export.csv",
        fileSize: 1024,
        totalRows: 100,
        detectedColumns: mockColumns,
        sampleData: [["Title", "Author", "ISBN"], ["Sample Book", "John Doe", "9781234567890"]],
        allData: []
    )
    
    return DataQualityIndicator(session: mockSession)
        .padding()
}