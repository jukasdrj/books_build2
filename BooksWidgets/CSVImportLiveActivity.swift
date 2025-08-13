/*
//
//  CSVImportLiveActivity.swift
//  BooksWidgets
//
//  Live Activity implementation for CSV import progress
//  Swift 6 compatible with iOS 16.1+ Live Activities API
//

import ActivityKit
import WidgetKit
import SwiftUI

@available(iOS 16.1, *)
@MainActor
struct CSVImportLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CSVImportActivityAttributes.self) { context in
            // Lock Screen Live Activity view
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded view
                DynamicIslandExpandedRegion(.leading) {
                    ProgressView(value: context.state.progress)
                        .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                        .frame(width: 40, height: 40)
                        .accessibilityLabel("Import progress")
                        .accessibilityValue(context.state.formattedProgress)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(context.state.formattedProgress)
                            .font(Theme.Typography.titleMedium)
                            .foregroundColor(.primary)
                            .accessibilityLabel("Import progress: \(context.state.formattedProgress)")
                        Text(context.state.statusSummary)
                            .font(Theme.Typography.labelMedium)
                            .foregroundColor(.secondary)
                            .accessibilityLabel("Status: \(context.state.statusSummary)")
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 4) {
                        Text(context.state.currentStep)
                            .font(Theme.Typography.bodyMedium)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .accessibilityLabel("Current step: \(context.state.currentStep)")
                        
                        if context.state.totalBooks > 0 {
                            HStack {
                                Text("✅ \(context.state.successCount)")
                                    .font(Theme.Typography.labelSmall)
                                    .foregroundColor(.green)
                                    .accessibilityLabel("\(context.state.successCount) books successfully imported")
                                
                                if context.state.duplicateCount > 0 {
                                    Text("⚠️ \(context.state.duplicateCount)")
                                        .font(Theme.Typography.labelSmall)
                                        .foregroundColor(.orange)
                                        .accessibilityLabel("\(context.state.duplicateCount) duplicate books found")
                                }
                                
                                if context.state.failureCount > 0 {
                                    Text("❌ \(context.state.failureCount)")
                                        .font(Theme.Typography.labelSmall)
                                        .foregroundColor(.red)
                                        .accessibilityLabel("\(context.state.failureCount) books failed to import")
                                }
                                
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.md)
                }
            } compactLeading: {
                // Compact leading view - progress indicator
                ProgressView(value: context.state.progress)
                    .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                    .frame(width: 20, height: 20)
                    .accessibilityLabel("Import progress")
                    .accessibilityValue(context.state.formattedProgress)
            } compactTrailing: {
                // Compact trailing view - book count
                VStack {
                    Text("\(context.state.booksProcessed)")
                        .font(Theme.Typography.labelSmall)
                        .fontWeight(.semibold)
                    Text("\(context.state.totalBooks)")
                        .font(Theme.Typography.labelSmall)
                        .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(context.state.booksProcessed) of \(context.state.totalBooks) books processed")
            } minimal: {
                // Minimal view - just progress
                ProgressView(value: context.state.progress)
                    .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                    .accessibilityLabel("Import progress")
                    .accessibilityValue(context.state.formattedProgress)
            }
        }
    }
}

// MARK: - Lock Screen Live Activity View

@available(iOS 16.1, *)
@MainActor
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<CSVImportActivityAttributes>
    
    var body: some View {
        VStack(spacing: 12) {
            // Header with file name
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.accentColor)
                    .accessibilityHidden(true)
                Text(context.attributes.displayName)
                    .font(Theme.Typography.titleMedium)
                    .foregroundColor(.primary)
                    .accessibilityLabel("Importing file: \(context.attributes.fileName)")
                Spacer()
                Text(context.state.formattedProgress)
                    .font(Theme.Typography.titleLarge)
                    .fontWeight(.bold)
                    .foregroundColor(.accentColor)
                    .accessibilityLabel("Progress: \(context.state.formattedProgress) complete")
            }
            
            // Progress bar
            ProgressView(value: context.state.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                .frame(height: 8)
                .accessibilityLabel("Import progress bar")
                .accessibilityValue("\(Int(context.state.progress * 100)) percent complete")
            
            // Current step and statistics
            VStack(spacing: 8) {
                HStack {
                    Text(context.state.currentStep)
                        .font(Theme.Typography.bodyMedium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .accessibilityLabel("Current step: \(context.state.currentStep)")
                    Spacer()
                    Text(context.state.statusSummary)
                        .font(Theme.Typography.bodySmall)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Status: \(context.state.statusSummary)")
                }
                
                if context.state.totalBooks > 0 {
                    HStack(spacing: 16) {
                        StatisticView(
                            icon: "checkmark.circle.fill",
                            count: context.state.successCount,
                            label: "Success",
                            color: .green
                        )
                        
                        if context.state.duplicateCount > 0 {
                            StatisticView(
                                icon: "exclamationmark.triangle.fill",
                                count: context.state.duplicateCount,
                                label: "Duplicates",
                                color: .orange
                            )
                        }
                        
                        if context.state.failureCount > 0 {
                            StatisticView(
                                icon: "xmark.circle.fill",
                                count: context.state.failureCount,
                                label: "Failed",
                                color: .red
                            )
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: Theme.CornerRadius.large))
    }
}

// MARK: - Supporting Views

@available(iOS 16.1, *)
@MainActor
struct StatisticView: View {
    let icon: String
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
                .accessibilityHidden(true)
            Text("\(count)")
                .font(Theme.Typography.labelMedium)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            Text(label)
                .font(Theme.Typography.labelSmall)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(count) \(label.lowercased())")
        .accessibilityAddTraits(.isStaticText)
    }
}

// MARK: - Preview Provider

@available(iOS 16.1, *)
struct CSVImportLiveActivity_Previews: PreviewProvider {
    static let attributes = CSVImportActivityAttributes(
        fileName: "library_export.csv",
        sessionId: UUID()
    )
    
    static let contentState = CSVImportActivityAttributes.ContentState(
        progress: 0.6,
        currentStep: "Processing 'The Great Gatsby' by F. Scott Fitzgerald",
        booksProcessed: 120,
        totalBooks: 200,
        successCount: 115,
        duplicateCount: 3,
        failureCount: 2
    )
    
    static var previews: some View {
        attributes
            .previewContext(contentState, viewKind: .content)
            .previewDisplayName("Live Activity Content")
        
        attributes
            .previewContext(contentState, viewKind: .dynamicIsland(.compact))
            .previewDisplayName("Dynamic Island Compact")
        
        attributes
            .previewContext(contentState, viewKind: .dynamicIsland(.expanded))
            .previewDisplayName("Dynamic Island Expanded")
        
        attributes
            .previewContext(contentState, viewKind: .dynamicIsland(.minimal))
            .previewDisplayName("Dynamic Island Minimal")
    }
}
*/
