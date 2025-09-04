//
//  DataCompletenessIndicator.swift
//  books
//
//  Data completeness indicator for book cards and views
//  Using iOS 26 Liquid Glass design system
//

import SwiftUI
import SwiftData

struct DataCompletenessIndicator: View {
    let book: UserBook
    
    @Environment(\.appTheme) private var theme
    
    private var completenessScore: Double {
        DataCompletenessService.calculateBookCompleteness(book)
    }
    
    private var indicatorColor: Color {
        if completenessScore >= 0.8 {
            return .green
        } else if completenessScore >= 0.5 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var completenessIcon: String {
        if completenessScore >= 0.8 {
            return "checkmark.circle.fill"
        } else if completenessScore >= 0.5 {
            return "exclamationmark.triangle.fill"
        } else {
            return "xmark.circle.fill"
        }
    }
    
    var body: some View {
        // Only show if completeness is less than 100%
        if completenessScore < 1.0 {
            Circle()
                .fill(indicatorColor.opacity(0.9))
                .frame(width: 20, height: 20)
                .overlay(
                    Image(systemName: completenessIcon)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                )
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                .accessibilityLabel("Data completeness: \(Int(completenessScore * 100))%")
        }
    }
}

// MARK: - Large Indicator for Detail Views

struct DataCompletenessBar: View {
    let book: UserBook
    
    @Environment(\.appTheme) private var theme
    
    private var completenessScore: Double {
        DataCompletenessService.calculateBookCompleteness(book)
    }
    
    private var metadataScore: Double {
        guard let metadata = book.metadata else { return 0.0 }
        return DataCompletenessService.calculateMetadataCompleteness(metadata)
    }
    
    private var userScore: Double {
        DataCompletenessService.calculateUserCompleteness(book)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Data Completeness")
                    .font(Theme.Typography.titleSmall)
                    .foregroundColor(theme.primaryText)
                
                Spacer()
                
                Text("\(Int(completenessScore * 100))%")
                    .font(Theme.Typography.labelLarge)
                    .foregroundColor(theme.primary)
                    .fontWeight(.semibold)
            }
            
            // Overall progress bar
            ProgressView(value: completenessScore)
                .progressViewStyle(LinearProgressViewStyle(tint: completenessScore >= 0.8 ? .green : completenessScore >= 0.5 ? .orange : .red))
                .scaleEffect(x: 1, y: 1.5, anchor: .center)
            
            // Breakdown
            HStack(spacing: Theme.Spacing.lg) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Book Data")
                        .font(Theme.Typography.labelMedium)
                        .foregroundColor(theme.secondaryText)
                    
                    HStack {
                        Circle()
                            .fill(metadataScore >= 0.8 ? .green : metadataScore >= 0.5 ? .orange : .red)
                            .frame(width: 8, height: 8)
                        
                        Text("\(Int(metadataScore * 100))%")
                            .font(Theme.Typography.labelSmall)
                            .foregroundColor(theme.secondaryText)
                    }
                }
                
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Personal Data")
                        .font(Theme.Typography.labelMedium)
                        .foregroundColor(theme.secondaryText)
                    
                    HStack {
                        Circle()
                            .fill(userScore >= 0.8 ? .green : userScore >= 0.5 ? .orange : .red)
                            .frame(width: 8, height: 8)
                        
                        Text("\(Int(userScore * 100))%")
                            .font(Theme.Typography.labelSmall)
                            .foregroundColor(theme.secondaryText)
                    }
                }
                
                Spacer()
            }
        }
        .padding(Theme.Spacing.md)
        .optimizedLiquidGlassCard(
            material: .regular,
            depth: .elevated,
            radius: .comfortable,
            vibrancy: .medium
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // High completeness
        let highBook = createHighCompletenessBook()
        
        HStack {
            DataCompletenessIndicator(book: highBook)
            Text("High Completeness")
        }
        
        DataCompletenessBar(book: highBook)
        
        // Low completeness
        let lowBook = createLowCompletenessBook()
        
        HStack {
            DataCompletenessIndicator(book: lowBook)
            Text("Low Completeness")
        }
        
        DataCompletenessBar(book: lowBook)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

private func createHighCompletenessBook() -> UserBook {
    let highBook = UserBook()
    highBook.rating = 5
    highBook.notes = "Great book!"
    highBook.metadata = BookMetadata(
        googleBooksID: "high_complete_123",
        title: "Complete Book",
        authors: ["Complete Author"],
        publishedDate: "2024",
        pageCount: 300,
        bookDescription: "A complete book description",
        dataSource: .googleBooksAPI,
        dataQualityScore: 0.9
    )
    return highBook
}

private func createLowCompletenessBook() -> UserBook {
    let lowBook = UserBook()
    lowBook.metadata = BookMetadata(
        googleBooksID: "low_complete_123",
        title: "Incomplete Book",
        authors: [],
        dataSource: .csvImport,
        dataQualityScore: 0.3
    )
    return lowBook
}